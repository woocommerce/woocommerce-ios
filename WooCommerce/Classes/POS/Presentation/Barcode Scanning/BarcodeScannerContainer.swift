import SwiftUI

/// A SwiftUI view that provides barcode scanning functionality by capturing keyboard input.
/// This container is designed to be invisible and non-interactive, serving as a bridge between
/// physical barcode scanners and the app's scanning functionality.
///
/// The container works by capturing keyboard input events and interpreting them as barcode scans
/// when a terminating character is detected.
@available(iOS 17.0, *)
struct BarcodeScannerContainer: View {
    /// Callback that is triggered when a barcode is successfully scanned
    let onScan: (String) -> Void

    var body: some View {
        BarcodeScannerContainerRepresentable(onScan: onScan)
            .frame(width: 0, height: 0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// A UIViewControllerRepresentable that bridges SwiftUI with UIKit to handle keyboard input events.
/// This component is responsible for creating and managing the UIKit view controller that captures
/// keyboard input for barcode scanning.
struct BarcodeScannerContainerRepresentable<Content: View>: UIViewControllerRepresentable {
    let content: Content
    let onScan: (String) -> Void

    init(@ViewBuilder content: () -> Content = { EmptyView() }, onScan: @escaping (String) -> Void) {
        self.content = content()
        self.onScan = onScan
    }

    func makeUIViewController(context: Context) -> BarcodeScannerHostingController<Content> {
        let controller = BarcodeScannerHostingController(rootView: content)
        controller.onScan = onScan
        return controller
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerHostingController<Content>, context: Context) {
        uiViewController.rootView = content
        uiViewController.onScan = onScan
    }
}

/// A UIHostingController that handles keyboard input events for barcode scanning.
/// This controller captures keyboard input and interprets it as barcode data when a terminating
/// character is detected.
class BarcodeScannerHostingController<Content: View>: UIHostingController<Content> {
    var onScan: ((String) -> Void)?
    private var buffer = ""

    override var canBecomeFirstResponder: Bool { true }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesBegan(presses, with: event)
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
            if let key = press.key?.charactersIgnoringModifiers {
                if key == "\r" || key == "\n" {
                    onScan?(buffer)
                    buffer = ""
                } else {
                    buffer.append(key)
                }
            }
        }
    }

    override func pressesChanged(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesChanged(presses, with: event)
    }

    /// `pressesCancelled` is rarely called, but Apple's documentation suggests it's possible and that crashes may occur if it's not handled.
    /// It makes sense to clear the buffer when this happens.
    /// We call super in case other presses are handled elsewhere in the responder chain.
    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        buffer = ""
        super.pressesCancelled(presses, with: event)
    }
}
