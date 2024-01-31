import WebKit

/// Previews a backend-generated receipt
final class ReceiptViewController: UIViewController {
    @IBOutlet private weak var webView: WKWebView!
    private let viewModel: ReceiptViewModel

    init(viewModel: ReceiptViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "LegacyReceiptViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureWebView()
    }

    private func configureWebView() {
        webView.load(URLRequest(url: URL(string: viewModel.receiptURLString)!))
    }
}
