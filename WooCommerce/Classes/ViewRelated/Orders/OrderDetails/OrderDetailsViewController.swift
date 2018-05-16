import UIKit
import Gridicons
import Contacts
import MessageUI

class OrderDetailsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    var order: Order! {
        didSet {
            refreshViewModel()
        }
    }

    var viewModel: OrderDetailsViewModel!
    var sectionTitles = [String]()
    var billingIsHidden = true
    private var sections = [Section]()

    func refreshViewModel() {
        viewModel = OrderDetailsViewModel(order: order)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        title = NSLocalizedString("Order #\(order.number)", comment:"Order number title")
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }

    func configureTableView() {
        configureSections()
        configureNibs()
    }

    func configureSections() {
        let summarySection = Section(title: nil, footer: nil, rows: [.summary])
        let customerNoteSection = Section(title: NSLocalizedString("CUSTOMER PROVIDED NOTE", comment: "Customer note section title"), footer: nil, rows: [.customerNote])

        let infoFooter = billingIsHidden ? NSLocalizedString("Show billing", comment: "Footer text to show the billing cell") : NSLocalizedString("Hide billing", comment: "Footer text to hide the billing cell")
        let infoRows: [Row] = billingIsHidden ? [.shippingAddress] : [.shippingAddress, .billingAddress, .billingPhone, .billingEmail]
        let customerInfoSection = Section(title: NSLocalizedString("CUSTOMER INFORMATION", comment: "Customer info section title"), footer: infoFooter, rows: infoRows)

        // FIXME: this is temporary
        // the API response always sends customer note data
        // if there is no customer note it sends an empty string
        // but order has customerNote as an optional property right now
        guard let customerNote = order.customerNote,
            !customerNote.isEmpty else {
            sections = [summarySection, customerInfoSection]
            return
        }
        sections = [summarySection, customerNoteSection, customerInfoSection]
    }

    func configureNibs() {
        for section in sections {
            for row in section.rows {
                if row != .billingEmail || row != .billingPhone {
                    let nib = UINib(nibName: row.reuseIdentifier, bundle: nil)
                    tableView.register(nib, forCellReuseIdentifier: row.reuseIdentifier)
                }
            }
        }

        let footerNib = UINib(nibName: ShowHideFooterCell.reuseIdentifier, bundle: nil)
        tableView.register(footerNib, forHeaderFooterViewReuseIdentifier: ShowHideFooterCell.reuseIdentifier)
    }
}

// MARK: - Table Data Source
//
extension OrderDetailsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        let cell: UITableViewCell
        switch row {
        case .billingPhone:
            cell = UITableViewCell(style: .default, reuseIdentifier: row.reuseIdentifier)
        case .billingEmail:
            cell = UITableViewCell(style: .default, reuseIdentifier: row.reuseIdentifier)
        default:
            cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        }
        configure(cell, for: row)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard sections[section].title != nil else {
            // iOS 11 table bug. Must return a tiny value to collapse `nil` or `empty` section headers.
            return CGFloat.leastNonzeroMagnitude
        }
        return UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard sections[section].footer != nil else {
            // iOS 11 table bug. Must return a tiny value to collapse `nil` or `empty` section footers.
            return CGFloat.leastNonzeroMagnitude
        }
        return Constants.rowHeight
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footerText = sections[section].footer else {
            return nil
        }

        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: ShowHideFooterCell.reuseIdentifier) as! ShowHideFooterCell
        let image = billingIsHidden ? Gridicon.iconOfType(.chevronDown) : Gridicon.iconOfType(.chevronUp)
        cell.configure(text: footerText, image: image)
        cell.didSelectFooter = { [weak self] in
            self?.setShowHideFooter()
            self?.configureSections()
            let sections = IndexSet(integer: section)
            tableView.reloadSections(sections, with: .fade)
        }
        return cell
    }
}

// MARK: - Table Delegate
//
extension OrderDetailsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Extension
//
extension OrderDetailsViewController {
    private func configure(_ cell: UITableViewCell, for row: Row) {
        var contactViewModel: ContactViewModel
        switch cell {
        case let cell as OrderDetailsSummaryCell:
            cell.configure(with: viewModel)
        case let cell as OrderDetailsCustomerNoteCell:
            cell.configure(with: viewModel)
        case let cell as OrderDetailsCustomerInfoCell:
            switch row {
            case .shippingAddress:
                contactViewModel = ContactViewModel(with: order.shippingAddress, contactType: .shipping)
                cell.configure(with: contactViewModel)
            case .billingAddress:
                contactViewModel = ContactViewModel(with: order.billingAddress, contactType: .billing)
                cell.configure(with: contactViewModel)
            case .billingPhone:
                fatalError("Billing phone number cell should be default tableview cell type")
            case .billingEmail:
                fatalError("Billing email cell should be default tableview cell type")
            default:
                fatalError()
            }
        default:
            switch row {
            case .billingPhone:
                contactViewModel = ContactViewModel(with: order.billingAddress, contactType: .billing)
                configureBillingPhone(cell, with: contactViewModel)
            case .billingEmail:
                contactViewModel = ContactViewModel(with: order.billingAddress, contactType: .billing)
                configureBillingEmail(cell, with: contactViewModel)
            default:
                fatalError()
            }
        }
    }

    func configureBillingPhone(_ cell: UITableViewCell, with viewModel: ContactViewModel) {
        cell.textLabel?.applyBodyStyle()

        let phoneButton = UIButton(type: .custom)
        phoneButton.frame = Constants.iconFrame
        phoneButton.setImage(Gridicon.iconOfType(.ellipsis), for: .normal)
        phoneButton.tintColor = StyleManager.wooCommerceBrandColor
        phoneButton.addTarget(self, action: #selector(phoneButtonAction), for: .touchUpInside)

        let iconView = UIView(frame: Constants.accessoryFrame)
        iconView .addSubview(phoneButton)
        cell.accessoryView = iconView
        cell.textLabel?.text = viewModel.phoneNumber
        cell.textLabel?.adjustsFontSizeToFitWidth = true
    }

    func configureBillingEmail(_ cell: UITableViewCell, with viewModel: ContactViewModel) {
        cell.textLabel?.applyBodyStyle()

        let emailButton = UIButton(type: .custom)
        emailButton.frame = Constants.iconFrame
        emailButton.setImage(Gridicon.iconOfType(.mail), for: .normal)
        emailButton.tintColor = StyleManager.wooCommerceBrandColor
        emailButton.addTarget(self, action: #selector(emailButtonAction), for: .touchUpInside)

        let iconView = UIView(frame: Constants.accessoryFrame)
        iconView .addSubview(emailButton)
        cell.accessoryView = iconView
        cell.textLabel?.text = viewModel.email
        cell.textLabel?.adjustsFontSizeToFitWidth = true
    }

    @objc func phoneButtonAction() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = StyleManager.wooCommerceBrandColor
        let dismissAction = UIAlertAction(title: NSLocalizedString("Dismiss", comment: "Dismiss the action sheet"), style: .cancel)
        actionSheet.addAction(dismissAction)

        let callAction = UIAlertAction(title: NSLocalizedString("Call", comment: "Call phone number button title"), style: .default) { [weak self] action in
            let contactViewModel = ContactViewModel(with: (self?.order.billingAddress)!, contactType: .billing)
            guard let phone = contactViewModel.cleanedPhoneNumber else {
                return
            }
            if let url = URL(string: "telprompt://" + phone),
                UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        actionSheet.addAction(callAction)

        let messageAction = UIAlertAction(title: NSLocalizedString("Message", comment: "Message phone number button title"), style: .default) { [weak self] action in
            self?.sendTextMessageIfPossible()
        }
        actionSheet.addAction(messageAction)

        present(actionSheet, animated: true)
    }

    @objc func emailButtonAction() {
        sendEmailIfPossible()
    }

    func setShowHideFooter() {
        billingIsHidden = !billingIsHidden
    }
}

// MARK: - Messages Delgate
//
extension OrderDetailsViewController: MFMessageComposeViewControllerDelegate {
    func sendTextMessageIfPossible() {
        let contactViewModel = ContactViewModel(with: order.billingAddress, contactType: .billing)
        guard let phoneNumber = contactViewModel.cleanedPhoneNumber else {
            return
        }
        if MFMessageComposeViewController.canSendText() {
            sendTextMessage(to: phoneNumber)
        }
    }

    private func sendTextMessage(to phoneNumber: String) {
        let controller = MFMessageComposeViewController()
        controller.recipients = [phoneNumber]
        controller.messageComposeDelegate = self
        present(controller, animated: true, completion: nil)
    }

    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Email Delegate
//
extension OrderDetailsViewController: MFMailComposeViewControllerDelegate {
    func sendEmailIfPossible() {
        if MFMailComposeViewController.canSendMail() {
            let contactViewModel = ContactViewModel(with: order.billingAddress, contactType: .billing)
            guard let email = contactViewModel.email else {
                return
            }
            sendEmail(to: email)
        }
    }

    private func sendEmail(to email: String) {
        let controller = MFMailComposeViewController()
        controller.setToRecipients([email])
        controller.mailComposeDelegate = self
        present(controller, animated: true, completion: nil)
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

private extension OrderDetailsViewController {
    struct Constants {
        static let rowHeight = CGFloat(38)
        static let iconFrame = CGRect(x: 8, y: 0, width: 44, height: 44)
        static let accessoryFrame = CGRect(x: 0, y: 0, width: 44, height: 44)
        static let billingPhoneReuseIdentifier = "BillingPhoneCell"
        static let billingEmailReuseIdentifier = "BillingEmailCell"
    }

    private struct Section {
        let title: String?
        let footer: String?
        let rows: [Row]
    }

    private enum Row {
        case summary
        case customerNote
        case shippingAddress
        case billingAddress
        case billingPhone
        case billingEmail

        var reuseIdentifier: String {
            switch self {
            case .summary:
                return OrderDetailsSummaryCell.reuseIdentifier
            case .customerNote:
                return OrderDetailsCustomerNoteCell.reuseIdentifier
            case .shippingAddress:
                return OrderDetailsCustomerInfoCell.reuseIdentifier
            case .billingAddress:
                return OrderDetailsCustomerInfoCell.reuseIdentifier
            case .billingPhone:
                return Constants.billingPhoneReuseIdentifier
            case .billingEmail:
                return Constants.billingEmailReuseIdentifier
            }
        }
    }
}
