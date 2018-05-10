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

    enum Section: Int {
        case summary = 0
        case fulfillment = 1
        case customerNote = 2
        case info = 3
        case payment = 4
        case orderNotes = 5
    }

    enum CustomerInfoRow: Int {
        case shipping = 0
        case billing = 1
        case billingPhone = 2
        case billingEmail = 3
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
        let orderSummary = ""
        let fulfillItems = ""
        var customerNoteTitle = NSLocalizedString("CUSTOMER PROVIDED NOTE", comment: "Customer note section title")
        let customerInfo = NSLocalizedString("CUSTOMER INFORMATION", comment: "Customer info section title")
        let paymentDetails = NSLocalizedString("PAYMENT", comment: "Payment section title")
        let orderNotes = NSLocalizedString("ORDER NOTES", comment: "Order notes section title")
        if let customerNote = order.customerNote {
            if customerNote.isEmpty {
                customerNoteTitle = ""
            }
        }
        sectionTitles = [orderSummary, fulfillItems, customerNoteTitle, customerInfo, paymentDetails, orderNotes]
    }

    func configureNibs() {
        let summaryNib = UINib(nibName: OrderDetailsSummaryCell.reuseIdentifier, bundle: nil)
        tableView.register(summaryNib, forCellReuseIdentifier: OrderDetailsSummaryCell.reuseIdentifier)
        let noteNib = UINib(nibName: OrderDetailsCustomerNoteCell.reuseIdentifier, bundle: nil)
        tableView.register(noteNib, forCellReuseIdentifier: OrderDetailsCustomerNoteCell.reuseIdentifier)
        let infoNib = UINib(nibName: OrderDetailsCustomerInfoCell.reuseIdentifier, bundle: nil)
        tableView.register(infoNib, forCellReuseIdentifier: OrderDetailsCustomerInfoCell.reuseIdentifier)
        let footerNib = UINib(nibName: ShowHideFooterCell.reuseIdentifier, bundle: nil)
        tableView.register(footerNib, forHeaderFooterViewReuseIdentifier: ShowHideFooterCell.reuseIdentifier)
    }
}

// MARK: - Table Data Source
//
extension OrderDetailsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitles.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == Section.summary.rawValue ||
            section == Section.fulfillment.rawValue ||
            section == Section.payment.rawValue {
        return 1
    }

        if section == Section.customerNote.rawValue {
            let numberOfRows = order.customerNote?.isEmpty == false ? 1 : 0
            return numberOfRows
        }

        if section == Section.info.rawValue {
            let shippingRow = 1
            let billingAddressRow = billingIsHidden ? 0 : 1
            let billingPhoneRow = billingIsHidden || order.billingAddress.phone?.isEmpty == true ? 0 : 1
            let billingEmailRow = billingIsHidden || order.billingAddress.email?.isEmpty == true ? 0 : 1
            return shippingRow + billingAddressRow + billingPhoneRow + billingEmailRow
        }

        if section == Section.orderNotes.rawValue {
            let titleRow = 1
            let addNoteRow = 1
            let totalNotes = order.notes?.count ?? 0
            return titleRow + addNoteRow + totalNotes
        }

        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case Section.summary.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: OrderDetailsSummaryCell.reuseIdentifier, for: indexPath) as! OrderDetailsSummaryCell
            cell.configure(with: viewModel)
            return cell

        case Section.customerNote.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: OrderDetailsCustomerNoteCell.reuseIdentifier, for: indexPath) as! OrderDetailsCustomerNoteCell
            cell.configure(with: viewModel)
            return cell

        case Section.info.rawValue:
            switch indexPath.row {
            case CustomerInfoRow.shipping.rawValue:
                let cell = tableView.dequeueReusableCell(withIdentifier: OrderDetailsCustomerInfoCell.reuseIdentifier, for: indexPath) as! OrderDetailsCustomerInfoCell
                let viewModel = ContactViewModel(with: order.shippingAddress, contactType: .shipping)
                cell.configure(with: viewModel)
                return cell
            case CustomerInfoRow.billing.rawValue:
                let cell = tableView.dequeueReusableCell(withIdentifier: OrderDetailsCustomerInfoCell.reuseIdentifier, for: indexPath) as! OrderDetailsCustomerInfoCell
                let viewModel = ContactViewModel(with: order.billingAddress, contactType: .billing)
                cell.configure(with: viewModel)
                return cell
            case CustomerInfoRow.billingPhone.rawValue:
                let viewModel = ContactViewModel(with: order.billingAddress, contactType: .billing)
                return configureBillingPhoneCell(viewModel: viewModel)
            case CustomerInfoRow.billingEmail.rawValue:
                let viewModel = ContactViewModel(with: order.billingAddress, contactType: .billing)
                return configureBillingEmailCell(viewModel: viewModel)
            default:
                fatalError()
            }
            default:
                return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if sectionTitles[section].isEmpty {
            return 0.0001
        }
        return UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if sectionTitles[section].isEmpty {
            return nil
        }
        return sectionTitles[section]
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == Section.info.rawValue {
            return 38
        }
        return 0.0001
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == Section.info.rawValue {
            let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: ShowHideFooterCell.reuseIdentifier) as! ShowHideFooterCell
            cell.configureCell(isHidden: billingIsHidden)
            cell.didSelectFooter = { [weak self] in
                self?.setShowHideFooter()
                // it would be nice to have `tableView.reloadSections([section], with: .bottom)`
                // but iOS 11 has an ugly animation bug https://forums.developer.apple.com/thread/86703
                tableView.reloadData()
            }
            return cell
        }
        let zeroFrame = CGRect(x: 0, y: 0, width: 0, height: 0.001)
        return UIView(frame: zeroFrame)
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
        phoneButton.frame = CGRect(x: 8, y: 0, width: 44, height: 44)
        phoneButton.setImage(Gridicon.iconOfType(.ellipsis), for: .normal)
        phoneButton.tintColor = StyleManager.wooCommerceBrandColor
        phoneButton.addTarget(self, action: #selector(phoneButtonAction), for: .touchUpInside)

        let iconView = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
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
        emailButton.frame = CGRect(x: 8, y: 0, width: 44, height: 44)
        emailButton.setImage(Gridicon.iconOfType(.mail), for: .normal)
        emailButton.tintColor = StyleManager.wooCommerceBrandColor
        emailButton.addTarget(self, action: #selector(emailButtonAction), for: .touchUpInside)

        let iconView = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
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
            self?.sendTextMessage()
        }
        actionSheet.addAction(messageAction)

        present(actionSheet, animated: true)
    }

    @objc func emailButtonAction() {
        sendEmail()
    }

    func setShowHideFooter() {
        billingIsHidden = !billingIsHidden
    }
}

// MARK: - Messages Delgate
//
extension OrderDetailsViewController: MFMessageComposeViewControllerDelegate {
    func sendTextMessage() {
        let contactViewModel = ContactViewModel(with: order.billingAddress, contactType: .billing)
        guard let phoneNumber = contactViewModel.cleanedPhoneNumber else {
            return
        }
        if MFMessageComposeViewController.canSendText() {
            let controller = MFMessageComposeViewController()
            controller.recipients = [phoneNumber]
            controller.messageComposeDelegate = self
            present(controller, animated: true, completion: nil)
        }
    }

    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Email Delegate
//
extension OrderDetailsViewController: MFMailComposeViewControllerDelegate {
    func sendEmail() {
        if MFMailComposeViewController.canSendMail() {
            let contactViewModel = ContactViewModel(with: order.billingAddress, contactType: .billing)
            guard let email = contactViewModel.email else {
                return
            }
            let controller = MFMailComposeViewController()
            controller.setToRecipients([email])
            controller.mailComposeDelegate = self
            present(controller, animated: true, completion: nil)
        }
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
