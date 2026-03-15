# FateVI_Tracker_IPadOS

Native iPadOS implementation of the Fate VI initiative and wound tracker.

## Direction

This project is a fresh SwiftUI rewrite, not a port of the existing web UI. The app is designed specifically for iPad:

- `NavigationSplitView` layout with a dedicated combat stage
- card-based initiative timeline instead of browser-style lists
- inspector-driven editing for combat state and wound tracking
- architecture split into combat rules, presentation state, and hardware integrations

## Current scope

The repository currently contains:

- an iPad-only SwiftUI app target
- a first-pass combat dashboard with party roster, initiative stage, and inspector
- local sample data for design and flow iteration
- foundation types for characters, rounds, wounds, and initiative entries

## Next steps

- implement full Fate VI initiative rules and turn sequencing
- persist combat sessions locally
- add Bluetooth integration for Pixels dice via CoreBluetooth
- replace sample actions with full editing flows

## Opening the project

Open `FateVI_Tracker_IPadOS.xcodeproj` in Xcode on macOS.

This environment does not provide Swift/Xcode tooling, so the project files were prepared statically and not compiled here.
