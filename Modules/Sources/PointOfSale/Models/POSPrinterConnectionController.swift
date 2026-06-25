import Observation
import protocol Yosemite.ReceiptPrinterServiceProtocol
import struct Yosemite.PrinterDevice
import enum Yosemite.PrinterConnectionStatus

/// Owns receipt-printer discovery and the connection lifecycle for POS settings.
///
/// Drives the setup modal through `discoveryState` and the settings status row through
/// `isConnected` / `connectedPrinterName`, wrapping the manufacturer-agnostic
/// `ReceiptPrinterServiceProtocol` so the views never touch the printer service directly.
@MainActor
@Observable
final class POSPrinterConnectionController {
    /// Drives the setup modal: pairing → searching → found → connecting → error.
    private(set) var discoveryState: PrinterDiscoveryState = .idle

    /// Whether a printer is currently connected, mirrored from the service's status stream.
    private(set) var isConnected = false

    /// The printer the merchant connected to, used to label the settings status row.
    private(set) var connectedPrinter: PrinterDevice?

    var connectedPrinterName: String? {
        connectedPrinter?.name
    }

    private let service: ReceiptPrinterServiceProtocol
    private var discoveryTask: Task<Void, Never>?
    private var connectTask: Task<Void, Never>?
    private var statusTask: Task<Void, Never>?

    init(service: ReceiptPrinterServiceProtocol) {
        self.service = service
        observeConnectionStatus()
    }

    deinit {
        discoveryTask?.cancel()
        connectTask?.cancel()
        statusTask?.cancel()
    }

    /// Starts (or restarts) Bluetooth discovery, accumulating found printers into `discoveryState`.
    func startDiscovery() {
        discoveryTask?.cancel()
        discoveryState = .searching
        discoveryTask = Task { [weak self] in
            // Reach the stream through a transient `self` so the in-flight `for await` holds only a
            // weak reference; binding `self` strongly here would retain the controller (which owns
            // this task) and stop its deinit — and this task's cancellation — from running.
            guard let stream = self?.service.discover() else { return }
            var devices: [PrinterDevice] = []
            do {
                for try await device in stream {
                    if !devices.contains(device) {
                        devices.append(device)
                    }
                    // A cancelled discovery (a restart, or the merchant moving on to connecting)
                    // is no longer authoritative and must not overwrite the newer flow's state.
                    guard !Task.isCancelled, let self else { return }
                    discoveryState = .found(devices)
                }
                // Discovery finished without a single device: surface the empty list so the
                // modal can offer a retry instead of spinning forever.
                guard !Task.isCancelled, let self else { return }
                if case .searching = discoveryState {
                    discoveryState = .found([])
                }
            } catch {
                guard !Task.isCancelled, let self else { return }
                discoveryState = .error
            }
        }
    }

    /// Connects to the chosen printer, stopping discovery first so the SDK scan is not left running.
    func connect(to device: PrinterDevice) {
        discoveryTask?.cancel()
        connectTask?.cancel()
        discoveryState = .connecting(device)
        connectTask = Task { [weak self] in
            // Reach the service through a transient `self` so the in-flight connect holds only a weak
            // reference; binding `self` strongly here would retain the controller for the whole
            // (SDK-bounded) connect and stop its deinit — and this task's cancellation — from running.
            guard let service = self?.service else { return }
            await service.stopDiscovery()
            do {
                try await service.connect(to: device)
                // A superseded connect (another printer tapped, or setup cancelled) must not
                // report success or failure over the newer flow.
                guard !Task.isCancelled, let self else { return }
                connectedPrinter = device
            } catch {
                guard !Task.isCancelled, let self else { return }
                discoveryState = .error
            }
        }
    }

    func disconnect() async {
        await service.disconnect()
    }

    /// Tears down any in-flight discovery and returns to the pairing screen, so reopening the
    /// modal always starts fresh.
    func cancelSetup() async {
        discoveryTask?.cancel()
        connectTask?.cancel()
        discoveryState = .idle
        await service.stopDiscovery()
    }

    private func observeConnectionStatus() {
        // Reach the stream through a transient `self` so the long-lived iteration captures only a
        // weak reference. Holding `self` strongly across this never-ending loop would retain the
        // controller (which owns this task) and stop `deinit` — and its cancellation — from running.
        statusTask = Task { [weak self] in
            guard let updates = self?.service.connectionStatusUpdates() else { return }
            for await status in updates {
                guard let self else { return }
                switch status {
                case .connected:
                    isConnected = true
                case .disconnected, .idle:
                    isConnected = false
                    connectedPrinter = nil
                case .connecting, .disconnecting:
                    break
                }
            }
        }
    }
}
