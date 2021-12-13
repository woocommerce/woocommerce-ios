import Hardware

final class ServiceLocator {
    static let printerService: PrinterService = AirPrintReceiptPrinterService()
}
