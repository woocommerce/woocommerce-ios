import UIKit
import Gridicons
import Contacts

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
            let viewModel = OrderDetailsViewModel(order: order)
            cell.configure(with: viewModel)
            return cell

        case Section.customerNote.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: OrderDetailsCustomerNoteCell.reuseIdentifier, for: indexPath) as! OrderDetailsCustomerNoteCell
            cell.configureCell(note: order.customerNote)
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
        phoneButton.contentHorizontalAlignment = .right
        phoneButton.tintColor = StyleManager.wooCommerceBrandColor
        cell.accessoryView = phoneButton
        cell.textLabel?.text = viewModel.formattedPhoneNumber
        cell.textLabel?.adjustsFontSizeToFitWidth = true

        return cell
    }

    func configureBillingEmailCell(viewModel: ContactViewModel) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "BillingEmailCell")
        cell.textLabel?.applyBodyStyle()

        let emailButton = UIButton(type: .custom)
        emailButton.frame = CGRect(x: 8, y: 0, width: 44, height: 44)
        emailButton.setImage(Gridicon.iconOfType(.mail), for: .normal)
        emailButton.contentHorizontalAlignment = .right
        emailButton.tintColor = StyleManager.wooCommerceBrandColor
        cell.accessoryView = emailButton
        cell.textLabel?.text = viewModel.email
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        return cell
    }

    func setShowHideFooter() {
        billingIsHidden = !billingIsHidden
    }
}
