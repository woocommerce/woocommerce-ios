import WebKit

/// Previews a backend-generated receipt
final class ReceiptViewController: UIViewController, WKNavigationDelegate, UIPrintInteractionControllerDelegate {
    @IBOutlet private weak var webView: WKWebView!

    private var printController: UIPrintInteractionController = UIPrintInteractionController.shared

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

    private func configurePrintController(with printInfo: UIPrintInfo) {
        // Use the webview's print formatter to initialize print operation.
        // UIPrintInteractionController printFormatter and printPageRenderer properties are mutually exclusive, in order to grab the
        // webview's page renderer, first we need to assign it to the controller's formatter:
        printController.printFormatter = webView.viewPrintFormatter()
        printController.delegate = self
        printController.printInfo = printInfo
    }

    private func configureNavigation() {
        let printButton = UIBarButtonItem(image: UIImage(systemName: "printer"),
                                          style: .plain,
                                          target: self,
                                          action: #selector(printReceipt))
        navigationItem.rightBarButtonItems = [printButton]
    }

    @objc private func printReceipt() {
        ServiceLocator.analytics.track(event: .InPersonPayments.receiptPrintTapped(countryCode: nil,
                                                                                   cardReaderModel: nil,
                                                                                   source: .backend))
        guard let _ = URL(string: viewModel.receiptURLString) else {
            return
        }
        let printInfo = UIPrintInfo(dictionary: nil)
        let formattedJobName = viewModel.formattedReceiptJobName(printInfo.jobName)
        printInfo.jobName = formattedJobName
        printInfo.orientation = .portrait
        configurePrintController(with: printInfo)

        printController.present(animated: true, completionHandler: { [weak self] _, isCompleted, error in
            if let error = error {
                ServiceLocator.analytics.track(event: .InPersonPayments.receiptPrintFailed(error: error, source: .backend))
                DDLogError("Failed to print receipt for orderID \(String(describing: self?.viewModel.orderID)). Error: \(error)")
            }
            switch isCompleted {
            case true:
                ServiceLocator.analytics.track(event: .InPersonPayments.receiptPrintSuccess(countryCode: nil, cardReaderModel: nil, source: .backend))
            case false:
                ServiceLocator.analytics.track(event: .InPersonPayments.receiptPrintCanceled(countryCode: nil, cardReaderModel: nil, source: .backend))
            }
            self?.dismiss(animated: true)
        })
    }
}

// MARK: - UIPrintInteractionControllerDelegate delegate
extension ReceiptViewController {
    func printInteractionController(_ printInteractionController: UIPrintInteractionController, choosePaper paperList: [UIPrintPaper]) -> UIPrintPaper {
        // Attempts to infer the paper size from a given content in order to optimize printing surface.
        guard let inferPaperSize = printController.printFormatter?.printPageRenderer?.paperRect.size else {
            DDLogInfo("Unable to retrieve inferred paper size from the web view. Using default paper provided by the system.")
            return paperList.first ?? UIPrintPaper()
        }

        // Constraints the printFormatter
        printController.printFormatter?.maximumContentWidth = Constants.maximumReceiptContentWidth
        printController.printFormatter?.maximumContentHeight = Constants.maximumReceiptContentHeight
        printController.printFormatter?.perPageContentInsets = .init(top: 0,
                                                                     left: Constants.margin,
                                                                     bottom: 0,
                                                                     right: Constants.margin)

        let paper = UIPrintPaper.bestPaper(forPageSize: inferPaperSize, withPapersFrom: paperList)
        return paper
    }

    func printInteractionController(_ printInteractionController: UIPrintInteractionController, cutLengthFor paper: UIPrintPaper) -> CGFloat {
        // Determines the length in which the content fits and return this value. When printed, the paper should be cut to this length.
        guard let inferPaperSize = printController.printFormatter?.printPageRenderer?.paperRect.size else {
            DDLogInfo("Unable to retrieve inferred paper size for the page renderer. Using default paper provided by the system.")
            return paper.paperSize.height
        }
        return inferPaperSize.height - Constants.defaultRollCutterMargin
    }
}

// MARK: - WKNavigation delegate
extension ReceiptViewController {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
    }
}
extension ReceiptViewController {
    enum Constants {
        static let pointsPerInch: Int = 72
        static let maximumReceiptContentWidth: CGFloat = CGFloat(4 * pointsPerInch)
        static let maximumReceiptContentHeight: CGFloat = CGFloat(11 * pointsPerInch)
        static let defaultRollCutterMargin: CGFloat = CGFloat(1 * pointsPerInch)
        static let margin: CGFloat = 16
    }
}
