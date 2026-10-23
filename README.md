# SP105E Siri Starter (iOS)

This is a starter source package for an iPhone app that controls an SP105E BLE LED controller and exposes actions to Apple Shortcuts/Siri.

## Important limitations
- This is source code, not an installed iPhone app.
- Building/signing an iOS app requires Xcode on macOS (a cloud Mac build service can be used from Windows).
- BLE behavior can vary by SP105E firmware. Test with the actual controller.
- Siri/background execution of Bluetooth actions must be tested on-device; iOS may require the app to be launched or Bluetooth permissions to be granted first.
- The protocol reference used here documents service `FFE0`, characteristic `FFE1`, and 5-byte commands. The power command toggles state, so this starter reads status before toggling when possible.

## Add these files to a new iOS SwiftUI project in Xcode
1. Create an iOS App project named `SP105ESiri`.
2. Add `SP105EController.swift`, `LightIntents.swift`, and `ContentView.swift`.
3. In the app target's Info settings, add `NSBluetoothAlwaysUsageDescription` with a message such as: `Connect to your SP105E LED controller to control your lights.`
4. Build and test with your iPhone and SP105E nearby.
5. In Shortcuts, try the app actions `Turn SP105E lights on`, `Turn SP105E lights off`, and `Set SP105E color`.

## Protocol notes
- BLE service UUID: FFE0
- BLE characteristic UUID: FFE1
- Static RGB command: `38 RR GG BB 1E`
- Status query: `38 CA CA CA 10`
- Power toggle: `38 CA CA CA AA`
- Leave at least 120 ms between successive commands.

Protocol reference: https://dzentech.store/docs/en/developers/protocols/mixup-pixel-v1/
