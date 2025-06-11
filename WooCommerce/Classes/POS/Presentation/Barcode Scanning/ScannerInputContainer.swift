import SwiftUI

@available(iOS 17.0, *)
struct ScannerInputContainer: View {
    let onScan: (String) -> Void

    var body: some View {
        ScannerInputContainerRepresentable(onScan: onScan)
            .frame(width: 0, height: 0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

struct ScannerInputContainerRepresentable<Content: View>: UIViewControllerRepresentable {
    let content: Content
    let onScan: (String) -> Void

    init(@ViewBuilder content: () -> Content = { EmptyView() }, onScan: @escaping (String) -> Void) {
        self.content = content()
        self.onScan = onScan
    }

    func makeUIViewController(context: Context) -> ScannerInputHostingController<Content> {
        let controller = ScannerInputHostingController(rootView: content)
        controller.onScan = onScan
        return controller
    }

    func updateUIViewController(_ uiViewController: ScannerInputHostingController<Content>, context: Context) {
        uiViewController.rootView = content
        uiViewController.onScan = onScan
    }
}

class ScannerInputHostingController<Content: View>: UIHostingController<Content> {
    var onScan: ((String) -> Void)?
    private var buffer = ""

    override var canBecomeFirstResponder: Bool { true }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
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
}
