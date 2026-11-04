import CoreBluetooth

/// Whether the device's Bluetooth radio is switched on. Independent of the app's Bluetooth permission.
public enum BluetoothRadioState: Equatable, Sendable {
    /// Not reported yet, or a state that doesn't say whether the radio is on (resetting, unsupported, unauthorized).
    case unknown
    case poweredOn
    case poweredOff
}

extension BluetoothRadioState {
    init(_ state: CBManagerState) {
        switch state {
        case .poweredOn:
            self = .poweredOn
        case .poweredOff:
            self = .poweredOff
        case .unknown, .resetting, .unsupported, .unauthorized:
            self = .unknown
        @unknown default:
            self = .unknown
        }
    }
}

/// Streams the radio state from a `CBCentralManager` that lives exactly as long as the stream.
///
/// `@unchecked Sendable` so the stream's termination handler can own it: `manager` is only assigned in `init`,
/// and CoreBluetooth calls the delegate on the main queue, so there is no shared mutable state to race on.
final class BluetoothRadioStateObserver: NSObject, CBCentralManagerDelegate, @unchecked Sendable {
    private let continuation: AsyncStream<BluetoothRadioState>.Continuation
    private var manager: CBCentralManager?

    private init(continuation: AsyncStream<BluetoothRadioState>.Continuation) {
        self.continuation = continuation
        super.init()
        // The setup modal shows its own Turn on Bluetooth state, so the system power alert is suppressed.
        manager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: false])
    }

    /// Each call creates its own manager, which reports the current state right away and then every change.
    static func updates() -> AsyncStream<BluetoothRadioState> {
        AsyncStream { continuation in
            let observer = BluetoothRadioStateObserver(continuation: continuation)
            // Holds the observer until the consumer stops listening, which then releases the manager.
            continuation.onTermination = { _ in
                withExtendedLifetime(observer) {}
            }
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        continuation.yield(BluetoothRadioState(central.state))
    }
}
