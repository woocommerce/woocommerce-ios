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
        guard printer == nil else { return }
        let discovery = try StarDeviceDiscoveryManagerFactory.create(interfaceTypes: [.lan, .bluetoothLE, .bluetooth, .usb])

        discovery.delegate = self
        discovery.discoveryTime = 30000 // 30 seconds
        try discovery.startDiscovery()
    }

    public enum PrintType {
        case template
        case standard
    }

    public func printReceipt(content: ReceiptContent,
                             completion: @escaping (PrintingResult) -> Void) {
        Task {
            do {
                try await printReceipt(content: content, printType: .template)
            } catch {
                return completion(.failure(error))
            }
            completion(.success)
        }
    }

    public func printReceipt(content: ReceiptContent, printType: PrintType = .template) async throws {
        guard let printer else {
            throw StarReceiptPrinterError.noPrinterConnected
        }

        try await printer.open()
        defer {
            Task {
                await printer.close()
            }
        }

        switch printType {
        case .template:
            printer.template = receiptTemplate(width: 72.0)
            try await printer.print(command: jsonRepresentation(of: content))
        case .standard:
            let command = getPrintCommand(for: content)
            try await printer.print(command: command)
        }
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
    case couldNotMakeJson
}

private extension StarReceiptPrinterService {
    func getPrintCommand(for content: ReceiptContent) -> String {
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

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }

    func jsonRepresentation(of content: ReceiptContent) throws -> String {
        let encoder = JSONEncoder()
        guard let jsonData = try? encoder.encode(content),
           let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw StarReceiptPrinterError.couldNotMakeJson
        }

        return jsonString
    }

    func receiptTemplate(width: Double = 48.0) -> String {
        let builder = StarXpandCommand.StarXpandCommandBuilder()
        _ = builder.addDocument(StarXpandCommand.DocumentBuilder()
            .settingPrintableArea(width)
            .addPrinter(StarXpandCommand.PrinterBuilder()
                .styleInternationalCharacter(.usa)
                .styleCharacterSpace(0.0)
                .add(
                     StarXpandCommand.PrinterBuilder()
                    .styleAlignment(.center)
                    .styleBold(true)
                    .styleInvert(true)
                    .styleMagnification(StarXpandCommand.MagnificationParameter(width: 2, height: 2))
                    .actionPrintText("${parameters.store_name}\n")
                    .actionPrintText("Receipt")
                    )
                .actionFeed(1.0)
                .actionPrintText("Amount Paid\n".uppercased())
                .actionPrintText("${parameters.formatted_amount}\n")
                .actionPrintText("Date Paid\n".uppercased())
                .actionPrintText("${parameters.date}\n")
                .actionPrintText("Payment Status\n".uppercased())
                .actionPrintText("Success\n")
                .actionPrintText("Payment Method\n".uppercased())
                .actionPrintText("${parameters.card_details.brand} - ${parameters.card_details.last_4}\n")
                .actionPrintText("Summary: Order #".uppercased())
                .actionPrintText("${parameters.order_id}\n")
                .actionPrintRuledLine(
                    StarXpandCommand.Printer.RuledLineParameter(width: width)
                )
                .add(
                    StarXpandCommand.PrinterBuilder(
                        StarXpandCommand.Printer.PrinterParameter()
                            .setTemplateExtension(
                                StarXpandCommand.TemplateExtensionParameter()
                                    .setEnableArrayFieldData(true)
                            )
                    )
                        .actionPrintText(
                            "${line_items.title}",
                            StarXpandCommand.Printer.TextParameter()
                                .setWidth(19)
                        )
                        .actionPrintText(
                            "x ${line_items.quantity}",
                            StarXpandCommand.Printer.TextParameter()
                                .setWidth(5)
                        )
                        .actionPrintText(
                            "${line_items.amount}\n",
                            StarXpandCommand.Printer.TextParameter()
                                .setWidth(7,
                                          StarXpandCommand.Printer.TextWidthParameter()
                                              .setAlignment(.right))
                        )
                )
                    .add(
                        StarXpandCommand.PrinterBuilder(
                            StarXpandCommand.Printer.PrinterParameter()
                                .setTemplateExtension(
                                    StarXpandCommand.TemplateExtensionParameter()
                                        .setEnableArrayFieldData(true)
                                )
                        )
                            .actionPrintText(
                                "${cart_totals.description}",
                                StarXpandCommand.Printer.TextParameter()
                                    .setWidth(24)
                            )
                            .actionPrintText(
                                "${cart_totals.amount}\n",
                                StarXpandCommand.Printer.TextParameter()
                                    .setWidth(7,
                                              StarXpandCommand.Printer.TextWidthParameter()
                                                  .setAlignment(.right))
                            )
                    )
                .actionPrintRuledLine(
                    StarXpandCommand.Printer.RuledLineParameter(width: width)
                )
                    .actionPrintText("Notes\n".uppercased())
                    .actionPrintText("${order_note}\n")
                    .actionPrintRuledLine(
                        StarXpandCommand.Printer.RuledLineParameter(width: width)
                    )
                    .actionPrintText("Application Name: ${parameters.card_details.receipt.application_preferred_name}\n")
                    .actionPrintText("AID: ${parameters.card_details.receipt.dedicated_file_name}\n")
                    .actionPrintText("Account Type: ${parameters.card_details.receipt.account_type}\n")
                .actionCut(.partial)
            )
        )

        return builder.getCommands()
    }
}
