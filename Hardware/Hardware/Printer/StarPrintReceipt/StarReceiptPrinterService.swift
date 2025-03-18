import Foundation
import StarIO10

public final class StarReceiptPrinterService: PrinterService {
    public init() { }

    private var printer: StarPrinter?

    public func connect() async throws {
        try await discoverAll()
//        connectToBluetoothPrinter()
    }

    func connectToBluetoothPrinter() {
        let connectionSettings = StarConnectionSettings(interfaceType: .bluetooth)
        printer = StarPrinter(connectionSettings)
    }

    func discoverAll() async throws {
        let discovery = try StarDeviceDiscoveryManagerFactory.create(interfaceTypes: [.lan, .bluetoothLE, .bluetooth, .usb])

        discovery.delegate = self
        discovery.discoveryTime = 30000 // 30 seconds
        try discovery.startDiscovery()
    }

    public func printReceipt(content: ReceiptContent,
                             completion: @escaping (PrintingResult) -> Void) {
        guard let printer else {
            return completion(.failure(StarReceiptPrinterError.noPrinterConnected))
        }
        Task {
            let printerStatus = try await printer.getStatus()
            DDLogInfo("Printer status: \(printerStatus)")
        }
        let command = getPrintCommand(for: content)

        Task {
            do {
//                let command = try getTemplateCommand(for: content)
                try await printer.open()
                try await printer.print(command: command)
            } catch {
                return completion(.failure(error))
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

    func getTemplateCommand(for content: ReceiptContent) throws -> String {
        // Load JSON template
        guard let templatePath = Bundle.main.path(forResource: "receipt_template", ofType: "json"),
              let templateData = try? Data(contentsOf: URL(fileURLWithPath: templatePath)),
              var templateString = String(data: templateData, encoding: .utf8) else {
            print("Failed to load template.")
            throw StarReceiptPrinterError.couldntLoadTemplate
        }

        // Replace placeholders with actual values
        templateString = templateString
            .replacingOccurrences(of: "{storeName}", with: content.parameters.storeName ?? "Store")
            .replacingOccurrences(of: "{date}", with: formatDate(content.parameters.date))
            .replacingOccurrences(of: "{amountPaid}", with: content.parameters.formattedAmount)
            .replacingOccurrences(of: "{cardLast4}", with: content.parameters.cardDetails.last4)
            .replacingOccurrences(of: "{orderNote}", with: content.orderNote ?? "")

        // Convert line items into JSON format
        let lineItemsJSON = content.lineItems.map {
            """
            {
                "type": "text",
                "content": "\($0.title) x \($0.quantity)    \($0.amount)",
                "style": { "fontSize": 14, "alignment": "left" }
            }
            """
        }.joined(separator: ",")

        let totalsJSON = content.cartTotals.map {
            """
            {
                "type": "text",
                "content": "\($0.description): \($0.amount)",
                "style": { "fontSize": 16, "bold": true, "alignment": "left" }
            }
            """
        }.joined(separator: ",")

        templateString = templateString
            .replacingOccurrences(of: "\"{lineItems}\"", with: "[\(lineItemsJSON)]")
            .replacingOccurrences(of: "\"{totals}\"", with: "[\(totalsJSON)]")

        // Send the command to print
        let builder = StarXpandCommand.StarXpandCommandBuilder()
            .addDocument(StarXpandCommand.DocumentBuilder().addRaw(templateString.data(using: .utf8)!))

        return builder.getCommands()
    }
}

extension StarReceiptPrinterService: StarDeviceDiscoveryManagerDelegate {
    public func manager(_ manager: any StarIO10.StarDeviceDiscoveryManager, didFind printer: StarIO10.StarPrinter) {
        DDLogInfo("Connected to printer \(printer.connectionSettings.identifier) using \(printer.connectionSettings.interfaceType.rawValue)")
        self.printer = printer
    }

    public func managerDidFinishDiscovery(_ manager: any StarIO10.StarDeviceDiscoveryManager) {
        DDLogInfo("Finished discovering printers")
    }
}

enum StarReceiptPrinterError: Error {
    case noPrinterConnected
    case couldntLoadTemplate
}
