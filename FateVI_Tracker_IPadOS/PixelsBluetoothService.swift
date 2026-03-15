import Foundation
import SwiftUI

struct PixelsDevice: Identifiable, Hashable {
    let id: UUID
    var name: String
    var isConnected: Bool
    var batteryLevel: Int?
}

@MainActor
final class PixelsBluetoothService: ObservableObject {
    @Published private(set) var devices: [PixelsDevice] = []
    @Published private(set) var status: String = "Pixels-CoreBluetooth-Layer noch nicht verbunden."

    func startScanning() {
        status = "Scan-Platzhalter: CoreBluetooth-Discovery wird im nächsten Schritt implementiert."
    }

    func reconnectKnownDevices() {
        status = "Reconnect-Platzhalter: bekannte Pixels werden später nativ wieder gekoppelt."
    }
}
