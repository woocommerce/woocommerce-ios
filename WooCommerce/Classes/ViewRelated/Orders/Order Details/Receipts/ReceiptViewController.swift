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

        configureContent()
        configureNavigation()
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
