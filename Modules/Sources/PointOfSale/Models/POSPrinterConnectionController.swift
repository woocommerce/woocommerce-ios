import Observation
import protocol Yosemite.ReceiptPrinterServiceProtocol
import struct Yosemite.PrinterDevice
import enum Yosemite.PrinterConnectionStatus
import enum WooFoundation.BluetoothAuthorization
import protocol WooFoundation.BluetoothAuthorizationProviding
import struct WooFoundation.CoreBluetoothAuthorizationProvider

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

    /// Whether a Bluetooth scan is currently running, so the multiple-printers list can show a live
    /// "scanning" indicator while results keep arriving and hide it once the scan window ends.
    private(set) var isDiscovering = false

    /// The printer the merchant connected to, used to label the settings status row.
    private(set) var connectedPrinter: PrinterDevice?

    var connectedPrinterName: String? {
        connectedPrinter?.name
    }

    /// Whether a printer is currently connected, derived from `connectedPrinter`.
    var isConnected: Bool {
        connectedPrinter != nil
    }

    /// The app's Bluetooth permission, so the setup modal can prompt the merchant to enable it when
    /// it's off. Refreshed via `refreshBluetoothAuthorization()` when the modal appears or the app
    /// returns to the foreground.
    private(set) var bluetoothAuthorization: BluetoothAuthorization

    private let service: ReceiptPrinterServiceProtocol
    private let bluetoothAuthorizationProvider: BluetoothAuthorizationProviding
    private var discoveryTask: Task<Void, Never>?
    private var connectTask: Task<Void, Never>?
    private var statusTask: Task<Void, Never>?

    /// Printers found in the current scan, excluding duplicates and skipped devices.
    private var discoveredDevices: [PrinterDevice] = []
    /// Printers the merchant chose to skip via "Keep Searching", excluded from later scans.
    private var skippedDeviceIDs: Set<String> = []
    /// Latches once two or more printers have been seen, so the flow stays on the list rather than
    /// snapping back to the single-printer modal.
    private var hasShownMultiple = false

    init(service: ReceiptPrinterServiceProtocol,
         bluetoothAuthorizationProvider: BluetoothAuthorizationProviding = CoreBluetoothAuthorizationProvider()) {
        self.service = service
        self.bluetoothAuthorizationProvider = bluetoothAuthorizationProvider
        self.bluetoothAuthorization = bluetoothAuthorizationProvider.current
        observeConnectionStatus()
    }

    isolated deinit {
        discoveryTask?.cancel()
        connectTask?.cancel()
        statusTask?.cancel()
    }

    /// Starts a fresh Bluetooth discovery, clearing any previously skipped printers.
    func startDiscovery() {
        skippedDeviceIDs = []
        beginDiscovery()
    }

    /// Skips the currently offered printer and keeps scanning, mirroring "Keep Searching" in the
    /// card-reader flow. Restarting the scan guarantees discovery is live again even if the previous
    /// 30-second window had already elapsed.
    func keepSearching(skipping device: PrinterDevice) {
        skippedDeviceIDs.insert(device.id)
        beginDiscovery()
    }

    private func beginDiscovery() {
        discoveryTask?.cancel()
        discoveredDevices = []
        hasShownMultiple = false
        isDiscovering = true
        discoveryState = .searching
        discoveryTask = Task { [weak self] in
            // Reach the stream through a transient `self` so the in-flight `for await` holds only a
            // weak reference; binding `self` strongly here would retain the controller (which owns
            // this task) and stop its deinit — and this task's cancellation — from running.
            guard let stream = self?.service.discover() else { return }
            do {
                for try await device in stream {
                    // A cancelled discovery (a restart, or the merchant moving on to connecting)
                    // is no longer authoritative and must not overwrite the newer flow's state.
                    guard !Task.isCancelled, let self else { return }
                    handleDiscovered(device)
                }
                guard !Task.isCancelled, let self else { return }
                finishDiscovery()
            } catch {
                guard !Task.isCancelled, let self else { return }
                isDiscovering = false
                discoveryState = .error
            }
        }
    }

    /// Accumulates a discovered printer (ignoring duplicates and skipped devices) and re-derives the
    /// presentation state: one printer is confirmed in a modal, two or more in a list. The choice
    /// latches via `hasShownMultiple`, so once a second printer appears the flow stays on the list.
    private func handleDiscovered(_ device: PrinterDevice) {
        guard !skippedDeviceIDs.contains(device.id),
              !discoveredDevices.contains(where: { $0.id == device.id }) else {
            return
        }
        discoveredDevices.append(device)
        if discoveredDevices.count > 1 {
            hasShownMultiple = true
        }
        if hasShownMultiple {
            discoveryState = .foundMultiple(discoveredDevices)
        } else if let only = discoveredDevices.first {
            discoveryState = .foundOne(only)
        }
    }

    /// The scan ended (timed out or completed). Surface an empty result so the modal can offer a
    /// retry instead of spinning forever; otherwise leave the found state in place and just stop the
    /// scanning indicator.
    private func finishDiscovery() {
        isDiscovering = false
        if discoveredDevices.isEmpty {
            discoveryState = .noPrintersFound
        }
    }

    /// Connects to the chosen printer, stopping discovery first so the SDK scan is not left running.
    func connect(to device: PrinterDevice) {
        discoveryTask?.cancel()
        connectTask?.cancel()
        isDiscovering = false
        discoveryState = .connecting(device)
        connectTask = Task { [weak self] in
            // Reach the service through a transient `self` so the in-flight connect holds only a weak
            // reference; binding `self` strongly here would retain the controller for the whole
            // (SDK-bounded) connect and stop its deinit — and this task's cancellation — from running.
            guard let service = self?.service else { return }
            await service.stopDiscovery()
            do {
                try await service.connect(to: device)
            } catch {
                // A superseded connect (another printer tapped, or setup cancelled) must not
                // report an error over the newer flow.
                guard !Task.isCancelled, let self else { return }
                discoveryState = .error
            }
        }
    }

    func disconnect() async {
        await service.disconnect()
    }

    /// Re-reads the app's Bluetooth permission, so the setup flow reflects a change the merchant just
    /// made in Settings after being sent there.
    func refreshBluetoothAuthorization() {
        bluetoothAuthorization = bluetoothAuthorizationProvider.current
    }

    /// Tears down any in-flight discovery and returns to the pairing screen, so reopening the
    /// modal always starts fresh.
    func cancelSetup() async {
        discoveryTask?.cancel()
        connectTask?.cancel()
        isDiscovering = false
        discoveredDevices = []
        skippedDeviceIDs = []
        hasShownMultiple = false
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
                case .connected(let device):
                    connectedPrinter = device
                case .disconnected, .idle:
                    connectedPrinter = nil
                case .connecting, .disconnecting:
                    break
                }
            }
        }
    }
}
