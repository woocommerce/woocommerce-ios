import Foundation
import UIKit

/// Presents a screen to confirm the refund with the user.
///
/// Shows the total amount to be refunded and allows the user to enter the reason for the refund.
///
final class RefundConfirmationViewController: UIViewController {

    private lazy var tableView = UITableView(frame: .zero, style: .grouped)

    private let viewModel: RefundConfirmationViewModel

    private lazy var contextNoticePresenter: NoticePresenter = {
        let noticePresenter = DefaultNoticePresenter()
        noticePresenter.presentingViewController = self
        return noticePresenter
    }()

    /// Needed to scroll content to a visible area when the keyboard appears.
    ///
    private lazy var keyboardFrameObserver = KeyboardFrameObserver(onKeyboardFrameUpdate: { [weak self] frame in
        self?.handleKeyboardFrameUpdate(keyboardFrame: frame)
    })

    /// Closure to be invoked when the refund button is pressed.
    ///
    var onRefundButtonAction: (() -> Void)?

    /// Closure to be invoked when the refund is about to be issued.
    ///
    var onRefundCreationAction: (() -> Void)?

    /// Closure to be invoked after the refund has been issued.
    ///
    var onRefundCompletion: ((Error?) -> Void)?

    init(viewModel: RefundConfirmationViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.refundAmount

        configureMainView()
        configureTableView()
        configureButtonTableFooterView()
        configureKeyboardDismissal()
        keyboardFrameObserver.startObservingKeyboardFrame(sendInitialEvent: true)
    }
}

// MARK: KeyboardScrollable
extension RefundConfirmationViewController: KeyboardScrollable {
    var scrollable: UIScrollView {
        tableView
    }
}

// MARK: External Updates
extension RefundConfirmationViewController {
    /// Submits the refund and dismisses the flow upon successful completion.
    ///
    func submitRefund() {
        onRefundCreationAction?()
        viewModel.submit { [weak self] result in
            if let error = result.failure {
                self?.displayNotice(with: error)
            }
            self?.onRefundCompletion?(result.failure)
        }
    }
}

// MARK: - Provisioning

private extension RefundConfirmationViewController {

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        // Register cells
        [
            SettingTitleAndValueTableViewCell.self,
            TitleAndEditableValueTableViewCell.self,
            HeadlineLabelTableViewCell.self,
            WooBasicTableViewCell.self
        ].forEach(tableView.registerNib)

        // Keyboard handling
        tableView.keyboardDismissMode = .onDrag

        // Delegation
        tableView.dataSource = self

        // Style
        tableView.backgroundColor = .listBackground

        // Dimensions
        tableView.sectionFooterHeight = .leastNonzeroMagnitude

        // Add to view
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(tableView)
    }

    func configureButtonTableFooterView() {
        tableView.tableFooterView = ButtonTableFooterView(frame: .zero, title: Localization.refund) { [weak self] in
            guard let self = self else { return }
            self.onRefundButtonAction?()
            self.viewModel.trackSummaryButtonTapped()
        }
        tableView.updateFooterHeight()
    }

    /// Hides the keyboard by asking the view's first responder to resign on each main view tap.
    ///
    func configureKeyboardDismissal() {
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
}

// MARK: - UITableView Boom

extension RefundConfirmationViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.sections[safe: section]?.rows.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = viewModel.sections[safe: indexPath.section]?.rows[safe: indexPath.row] else {
            return UITableViewCell()
        }

        switch row {
        case let row as RefundConfirmationViewModel.TwoColumnRow:
            let cell = tableView.dequeueReusableCell(SettingTitleAndValueTableViewCell.self, for: indexPath)
            cell.updateUI(title: row.title, value: row.value)
            if row.isHeadline {
                cell.apply(style: .headline)
            } else {
                cell.apply(style: .bodyConsistent)
            }
            cell.selectionStyle = .none
            return cell
        case let row as RefundConfirmationViewModel.TitleAndEditableValueRow:
            let cell = tableView.dequeueReusableCell(TitleAndEditableValueTableViewCell.self, for: indexPath)
            cell.update(style: .relaxed, viewModel: row.cellViewModel)
            return cell
        case let row as RefundConfirmationViewModel.TitleAndBodyRow:
            let cell = tableView.dequeueReusableCell(HeadlineLabelTableViewCell.self, for: indexPath)
            cell.update(style: .regular, headline: row.title, body: row.body)
            cell.selectionStyle = .none
            return cell
        case let row as RefundConfirmationViewModel.SimpleTextRow:
            let cell = tableView.dequeueReusableCell(WooBasicTableViewCell.self, for: indexPath)
            cell.applyPlainTextStyle()
            cell.bodyLabel.text = row.text
            return cell
        default:
            assertionFailure("Unsupported row.")
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        viewModel.sections[safe: section]?.title
    }
}

// MARK: Submission
private extension RefundConfirmationViewController {
    /// Displays a refund error notice.
    ///
    func displayNotice(with error: Error) {
        contextNoticePresenter.enqueue(notice: .init(title: Localization.refundError))
    }
}

// MARK: Interactive Dismiss
extension RefundConfirmationViewController: IssueRefundInteractiveDismissDelegate {
    /// Don't allow interactive dismiss gesture.
    ///
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        false
    }
}

// MARK: - Localization

private extension RefundConfirmationViewController {
    enum Localization {
        static let refund = NSLocalizedString("Refund", comment: "The title of the button to confirm the refund.")
        static let refundError = NSLocalizedString("There was an error issuing the refund",
                                                   comment: "Text of the notice that is displayed while the refund creation fails.")
    }
}
