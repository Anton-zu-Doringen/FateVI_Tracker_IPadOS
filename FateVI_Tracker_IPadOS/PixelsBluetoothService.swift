import CoreBluetooth
import Foundation
import SwiftUI

struct PixelsDevice: Identifiable, Hashable {
    let id: UUID
    var name: String
    var isConnected: Bool
    var batteryLevel: Int?
    var rssi: Int?
    var lastSeenAt: Date?
    var stateDescription: String
}

@MainActor
final class PixelsBluetoothService: NSObject, ObservableObject {
    @Published private(set) var devices: [PixelsDevice] = []
    @Published private(set) var status: String = "Bluetooth wird initialisiert."
    @Published private(set) var bluetoothStateDescription: String = "Unbekannt"
    @Published private(set) var isScanning = false

    private let knownDeviceIDsKey = "pixels.known-device-ids"
    private var centralManager: CBCentralManager?
    private var peripheralsByID: [UUID: CBPeripheral] = [:]
    private var batteryCharacteristicIDs: [UUID: CBCharacteristic] = [:]

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func startScanning() {
        guard let centralManager else { return }
        guard centralManager.state == .poweredOn else {
            status = "Bluetooth ist nicht bereit: \(bluetoothStateDescription)."
            return
        }
        if isScanning {
            status = "Scan läuft bereits."
            return
        }

        status = "Suche nach erreichbaren Pixels-Würfeln in der Nähe."
        isScanning = true
        centralManager.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ])
    }

    func stopScanning() {
        guard let centralManager, isScanning else { return }
        centralManager.stopScan()
        isScanning = false
        status = devices.isEmpty ? "Scan beendet. Keine bekannten Devices gefunden." : "Scan beendet."
    }

    func reconnectKnownDevices() {
        guard let centralManager else { return }
        guard centralManager.state == .poweredOn else {
            status = "Reconnect nicht möglich: \(bluetoothStateDescription)."
            return
        }

        let ids = knownDeviceIDs()
        guard !ids.isEmpty else {
            status = "Keine gemerkten Pixels-Geräte vorhanden."
            return
        }

        let peripherals = centralManager.retrievePeripherals(withIdentifiers: ids)
        if peripherals.isEmpty {
            status = "Keine gemerkten Geräte aktuell durch iPadOS verfügbar."
            return
        }

        status = "Versuche \(peripherals.count) gemerkte Geräte erneut zu verbinden."
        for peripheral in peripherals {
            register(peripheral, rssi: nil)
            centralManager.connect(peripheral)
        }
    }

    func connect(_ device: PixelsDevice) {
        guard let centralManager, let peripheral = peripheralsByID[device.id] else { return }
        centralManager.connect(peripheral)
        updateDevice(id: device.id) { current in
            current.stateDescription = "Verbinden..."
        }
        status = "Verbinde \(device.name)."
    }

    func disconnect(_ device: PixelsDevice) {
        guard let centralManager, let peripheral = peripheralsByID[device.id] else { return }
        centralManager.cancelPeripheralConnection(peripheral)
        status = "Trenne \(device.name)."
    }

    private func knownDeviceIDs() -> [UUID] {
        let rawValues = UserDefaults.standard.array(forKey: knownDeviceIDsKey) as? [String] ?? []
        return rawValues.compactMap(UUID.init(uuidString:))
    }

    private func persistKnownDeviceID(_ id: UUID) {
        var values = knownDeviceIDs()
        guard !values.contains(id) else { return }
        values.append(id)
        UserDefaults.standard.set(values.map(\.uuidString), forKey: knownDeviceIDsKey)
    }

    private func register(_ peripheral: CBPeripheral, rssi: NSNumber?) {
        peripheralsByID[peripheral.identifier] = peripheral
        peripheral.delegate = self

        let name = peripheral.name ?? "Unbenannter Würfel"
        let device = PixelsDevice(
            id: peripheral.identifier,
            name: name,
            isConnected: peripheral.state == .connected,
            batteryLevel: devices.first(where: { $0.id == peripheral.identifier })?.batteryLevel,
            rssi: rssi?.intValue,
            lastSeenAt: Date(),
            stateDescription: describe(peripheral.state)
        )

        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            devices[index] = device
        } else {
            devices.append(device)
            devices.sort { lhs, rhs in
                lhs.name.localizedCompare(rhs.name) == .orderedAscending
            }
        }
    }

    private func updateDevice(id: UUID, mutate: (inout PixelsDevice) -> Void) {
        guard let index = devices.firstIndex(where: { $0.id == id }) else { return }
        var device = devices[index]
        mutate(&device)
        devices[index] = device
    }

    private func describe(_ state: CBPeripheralState) -> String {
        switch state {
        case .connected: return "Verbunden"
        case .connecting: return "Verbinden..."
        case .disconnected: return "Getrennt"
        case .disconnecting: return "Trennen..."
        @unknown default: return "Unbekannt"
        }
    }

    private func describe(_ state: CBManagerState) -> String {
        switch state {
        case .unknown: return "Unbekannt"
        case .resetting: return "Bluetooth wird zurückgesetzt"
        case .unsupported: return "Bluetooth nicht unterstützt"
        case .unauthorized: return "Bluetooth nicht autorisiert"
        case .poweredOff: return "Bluetooth aus"
        case .poweredOn: return "Bluetooth bereit"
        @unknown default: return "Unbekannt"
        }
    }
}

extension PixelsBluetoothService: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            bluetoothStateDescription = describe(central.state)
            if central.state == .poweredOn {
                status = "Bluetooth bereit. Scan oder Reconnect kann gestartet werden."
            } else {
                isScanning = false
                status = "Bluetooth-Status: \(bluetoothStateDescription)."
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        Task { @MainActor in
            register(peripheral, rssi: RSSI)
            status = "Gefunden: \(peripheral.name ?? peripheral.identifier.uuidString)."
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            register(peripheral, rssi: nil)
            persistKnownDeviceID(peripheral.identifier)
            updateDevice(id: peripheral.identifier) { current in
                current.isConnected = true
                current.stateDescription = "Verbunden"
            }
            status = "\(peripheral.name ?? "Würfel") verbunden."
            peripheral.discoverServices([CBUUID(string: "180F")])
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            let message = error?.localizedDescription ?? "unbekannter Fehler"
            updateDevice(id: peripheral.identifier) { current in
                current.isConnected = false
                current.stateDescription = "Fehlgeschlagen"
            }
            status = "Verbindung zu \(peripheral.name ?? "Würfel") fehlgeschlagen: \(message)."
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            updateDevice(id: peripheral.identifier) { current in
                current.isConnected = false
                current.stateDescription = "Getrennt"
            }
            if let error {
                status = "\(peripheral.name ?? "Würfel") getrennt: \(error.localizedDescription)."
            } else {
                status = "\(peripheral.name ?? "Würfel") getrennt."
            }
        }
    }
}

extension PixelsBluetoothService: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else { return }
        peripheral.services?.forEach { service in
            if service.uuid == CBUUID(string: "180F") {
                peripheral.discoverCharacteristics([CBUUID(string: "2A19")], for: service)
            }
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else { return }
        service.characteristics?.forEach { characteristic in
            if characteristic.uuid == CBUUID(string: "2A19") {
                Task { @MainActor in
                    batteryCharacteristicIDs[peripheral.identifier] = characteristic
                }
                peripheral.readValue(for: characteristic)
            }
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else { return }
        guard characteristic.uuid == CBUUID(string: "2A19"),
              let value = characteristic.value?.first else { return }
        Task { @MainActor in
            updateDevice(id: peripheral.identifier) { current in
                current.batteryLevel = Int(value)
            }
        }
    }
}
