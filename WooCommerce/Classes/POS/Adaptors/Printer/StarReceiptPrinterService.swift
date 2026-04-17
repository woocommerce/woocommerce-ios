import Foundation
import StarIO10
import Combine
import Hardware

public final class StarReceiptPrinterService: PrinterService, DiscoverableHardwareService {
    public init() { }

    private var printer: StarPrinter?
    private var discoveryManager: StarDeviceDiscoveryManager?
    private var cancellables = Set<AnyCancellable>()

    private let statusSubject = PassthroughSubject<DeviceStatus, Never>()
    public var statusPublisher: AnyPublisher<DeviceStatus, Never> {
        statusSubject.eraseToAnyPublisher()
    }

    fileprivate var discoveryDolegate: StarDiscoveryDelegate?

    public func discover() -> AsyncThrowingStream<StarPrinter, Error> {
        print("🖨️ Starting printer discovery")
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let discovery = try StarDeviceDiscoveryManagerFactory.create(interfaceTypes: [.lan, .bluetoothLE, .bluetooth, .usb])
                    self.discoveryManager = discovery

                    let discoveryDelegate = StarDiscoveryDelegate(continuation: continuation)
                    self.discoveryDolegate = discoveryDelegate
                    discovery.delegate = discoveryDelegate

                    discovery.discoveryTime = 30000
                    try discovery.startDiscovery()
                    DDLogDebug("🖨️ Discovery started")

                    continuation.onTermination = { _ in
                        discovery.stopDiscovery()
                        self.discoveryDolegate = nil
                        DDLogDebug("🖨️ Discovery stopped")
                    }
                } catch {
                    DDLogError("🖨️ Discovery error: \(error.localizedDescription)")
                    continuation.finish(throwing: StarReceiptPrinterError.discoveryFailure)
                }
            }
        }
    }

    public func stopDiscovery() {
        guard let discoveryManager else {
            return
        }
        discoveryManager.stopDiscovery()
    }

    public func connect(to printer: StarPrinter) {
        DDLogDebug("🖨️ Connecting to printer: \(printer.connectionSettings.identifier)")
        statusSubject.send(.connecting)
        self.printer = printer
        self.printer?.printerDelegate = self
        statusSubject.send(.connected)
        DDLogDebug("🖨️ Connected to printer")
    }

    public func disconnect() async {
        DDLogDebug("🖨️ Disconnecting from printer")
        statusSubject.send(.disconnecting)
        await self.printer?.close()
        self.printer = nil
        statusSubject.send(.disconnected)
    }

    public enum PrintType {
        case template
        case standard
    }

    public func printReceipt(content: ReceiptContent, completion: @escaping (PrintingResult) -> Void) {
        Task {
            do {
                try await printReceipt(content: content, printType: .template)
            } catch {
                return completion(.failure(error))
            }
            completion(.success)
        }
    }

    public func printReceipt(content: ReceiptContent) async throws {
        try await printReceipt(content: content, printType: .template)
    }

    public func printReceipt(content: ReceiptContent, printType: PrintType) async throws {
        guard let printer else {
            DDLogDebug("🖨️ No printer connected")
            throw StarReceiptPrinterError.noPrinterConnected
        }

        DDLogDebug("🖨️ Opening connection to printer")
        try await printer.open()
        defer { Task { await printer.close() } }

        DDLogDebug("🖨️ Sending print command")
        switch printType {
        case .template:
            printer.template = receiptTemplate(width: 72.0)
            try await printer.print(command: jsonRepresentation(of: content))
        case .standard:
            let command = getPrintCommand(for: content)
            try await printer.print(command: command)
        }
        DDLogDebug("🖨️ Print job sent successfully")
    }
}

private class StarDiscoveryDelegate: NSObject, StarDeviceDiscoveryManagerDelegate {
    private let continuation: AsyncThrowingStream<StarPrinter, Error>.Continuation

    init(continuation: AsyncThrowingStream<StarPrinter, Error>.Continuation) {
        self.continuation = continuation
    }

    func manager(_ manager: any StarIO10.StarDeviceDiscoveryManager, didFind printer: StarIO10.StarPrinter) {
        DDLogDebug("🖨️ Found printer: \(printer.connectionSettings.identifier)")
        continuation.yield(printer)
    }

    func managerDidFinishDiscovery(_ manager: any StarIO10.StarDeviceDiscoveryManager) {
        DDLogDebug("🖨️ Finished printer discovery")
        continuation.finish()
    }
}

extension StarReceiptPrinterService: PrinterDelegate {
    public func printer(_ printer: StarIO10.StarPrinter, communicationErrorDidOccur error: any Error) {
        DDLogError("🖨️ Communication error: \(error)")
        Task {
            let status = try await printer.getStatus()
            statusSubject.send(status.toDeviceStatus())
        }
    }

    public func printerIsReady(_ printer: StarIO10.StarPrinter) {
        DDLogInfo("🖨️ Printer ready: \(printer.connectionSettings.identifier)")
    }

    public func printerDidHaveError(_ printer: StarIO10.StarPrinter) {
        DDLogError("🖨️ Printer error: \(printer.connectionSettings.identifier)")
        Task {
            let status = try await printer.getStatus()
            statusSubject.send(status.toDeviceStatus())
        }
    }

    public func printerIsPaperReady(_ printer: StarIO10.StarPrinter) {
        DDLogInfo("🖨️ Paper ready for printer: \(printer.connectionSettings.identifier)")
        Task {
            let status = try await printer.getStatus()
            statusSubject.send(status.toDeviceStatus())
        }
    }

    public func printerIsPaperNearEmpty(_ printer: StarIO10.StarPrinter) {
        DDLogInfo("🖨️ Paper near empty for printer: \(printer.connectionSettings.identifier)")
        Task {
            let status = try await printer.getStatus()
            statusSubject.send(status.toDeviceStatus())
        }
    }

    public func printerIsPaperEmpty(_ printer: StarIO10.StarPrinter) {
        DDLogInfo("🖨️ Paper empty for printer: \(printer.connectionSettings.identifier)")
        Task {
            let status = try await printer.getStatus()
            statusSubject.send(status.toDeviceStatus())
        }
    }

    public func printerIsCoverOpen(_ printer: StarIO10.StarPrinter) {
        DDLogInfo("🖨️ Cover open on printer: \(printer.connectionSettings.identifier)")
        Task {
            let status = try await printer.getStatus()
            statusSubject.send(status.toDeviceStatus())
        }
    }

    public func printerIsCoverClose(_ printer: StarIO10.StarPrinter) {
        DDLogInfo("🖨️ Cover closed on printer: \(printer.connectionSettings.identifier)")
        Task {
            let status = try await printer.getStatus()
            statusSubject.send(status.toDeviceStatus())
        }
    }
}

extension StarPrinter: Identifiable {
    public var id: String {
        return connectionSettings.identifier
    }
}

private extension StarPrinterStatus {
    func toDeviceStatus() -> DeviceStatus {
        guard !hasError else {
            return .error(StarReceiptPrinterError.unknownError)
        }
        return .connected
    }
}

enum StarReceiptPrinterError: Error {
    case noPrinterConnected
    case couldNotMakeJson
    case discoveryFailure
    case unknownError
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

public extension StarIO10.InterfaceType {
    var interfaceName: String {
        switch self {
        case .bluetooth:
            return "Bluetooth"
        case .bluetoothLE:
            return "Bluetooth Low Energy"
        case .usb:
            return "USB"
        case .lan:
            return "Local Network"
        case .unknown:
            return "Unknown"
        @unknown default:
            return "Unknown"
        }
    }
}
