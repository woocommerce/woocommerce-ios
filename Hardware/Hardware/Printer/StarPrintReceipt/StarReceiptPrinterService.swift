import Foundation
import StarIO10

public final class StarReceiptPrinterService: PrinterService {
    public init() { }

    private var printer: StarPrinter?

    public func connect() async throws {
        let discovery = try StarDeviceDiscoveryManagerFactory.create(interfaceTypes: [.lan, .bluetooth, .usb])

        discovery.delegate = self
        discovery.discoveryTime = 10000 // 10 seconds
        try discovery.startDiscovery()
    }

    public func printReceipt(content: ReceiptContent,
                             completion: @escaping (PrintingResult) -> Void) {
        guard let printer else {
            return completion(.failure(StarReceiptPrinterError.noPrinterConnected))
        }

        let command = getPrintCommand(for: content)

        Task {
            do {
                try await printer.open()
                try await printer.print(command: command)
            } catch {
                completion(.failure(error))
            }
            await printer.close()
            completion(.success)
        }
    }

    private func getPrintCommand(for content: ReceiptContent) -> String {
        var printerBuilder = StarXpandCommand.PrinterBuilder()
            .actionPrintText("\(content.parameters.storeName ?? "Store")\n")
            .actionPrintText("Date: \(formatDate(content.parameters.date))\n")
            .actionPrintText("Amount Paid: \(content.parameters.formattedAmount)\n")
            .actionPrintText("Card: **** **** **** \(content.parameters.cardDetails.last4)\n")
            .actionPrintText("--------------------------------\n")

        for item in content.lineItems {
            printerBuilder = printerBuilder.actionPrintText("\(item.title) x \(item.quantity)    \(item.amount)\n")
        }

        printerBuilder = printerBuilder.actionPrintText("--------------------------------\n")
        for total in content.cartTotals {
            printerBuilder = printerBuilder.actionPrintText("\(total.description): \(total.amount)\n")
        }

        if let note = content.orderNote, !note.isEmpty {
            printerBuilder = printerBuilder.actionPrintText("\nOrder Note:\n\(note)\n")
        }

        printerBuilder = printerBuilder
            .actionPrintText("--------------------------------\n")
            .actionCut(.partial)
            .actionFeedLine(1)

        let builder = StarXpandCommand.StarXpandCommandBuilder()
            .addDocument(StarXpandCommand.DocumentBuilder().addPrinter(printerBuilder))
        return builder.getCommands()
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}

extension StarReceiptPrinterService: StarDeviceDiscoveryManagerDelegate {
    public func manager(_ manager: any StarIO10.StarDeviceDiscoveryManager, didFind printer: StarIO10.StarPrinter) {
        self.printer = printer
    }
    
    public func managerDidFinishDiscovery(_ manager: any StarIO10.StarDeviceDiscoveryManager) {

    }
}

enum StarReceiptPrinterError: Error {
    case noPrinterConnected
}
