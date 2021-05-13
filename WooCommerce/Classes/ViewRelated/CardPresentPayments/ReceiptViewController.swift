import UIKit
import WebKit
import Yosemite

final class ReceiptViewController: UIViewController {
    @IBOutlet private weak var webView: WKWebView!

    private let viewModel: ReceiptViewModel

    init(viewModel: ReceiptViewModel) {
        self.viewModel = viewModel
        super.init(nibName: Self.nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureBackground()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        syncReceiptContent()
    }
}

private extension ReceiptViewController {
    func configureBackground() {
        view.backgroundColor = .systemBackground
    }

    func syncReceiptContent() {
        viewModel.generateContent { [weak self] content in
            self?.webView.loadHTMLString(content, baseURL: nil)
        }
    }
}
