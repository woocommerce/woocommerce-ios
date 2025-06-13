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
    /// Callback that is triggered when a barcode is successfully scanned
    let onScan: (String) -> Void

    init(
        configuration: HIDBarcodeParserConfiguration = .default,
        onScan: @escaping (String) -> Void
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
    let onScan: (String) -> Void

    func makeUIViewController(context: Context) -> BarcodeScannerHostingController {
        let controller = BarcodeScannerHostingController(
            configuration: configuration,
            onScan: onScan
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerHostingController, context: Context) {
        uiViewController.configuration = configuration
        uiViewController.onScan = onScan
    }
}

/// A UIHostingController that handles keyboard input events for barcode scanning.
/// This controller captures keyboard input and interprets it as barcode data when a terminating
/// character is detected.
class BarcodeScannerHostingController: UIHostingController<EmptyView> {
    var configuration: HIDBarcodeParserConfiguration
    var onScan: (String) -> Void

    private let scanner: HIDBarcodeParser

    init(
        configuration: HIDBarcodeParserConfiguration,
        onScan: @escaping (String) -> Void
    ) {
        self.configuration = configuration
        self.onScan = onScan
        self.scanner = HIDBarcodeParser(configuration: configuration, onScan: onScan)
        super.init(rootView: EmptyView())
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var canBecomeFirstResponder: Bool { true }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        resignFirstResponder()
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        /// We don't call super here because it helps prevent the system from hiding the software keyboard when
        /// a textfield is next used.
    }

    /// Handles the end of keyboard press events, interpreting them as barcode input.
    /// When a terminating character is detected, the accumulated buffer is treated as a complete
    /// barcode and passed to the onScan callback.
    /// We don't call `super` here because we don't other responder chain items to handle our barcode as well,
    /// as this could cause unexpected behavior.
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        /// While a scanner should just "press" each key once, in theory it's possible for presses to be cancelled
        /// or change between the `began` call and the `ended` call.
        /// It's better practice for barcode scanning to only consider the presses when they end.
        for press in presses {
            guard let key = press.key?.charactersIgnoringModifiers else { continue }
            scanner.processKeyPress(key)
        }
    }

    override func pressesChanged(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesChanged(presses, with: event)
    }

    /// `pressesCancelled` is rarely called, but Apple's documentation suggests it's possible and that crashes may occur if it's not handled.
    /// It makes sense to clear the buffer when this happens.
    /// We call super in case other presses are handled elsewhere in the responder chain.
    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        scanner.cancel()
        super.pressesCancelled(presses, with: event)
    }
}
