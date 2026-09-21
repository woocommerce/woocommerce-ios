/// Discovers printers over Bluetooth, manages the connection lifecycle, and prints receipts.
///
/// Hardware-domain abstraction over the printer SDK. Concrete implementations wrap the
/// SDK and expose only Hardware-domain types, keeping SDK details inside the Hardware module.
public protocol PrinterDiscoveryService: AnyObject {
    /// Streams the printer connection status. Each call returns its own stream, which replays the
    /// current status immediately on subscription and then emits every subsequent change.
    func connectionStatusUpdates() -> AsyncStream<PrinterConnectionStatus>

    /// Starts discovering available printers, emitting each device as it is found.
    func discover() -> AsyncThrowingStream<PrinterDevice, Error>

    /// Stops the current printer discovery.
    func stopDiscovery() async

    /// Connects to the given printer.
    func connect(to device: PrinterDevice) async throws

    /// Disconnects from the currently connected printer, if any.
    func disconnect() async

    /// Prints already-rendered receipt text on the connected printer.
    ///
    /// The text is composed by the caller (Yosemite); this backend only wraps it into the
    /// printer's own print command, so it stays agnostic of receipt content and layout.
    func printReceipt(text: String) async throws
}
