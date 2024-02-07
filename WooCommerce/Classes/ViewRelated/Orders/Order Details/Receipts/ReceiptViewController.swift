import WebKit

/// Previews a backend-generated receipt
final class ReceiptViewController: UIViewController, WKNavigationDelegate {
    @IBOutlet private weak var webView: WKWebView!

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private let viewModel: ReceiptViewModel
    
    var onDisappear: (() -> Void)?

    init(viewModel: ReceiptViewModel, onDisappear: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onDisappear = onDisappear
        super.init(nibName: "LegacyReceiptViewController", bundle: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onDisappear?()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureContent()
        configureNavigation()
        configureActivityIndicator()

        webView.navigationDelegate = self
    }

    func configureActivityIndicator() {
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: activityIndicator.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: activityIndicator.centerYAnchor)
        ])

        activityIndicator.startAnimating()
    }

    private func configureContent() {
        guard let receipt = viewModel.receiptRequest else {
            DDLogError("No receipt could be found for orderID \(viewModel.orderID)")
            navigationController?.popViewController(animated: true)
            return
        }
        webView.load(receipt)
    }

    private func configureNavigation() {
        let shareButton = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"),
                                          style: .plain,
                                          target: self,
                                          action: #selector(shareReceipt))
        let printButton = UIBarButtonItem(image: UIImage(systemName: "printer"),
                                          style: .plain,
                                          target: self,
                                          action: #selector(printReceipt))
        navigationItem.rightBarButtonItems = [shareButton, printButton]
    }

    @objc private func shareReceipt() {
        guard let url = URL(string: viewModel.receiptURLString) else {
            return
        }
        let activityViewController = UIActivityViewController(activityItems: [url],
                                                applicationActivities: nil)
        present(activityViewController, animated: true)
    }

    @objc private func printReceipt() {
        guard let url = URL(string: viewModel.receiptURLString) else {
            return
        }
        let printController = UIPrintInteractionController.shared

        let printInfo = UIPrintInfo(dictionary: nil)
        let formattedJobName = viewModel.formattedReceiptJobName(printInfo.jobName)
        printInfo.jobName = formattedJobName

        printController.printInfo = printInfo
        printController.printFormatter = webView.viewPrintFormatter()

        printController.present(animated: true, completionHandler: { [weak self] _, isCompleted, error in
            if let error = error {
                DDLogError("Failed to print receipt for orderID \(String(describing: self?.viewModel.orderID)). Error: \(error)")
            } else if isCompleted {
                self?.dismiss(animated: true)
            }
        })
    }
}

// MARK: - WKNavigation delegate
extension ReceiptViewController {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
    }
}
