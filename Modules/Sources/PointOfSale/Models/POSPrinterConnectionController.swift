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
            guard let self else { return }
            var devices: [PrinterDevice] = []
            do {
                for try await device in service.discover() {
                    if !devices.contains(device) {
                        devices.append(device)
                    }
                    discoveryState = .found(devices)
                }
                // Discovery finished without a single device: surface the empty list so the
                // modal can offer a retry instead of spinning forever.
                if case .searching = discoveryState {
                    discoveryState = .found([])
                }
            } catch {
                // A cancelled discovery (the merchant moved on to connecting or closed the modal)
                // must not clobber the state the new flow already set.
                if !Task.isCancelled {
                    discoveryState = .error
                }
            }
        }
    }

    /// Connects to the chosen printer, stopping discovery first so the SDK scan is not left running.
    func connect(to device: PrinterDevice) {
        discoveryTask?.cancel()
        discoveryState = .connecting(device)
        connectTask?.cancel()
        connectTask = Task { [weak self] in
            guard let self else { return }
            await service.stopDiscovery()
            do {
                try await service.connect(to: device)
                connectedPrinter = device
            } catch {
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
        discoveryState = .idle
        await service.stopDiscovery()
    }

    private func observeConnectionStatus() {
        statusTask = Task { [weak self] in
            guard let self else { return }
            for await status in service.connectionStatusUpdates() {
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
