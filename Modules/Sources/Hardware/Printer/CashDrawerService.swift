/// Opens a cash drawer connected to the receipt printer's drawer-kick port.
///
/// Kept separate from `PrinterDiscoveryService` so the drawer stays a device capability of its own:
/// callers decide when to open it, and a failure here never affects printing or the sale itself.
public protocol CashDrawerService: AnyObject {
    /// Sends the open pulse to the drawer on the connected printer.
    /// Throws `PrinterError.printerNotConnected` when no printer is connected.
    func openCashDrawer() async throws
}
