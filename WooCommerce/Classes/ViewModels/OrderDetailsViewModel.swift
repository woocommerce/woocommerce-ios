import UIKit
import Contacts
import Gridicons
import PhoneNumberKit

class OrderDetailsViewModel {
    let order: Order
    let notes: [OrderNote]
    var title: String
    var billingIsHidden = true

    enum Section: Int {
        case summary = 0
        case fulfillment = 1
        case customerNote = 2
        case info = 3
        case payment = 4
        case orderNotes = 5
    }

    init(withOrder order: Order) {
        self.order = order
        self.notes = []
        self.title = NSLocalizedString("Order #\(order.number)", comment:"Order number title")
    }

    func getSectionTitles() -> [String] {
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
        return [orderSummary, fulfillItems, customerNoteTitle, customerInfo, paymentDetails, orderNotes]
    }

    func rowCount(for section: Int) -> Int {
        if section == Section.summary.rawValue {
            return 1
        }

        if section == Section.customerNote.rawValue {
            return order.customerNote?.isEmpty == false ? 1 : 0
        }

        if section == Section.info.rawValue {
            let shippingRow = 1
            let billingAddressRow = billingIsHidden ? 0 : 1
            let billingPhoneRow = billingIsHidden || order.billingAddress.phone?.isEmpty == true ? 0 : 1
            let billingEmailRow = billingIsHidden || order.billingAddress.email?.isEmpty == true ? 0 : 1

            return shippingRow + billingAddressRow + billingPhoneRow + billingEmailRow
        }

        return 0
    }

    func cellForSummarySection(indexPath: IndexPath, tableView: UITableView) -> OrderDetailsSummaryCell {
        let cell: OrderDetailsSummaryCell = tableView.dequeueReusableCell(withIdentifier: OrderDetailsSummaryCell.reuseIdentifier, for: indexPath) as! OrderDetailsSummaryCell
        cell.configureCell(order: order)
        return cell
    }

    func cellForCustomerNoteSection(indexPath: IndexPath, tableView: UITableView) -> OrderDetailsCustomerNoteCell {
        let cell: OrderDetailsCustomerNoteCell = tableView.dequeueReusableCell(withIdentifier: OrderDetailsCustomerNoteCell.reuseIdentifier, for: indexPath) as! OrderDetailsCustomerNoteCell
        cell.configureCell(note: order.customerNote)
        return cell
    }

    func cellForCustomerInfoSection(indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        let shippingRow = 0
        var billingRow = -1
        var billingPhoneRow = -2
        var billingEmailRow = -3

        if billingIsHidden == false {
            billingRow = 1

            if order.billingAddress.phone?.isEmpty == false {
                billingPhoneRow = 2
            }

            if order.billingAddress.email?.isEmpty == false {
                billingEmailRow = 3
            }
        }

        if indexPath.row == shippingRow {
            let cell = tableView.dequeueReusableCell(withIdentifier: OrderDetailsCustomerInfoCell.reuseIdentifier, for: indexPath) as! OrderDetailsCustomerInfoCell
            let title = NSLocalizedString("Shipping details", comment: "Shipping title for customer info cell")
            let contact: CNContact = order.shippingAddress.createContact()
            let fullName = CNContactFormatter.string(from: contact, style: .fullName)
            let address = CNPostalAddressFormatter.string(from: contact.postalAddresses[0].value, style: .mailingAddress)
            cell.configureCell(title: title, name: fullName, address: address)
            cell.separatorInset = UIEdgeInsets.zero
            return cell
        }

        if indexPath.row == billingRow {
            let cell = tableView.dequeueReusableCell(withIdentifier: OrderDetailsCustomerInfoCell.reuseIdentifier, for: indexPath) as! OrderDetailsCustomerInfoCell
            let title = NSLocalizedString("Billing details", comment: "Billing details for customer info cell")
            let contact: CNContact = order.billingAddress.createContact()
            let fullName = CNContactFormatter.string(from: contact, style: .fullName)
            let address = CNPostalAddressFormatter.string(from: contact.postalAddresses[0].value, style: .mailingAddress)
            cell.configureCell(title: title, name: fullName, address: address)
            return cell
        }

        if indexPath.row == billingPhoneRow {
            let contact: CNContact = order.billingAddress.createContact()
            let cell = UITableViewCell(style: .default, reuseIdentifier: "BillingPhoneCell")
            cell.textLabel?.applyBodyStyle()

            let phoneButton = UIButton(type: .custom)
            phoneButton.frame = CGRect(x: 8, y: 0, width: 44, height: 44)
            phoneButton.setImage(Gridicon.iconOfType(.ellipsis), for: .normal)
            phoneButton.contentHorizontalAlignment = .right
            phoneButton.tintColor = StyleManager.wooCommerceBrandColor
            cell.accessoryView = phoneButton

            if let phoneData = contact.phoneNumbers.first?.value {
                let phoneStringArray = phoneData.stringValue.components(separatedBy: NSCharacterSet.decimalDigits.inverted)
                let strippedPhoneNumber = NSArray(array: phoneStringArray).componentsJoined(by: "")
                let phoneNumberKit = PhoneNumberKit()
                let iOS639LanguageCode = NSLocale.current.identifier
                var regionShortCode = ""
                if iOS639LanguageCode.count > 3 { // e.g. "en-GB"
                    let range = iOS639LanguageCode.index(iOS639LanguageCode.startIndex, offsetBy: 3)..<iOS639LanguageCode.endIndex
                    regionShortCode = String(iOS639LanguageCode[range])
                }
                do {
                    let phoneNumber = try phoneNumberKit.parse(strippedPhoneNumber, withRegion: regionShortCode, ignoreType: true)
                    let formattedPhoneNumber = phoneNumberKit.format(phoneNumber, toType: .national)
                    cell.textLabel?.text = formattedPhoneNumber
                    cell.textLabel?.adjustsFontSizeToFitWidth = true
                } catch {
                    NSLog("error parsing sanitized billing phone number: %@", strippedPhoneNumber)
                }
            }
            return cell
        }

        if indexPath.row == billingEmailRow {
            let contact: CNContact = order.billingAddress.createContact()
            let cell = UITableViewCell(style: .default, reuseIdentifier: "BillingEmailCell")
            cell.textLabel?.applyBodyStyle()

            let emailButton = UIButton(type: .custom)
            emailButton.frame = CGRect(x: 8, y: 0, width: 44, height: 44)
            emailButton.setImage(Gridicon.iconOfType(.mail), for: .normal)
            emailButton.contentHorizontalAlignment = .right
            emailButton.tintColor = StyleManager.wooCommerceBrandColor
            cell.accessoryView = emailButton
            if let email = contact.emailAddresses.first?.value {
                cell.textLabel?.text = email as String
                cell.textLabel?.adjustsFontSizeToFitWidth = true
            }
            return cell
        }

        fatalError()
    }

    func cellForShowHideFooter(tableView: UITableView, section: Int) -> UIView {
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

    func setShowHideFooter() {
        billingIsHidden = !billingIsHidden
    }
}
