import SwiftUI

/// A SwiftUI view that provides barcode scanning functionality by capturing keyboard input.
/// This container is designed to be invisible and non-interactive, serving as a bridge between
/// physical barcode scanners and the app's scanning functionality.
///
/// The container works by capturing keyboard input events and interpreting them as barcode scans
/// when a terminating character is detected.
@available(iOS 17.0, *)
struct BarcodeScannerContainer: View {
    /// Configuration for the barcode scanner
    let configuration: HIDBarcodeParserConfiguration
    /// Callback that is triggered when a barcode scan completes (success or failure)
    let onScan: (Result<String, HIDBarcodeParserError>) -> Void

    init(
        configuration: HIDBarcodeParserConfiguration = .default,
        onScan: @escaping (Result<String, HIDBarcodeParserError>) -> Void
    ) {
        self.configuration = configuration
        self.onScan = onScan
    }

    var body: some View {
        BarcodeScannerContainerRepresentable(
            configuration: configuration,
            onScan: onScan
        )
        .frame(width: 0, height: 0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A UIViewControllerRepresentable that bridges SwiftUI with UIKit to handle keyboard input events.
/// This component is responsible for creating and managing the UIKit view controller that captures
/// keyboard input for barcode scanning.
struct BarcodeScannerContainerRepresentable: UIViewControllerRepresentable {
    let configuration: HIDBarcodeParserConfiguration
    let onScan: (Result<String, HIDBarcodeParserError>) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        return GameControllerBarcodeScannerHostingController(
            configuration: configuration,
            onScan: onScan
        )
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

/// A UIHostingController that handles GameController keyboard input events for barcode scanning.
/// This controller uses GameController framework exclusively for language-independent barcode scanning.
final class GameControllerBarcodeScannerHostingController: UIHostingController<EmptyView> {
    private var gameControllerBarcodeObserver: GameControllerBarcodeObserver?

    init(
        configuration: HIDBarcodeParserConfiguration,
        onScan: @escaping (Result<String, HIDBarcodeParserError>) -> Void
    ) {
        super.init(rootView: EmptyView())

        gameControllerBarcodeObserver = GameControllerBarcodeObserver(configuration: configuration, onScan: onScan)
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        gameControllerBarcodeObserver = nil
    }

    // MARK: - VoiceOver Support
    /// Barcode scanner  input is not received through GameController framework keyChangeHandler if VoiceOver is enabled.

    override var canBecomeFirstResponder: Bool {
        // Only become first responder when VoiceOver is running as fallback for GameController limitations
        return UIAccessibility.isVoiceOverRunning
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard UIAccessibility.isVoiceOverRunning else { return }

        becomeFirstResponder()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        guard UIAccessibility.isVoiceOverRunning else { return }

        resignFirstResponder()
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        // Don't call super to prevent system from hiding software keyboard
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        // When VoiceOver is running, use UIPress fallback since GameController keyChangeHandler doesn't work
        guard UIAccessibility.isVoiceOverRunning else { return }

        gameControllerBarcodeObserver?.processUIPress(presses)
        // Don't call super to prevent other responders from handling our barcode input
    }

    override func pressesChanged(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesChanged(presses, with: event)
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if UIAccessibility.isVoiceOverRunning {
            gameControllerBarcodeObserver?.barcodeParser?.cancel()
        }
        super.pressesCancelled(presses, with: event)
    }
}
