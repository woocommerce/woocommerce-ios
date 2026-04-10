import Foundation
import GameController
import UIKit
import WooFoundation

/// An observer that processes UIKit UIPress events for barcode scanner input.
/// This class serves as a fallback for VoiceOver scenarios where GameController framework
/// keyChangeHandler doesn't work properly.
final class UIKitBarcodeObserver {
    /// A closure that is called when a barcode scan is completed.
    /// The result will be a `success` with the barcode string or a `failure` with an HIDBarcodeParserError.
    private let onScan: (Result<String, HIDBarcodeParserError>) -> Void

    private let configuration: HIDBarcodeParserConfiguration
    private(set) var barcodeParser: GameControllerBarcodeParser?
    private let analyticsTracker: BarcodeAnalyticsTracker
    private let timeProvider: TimeProvider

    /// Initializes a new UIKit barcode scanner observer.
    /// - Parameters:
    ///   - configuration: The configuration to use for the barcode parser. Defaults to the standard configuration.
    ///   - onScan: The closure to be called when a scan is completed.
    ///   - analyticsTracker: The analytics tracker to use. Defaults to a new instance.
    ///   - timeProvider: The time provider to use for timing operations. Defaults to the system time provider.
    init(
        configuration: HIDBarcodeParserConfiguration = .default,
        analytics: POSAnalyticsProviding,
        onScan: @escaping (Result<String, HIDBarcodeParserError>) -> Void,
        timeProvider: TimeProvider = DefaultTimeProvider()
    ) {
        self.onScan = onScan
        self.configuration = configuration
        self.analyticsTracker = BarcodeAnalyticsTracker(analytics: analytics)
        self.timeProvider = timeProvider
    }


    /// Process UIPress events for barcode scanning.
    /// Translates UIKey input to GCKeyCode and feeds to existing parser infrastructure.
    func processUIPress(_ presses: Set<UIPress>) {
        // Lazily initialize parser when needed
        if barcodeParser == nil {
            barcodeParser = GameControllerBarcodeParser(
                configuration: configuration,
                onScan: { [weak self] result in
                    self?.analyticsTracker.track(result: result)
                    self?.onScan(result.asResult)
                },
                timeProvider: timeProvider
            )
        }

        for press in presses {
            guard let key = press.key else { continue }

            // Translate UIKey to GCKeyCode
            guard let keyCode = uiKeyToGCKeyCode(key) else { continue }

            // Determine shift state from modifiers
            let isShiftPressed = key.modifierFlags.contains(.shift)

            // Use existing parser with translated input
            barcodeParser?.processKeyPress(keyCode, isShiftPressed: isShiftPressed)
        }
    }

    /// Translates UIKey to equivalent GCKeyCode for consistent parsing
    private func uiKeyToGCKeyCode(_ key: UIKey) -> GCKeyCode? {
        switch key.keyCode {
        // Numbers
        case .keyboard0: return .zero
        case .keyboard1: return .one
        case .keyboard2: return .two
        case .keyboard3: return .three
        case .keyboard4: return .four
        case .keyboard5: return .five
        case .keyboard6: return .six
        case .keyboard7: return .seven
        case .keyboard8: return .eight
        case .keyboard9: return .nine

        // Letters
        case .keyboardA: return .keyA
        case .keyboardB: return .keyB
        case .keyboardC: return .keyC
        case .keyboardD: return .keyD
        case .keyboardE: return .keyE
        case .keyboardF: return .keyF
        case .keyboardG: return .keyG
        case .keyboardH: return .keyH
        case .keyboardI: return .keyI
        case .keyboardJ: return .keyJ
        case .keyboardK: return .keyK
        case .keyboardL: return .keyL
        case .keyboardM: return .keyM
        case .keyboardN: return .keyN
        case .keyboardO: return .keyO
        case .keyboardP: return .keyP
        case .keyboardQ: return .keyQ
        case .keyboardR: return .keyR
        case .keyboardS: return .keyS
        case .keyboardT: return .keyT
        case .keyboardU: return .keyU
        case .keyboardV: return .keyV
        case .keyboardW: return .keyW
        case .keyboardX: return .keyX
        case .keyboardY: return .keyY
        case .keyboardZ: return .keyZ

        // Punctuation and symbols
        case .keyboardSpacebar: return .spacebar
        case .keyboardHyphen: return .hyphen
        case .keyboardEqualSign: return .equalSign
        case .keyboardOpenBracket: return .openBracket
        case .keyboardCloseBracket: return .closeBracket
        case .keyboardBackslash: return .backslash
        case .keyboardSemicolon: return .semicolon
        case .keyboardQuote: return .quote
        case .keyboardComma: return .comma
        case .keyboardPeriod: return .period
        case .keyboardSlash: return .slash
        case .keyboardGraveAccentAndTilde: return .graveAccentAndTilde
        case .keyboardReturnOrEnter: return .returnOrEnter
        case .keyboardTab: return .tab

        default:
            return nil
        }
    }
}
