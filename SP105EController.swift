import Foundation
import CoreBluetooth

@MainActor
final class SP105EController: NSObject, ObservableObject {
    static let shared = SP105EController()

    @Published private(set) var isConnected = false
    @Published private(set) var statusText = "Not connected"

    private let serviceID = CBUUID(string: "FFE0")
    private let characteristicID = CBUUID(string: "FFE1")
    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    private var statusContinuation: CheckedContinuation<Bool?, Never>?

    private override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
    }

    func connectIfNeeded() async throws {
        if isConnected, peripheral != nil, writeCharacteristic != nil { return }
        guard central.state == .poweredOn else {
            throw ControllerError.bluetoothUnavailable
        }

        statusText = "Scanning for SP105E…"
        central.scanForPeripherals(withServices: [serviceID], options: nil)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Task { @MainActor in
                self.connectionContinuation = continuation
            }
        }
    }

    private var connectionContinuation: CheckedContinuation<Void, Error>?

    func setColor(red: UInt8, green: UInt8, blue: UInt8) async throws {
        try await connectIfNeeded()
        let bytes: [UInt8] = [0x38, red, green, blue, 0x1E]
        try write(bytes)
    }

    func turnPowerOn() async throws {
        try await setPower(desiredOn: true)
    }

    func turnPowerOff() async throws {
        try await setPower(desiredOn: false)
    }

    private func setPower(desiredOn: Bool) async throws {
        try await connectIfNeeded()
        // SP105E's documented power command toggles, rather than setting a fixed state.
        // Query current state and only toggle if needed.
        let status = await queryPowerStatus()
        if let status, status == desiredOn { return }
        try write([0x38, 0xCA, 0xCA, 0xCA, 0xAA])
        try await Task.sleep(for: .milliseconds(250))
        statusText = desiredOn ? "Sent power-on command" : "Sent power-off command"
    }

    private func queryPowerStatus() async -> Bool? {
        guard let peripheral, let characteristic = writeCharacteristic else { return nil }
        peripheral.writeValue(Data([0x38, 0xCA, 0xCA, 0xCA, 0x10]), for: characteristic, type: .withResponse)
        do {
            return try await withCheckedContinuation { continuation in
                self.statusContinuation = continuation
                Task { try? await Task.sleep(for: .milliseconds(700)); self.statusContinuation?.resume(returning: nil); self.statusContinuation = nil }
            }
        }
    }

    private func write(_ bytes: [UInt8]) throws {
        guard let peripheral, let characteristic = writeCharacteristic else {
            throw ControllerError.notConnected
        }
        peripheral.writeValue(Data(bytes), for: characteristic, type: .withResponse)
        statusText = "Sent command: " + bytes.map { String(format: "%02X", $0) }.joined(separator: " ")
    }

    enum ControllerError: LocalizedError {
        case bluetoothUnavailable
        case notConnected

        var errorDescription: String? {
            switch self {
            case .bluetoothUnavailable: return "Turn on Bluetooth and keep the SP105E nearby."
            case .notConnected: return "The SP105E is not connected yet."
            }
        }
    }
}

extension SP105EController: CBCentralManagerDelegate, CBPeripheralDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn { statusText = "Bluetooth is unavailable" }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let name = peripheral.name ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? ""
        guard name.localizedCaseInsensitiveContains("SP105") else { return }
        self.peripheral = peripheral
        self.peripheral?.delegate = self
        central.stopScan()
        central.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        statusText = "Connected; discovering service…"
        peripheral.discoverServices([serviceID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        statusText = "Connection failed: \(error?.localizedDescription ?? "unknown error")"
        connectionContinuation?.resume(throwing: error ?? ControllerError.notConnected)
        connectionContinuation = nil
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let service = peripheral.services?.first(where: { $0.uuid == serviceID }) else { return }
        peripheral.discoverCharacteristics([characteristicID], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristic = service.characteristics?.first(where: { $0.uuid == characteristicID }) else {
            connectionContinuation?.resume(throwing: ControllerError.notConnected)
            connectionContinuation = nil
            return
        }
        writeCharacteristic = characteristic
        statusText = "Connected to SP105E"
        connectionContinuation?.resume()
        connectionContinuation = nil
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.uuid == characteristicID, let data = characteristic.value, !data.isEmpty else { return }
        statusContinuation?.resume(returning: data[0] != 0)
        statusContinuation = nil
    }
}
