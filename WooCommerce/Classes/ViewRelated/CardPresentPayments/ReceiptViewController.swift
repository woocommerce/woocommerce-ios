import MessageUI
import Combine
import UIKit
import WebKit
import Yosemite


/// Previews a receipt
final class ReceiptViewController: UIViewController {
    @IBOutlet private weak var webView: WKWebView!

    private let viewModel: ReceiptViewModel

    private var emailCoordinator: CardPresentPaymentReceiptEmailCoordinator?
    private var receiptContentSubscription: AnyCancellable?
    private var emailDataSubscription: AnyCancellable?

    init(viewModel: ReceiptViewModel) {
        self.viewModel = viewModel
        super.init(nibName: Self.nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureToolbar()
        configureBackground()
        observeReceiptContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        syncReceiptContent()
    }
}

private extension ReceiptViewController {
    func configureToolbar() {
        title = Localization.title
        navigationItem.rightBarButtonItems = [
            MFMailComposeViewController.canSendMail() ?
            UIBarButtonItem(image: .mailImage,
                            style: .plain,
                            target: self,
                            action: #selector(emailReceipt)): nil,
            UIBarButtonItem(image: .print,
                            style: .plain,
                            target: self,
                            action: #selector(printReceipt))
        ].compactMap { $0 }
    }

    func configureBackground() {
        view.backgroundColor = .systemBackground
    }

    func syncReceiptContent() {
        viewModel.generateContent()
    }

    func observeReceiptContent() {
        receiptContentSubscription = viewModel.content.sink { [weak self] content in
            self?.webView.loadHTMLString(content, baseURL: nil)
        }
    }

    @objc func printReceipt() {
        viewModel.printReceipt()
    }

    @objc func emailReceipt() {
        emailDataSubscription = viewModel.emailReceiptTapped().sink { [weak self] data, countryCode in
            guard let self = self else { return }
            let emailCoordinator = CardPresentPaymentReceiptEmailCoordinator(countryCode: countryCode, cardReaderModel: nil)
            self.emailCoordinator = emailCoordinator
            emailCoordinator.presentEmailForm(data: data,
                                              from: self,
                                              completion: {})
        }
    }
}

private extension ReceiptViewController {
    enum Localization {
        static let title = NSLocalizedString(
            "Receipt",
            comment: "The title of the view containing a receipt preview"
        )
    }
}
