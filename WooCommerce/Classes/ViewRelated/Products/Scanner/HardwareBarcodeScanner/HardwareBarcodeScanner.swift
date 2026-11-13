import UIKit
import class Hardware.GameControllerBarcodeObserver
import struct Hardware.HIDBarcodeParserConfiguration
import enum Hardware.HIDBarcodeParserError
import enum Hardware.HIDBarcodeParserResult
import protocol WooFoundation.Analytics

/// `GCKeyboard.coalesced` has a single key handler, so the app keeps one observer for all its screens.
@MainActor
final class HardwareBarcodeScanner {
    static let shared = HardwareBarcodeScanner()

    typealias Source = WooAnalyticsEvent.BarcodeScanning.Source

    struct ListenerToken: Hashable {
        fileprivate let id = UUID()
    }

    typealias ObserverFactory = @MainActor (_ acceptsInput: @escaping () -> Bool,
                                 _ onResult: @escaping (HIDBarcodeParserResult) -> Void) -> AnyObject

    fileprivate struct Listener {
        let token: ListenerToken
        let source: Source
        let isEnabled: () -> Bool
        let onScan: (ScannedBarcode) -> Void
        let onMissingEnterSuffix: (() -> Void)?
    }

    private let analytics: Analytics
    private let noticePresenter: () -> NoticePresenter
    private let isTextInputActive: () -> Bool
    private let makeObserver: ObserverFactory
    private var listeners: [Listener] = []
    private var observer: AnyObject?

    init(analytics: Analytics = ServiceLocator.analytics,
         noticePresenter: @escaping () -> NoticePresenter = { ServiceLocator.noticePresenter },
         isTextInputActive: @escaping () -> Bool = { UIResponder.isTextInputFirstResponder },
         makeObserver: @escaping ObserverFactory = HardwareBarcodeScanner.makeGameControllerObserver) {
        self.analytics = analytics
        self.noticePresenter = noticePresenter
        self.isTextInputActive = isTextInputActive
        self.makeObserver = makeObserver
    }

    func startListening(source: Source,
                        isEnabled: @escaping () -> Bool = { true },
                        onMissingEnterSuffix: (() -> Void)? = nil,
                        onScan: @escaping (ScannedBarcode) -> Void) -> ListenerToken {
        let token = ListenerToken()
        listeners.append(Listener(token: token,
                                  source: source,
                                  isEnabled: isEnabled,
                                  onScan: onScan,
                                  onMissingEnterSuffix: onMissingEnterSuffix))
        startObservingIfNeeded()
        return token
    }

    func stopListening(_ token: ListenerToken) {
        listeners.removeAll { $0.token == token }
        if listeners.isEmpty {
            observer = nil
        }
    }
}

private extension HardwareBarcodeScanner {
    /// A disabled top listener drops the scan, so it doesn't reach the screen it covers.
    var activeListener: Listener? {
        guard let listener = listeners.last, listener.isEnabled() else {
            return nil
        }
        return listener
    }

    var acceptsInput: Bool {
        activeListener != nil && !isTextInputActive()
    }

    func startObservingIfNeeded() {
        guard observer == nil else { return }
        // The key handler runs on the main queue, the default `GCKeyboardInput.handlerQueue`.
        observer = makeObserver({ [weak self] in
            MainActor.assumeIsolated { self?.acceptsInput ?? false }
        }, { [weak self] result in
            MainActor.assumeIsolated { self?.handle(result) }
        })
    }

    func handle(_ result: HIDBarcodeParserResult) {
        guard let listener = activeListener else { return }
        switch result {
        case .success(let barcode, _):
            analytics.track(event: .BarcodeScanning.hardwareBarcodeScanningSuccess(from: listener.source))
            listener.onScan(ScannedBarcode(hardwareScannerInput: barcode))
        case .failure(.timedOut(let barcode), _) where barcode.count >= Constants.minimumBarcodeLength:
            if let onMissingEnterSuffix = listener.onMissingEnterSuffix {
                onMissingEnterSuffix()
            } else {
                noticePresenter().enqueue(notice: Notice(title: Localization.missingEnterSuffix))
            }
        case .failure:
            break
        }
    }

    static func makeGameControllerObserver(acceptsInput: @escaping () -> Bool,
                                           onResult: @escaping (HIDBarcodeParserResult) -> Void) -> AnyObject {
        GameControllerBarcodeObserver(configuration: Constants.parserConfiguration,
                                      isScanningEnabled: acceptsInput,
                                      onScan: onResult)
    }

    enum Constants {
        /// 3 matches Android so short SKUs work; POS keeps 6.
        static let minimumBarcodeLength = 3
        static let parserConfiguration = HIDBarcodeParserConfiguration(
            terminatingStrings: HIDBarcodeParserConfiguration.default.terminatingStrings,
            minimumBarcodeLength: minimumBarcodeLength,
            maximumInterCharacterTime: HIDBarcodeParserConfiguration.default.maximumInterCharacterTime
        )
    }

    enum Localization {
        static let missingEnterSuffix = NSLocalizedString(
            "hardwareBarcodeScanner.missingEnterSuffix",
            value: "Scan not finished. Set your scanner to send Enter after each barcode.",
            comment: "Notice shown when a barcode scanner sends a code without Enter at the end."
        )
    }
}

extension ScannedBarcode {
    /// A scanner doesn't send the symbology; treating GS1-valid codes as EAN/UPC lets the product search retry without the check digit or country code.
    init(hardwareScannerInput barcode: String) {
        self.init(payloadStringValue: barcode, symbology: Self.symbology(forHardwareScannerInput: barcode))
    }

    private static func symbology(forHardwareScannerInput barcode: String) -> BarcodeSymbology {
        let digits = barcode.compactMap { $0.wholeNumberValue }
        guard digits.count == barcode.count, hasValidGS1CheckDigit(digits) else {
            return .code128
        }
        switch digits.count {
        case 8:
            return .ean8
        case 12, 13:
            // Vision reports UPC-A as EAN-13.
            return .ean13
        default:
            return .code128
        }
    }

    private static func hasValidGS1CheckDigit(_ digits: [Int]) -> Bool {
        guard let checkDigit = digits.last else { return false }
        let weightedSum = digits.dropLast().reversed().enumerated().reduce(0) { sum, element in
            sum + element.element * (element.offset.isMultiple(of: 2) ? 3 : 1)
        }
        return (10 - weightedSum % 10) % 10 == checkDigit
    }
}

extension UIResponder {
    private static weak var foundFirstResponder: UIResponder?

    static var isTextInputFirstResponder: Bool {
        foundFirstResponder = nil
        UIApplication.shared.sendAction(#selector(captureFirstResponder), to: nil, from: nil, for: nil)
        return foundFirstResponder is UITextInput
    }

    @objc private func captureFirstResponder() {
        UIResponder.foundFirstResponder = self
    }
}
