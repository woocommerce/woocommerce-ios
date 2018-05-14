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

    private struct Section {
        let title: String
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

        var cellType: AnyClass {
            switch self {
            case .summary:
                return OrderDetailsSummaryCell.self
            case .customerNote:
                return OrderDetailsCustomerNoteCell.self
            case .shippingAddress:
                return OrderDetailsCustomerInfoCell.self
            case .billingAddress:
                return OrderDetailsCustomerInfoCell.self
            case .billingPhone:
                return UITableViewCell.self
            case .billingEmail:
                return UITableViewCell.self
            }
        }
    }

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
        let summarySection = Section(title: "", rows: [.summary])
        let customerNoteSection = Section(title: NSLocalizedString("CUSTOMER PROVIDED NOTE", comment: "Customer note section title"), rows: [.customerNote])
        let customerInfoSection = Section(title: NSLocalizedString("CUSTOMER INFORMATION", comment: "Customer info section title"), rows: [.shippingAddress, .billingAddress, .billingPhone, .billingEmail])

        sections = [summarySection, customerNoteSection, customerInfoSection]
    }

    func configureNibs() {
        for section in sections {
            for row in section.rows {
                let nib = UINib(nibName: row.reuseIdentifier, bundle: nil)
                tableView.register(nib, forCellReuseIdentifier: row.reuseIdentifier)
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
        let section = sections[indexPath.section]
        let row = section.rows[indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath) as! row.cellType
            cell.configure(with: viewModel)
        return cell

//        switch indexPath.section {
//        case Section.summary:
//            let cell = tableView.dequeueReusableCell(withIdentifier: OrderDetailsSummaryCell.reuseIdentifier, for: indexPath) as! OrderDetailsSummaryCell
//            cell.configure(with: viewModel)
//            return cell
//
//        case Section.customerNote.rawValue:
//            let cell = tableView.dequeueReusableCell(withIdentifier: OrderDetailsCustomerNoteCell.reuseIdentifier, for: indexPath) as! OrderDetailsCustomerNoteCell
//            cell.configure(with: viewModel)
//            return cell
//
//        case Section.info.rawValue:
//            switch indexPath.row {
//            case CustomerInfoRow.shipping.rawValue:
//                let cell = tableView.dequeueReusableCell(withIdentifier: OrderDetailsCustomerInfoCell.reuseIdentifier, for: indexPath) as! OrderDetailsCustomerInfoCell
//                let viewModel = ContactViewModel(with: order.shippingAddress, contactType: .shipping)
//                cell.configure(with: viewModel)
//                return cell
//            case CustomerInfoRow.billing.rawValue:
//                let cell = tableView.dequeueReusableCell(withIdentifier: OrderDetailsCustomerInfoCell.reuseIdentifier, for: indexPath) as! OrderDetailsCustomerInfoCell
//                let viewModel = ContactViewModel(with: order.billingAddress, contactType: .billing)
//                cell.configure(with: viewModel)
//                return cell
//            case CustomerInfoRow.billingPhone.rawValue:
//                let viewModel = ContactViewModel(with: order.billingAddress, contactType: .billing)
//                return configureBillingPhoneCell(viewModel: viewModel)
//            case CustomerInfoRow.billingEmail.rawValue:
//                let viewModel = ContactViewModel(with: order.billingAddress, contactType: .billing)
//                return configureBillingEmailCell(viewModel: viewModel)
//            default:
//                fatalError()
//            }
//            default:
//                return UITableViewCell()
//        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if sections[section].title.isEmpty {
            // iOS 11 table bug. Must return a tiny value to collapse empty section headers.
            return CGFloat.leastNonzeroMagnitude
        }
        return UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if sections[section].title.isEmpty {
            return nil
        }
        return sectionTitles[section]
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if sections[section].title.isEmpty{
            // iOS 11 table bug. Must return a tiny value to collapse empty section footers.
            return CGFloat.leastNonzeroMagnitude
        }
        return Constants.rowHeight
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section == Section.info.rawValue else {
            return nil
        }
        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: ShowHideFooterCell.reuseIdentifier) as! ShowHideFooterCell
        cell.configureCell(isHidden: billingIsHidden)
        cell.didSelectFooter = { [weak self] in
            self?.setShowHideFooter()
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
    func configureBillingPhoneCell(viewModel: ContactViewModel) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "BillingPhoneCell")
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

        return cell
    }

    func configureBillingEmailCell(viewModel: ContactViewModel) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "BillingEmailCell")
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
        return cell
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
}
