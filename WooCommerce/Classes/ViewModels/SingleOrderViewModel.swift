import UIKit
import Contacts
import Gridicons
import PhoneNumberKit

class SingleOrderViewModel {
    let order: Order
    var title: String
    var summarySection = 0
    var fulfillItemsSection = 1
    var customerNoteSection = 2
    var customerInfoSection = 3
    var paymentSection = 4
    var orderNotesSection = 5

    init(withOrder order: Order) {
        self.order = order
        self.title = NSLocalizedString("Order #\(order.number)", comment:"Order number title")

        if customerNoteIsEmpty() {
            customerNoteSection = -1
            customerInfoSection -= 1
            paymentSection -= 1
            orderNotesSection -= 1
        }
    }

    func getSectionTitles() -> [String] {
        let summaryTitle = ""
        let itemsTitle = ""
        let customerNoteTitle = NSLocalizedString("CUSTOMER PROVIDED NOTE", comment: "Customer note section title")
        let customerInfoTitle = NSLocalizedString("CUSTOMER INFORMATION", comment: "Customer info section title")
        let paymentTitle = NSLocalizedString("PAYMENT", comment: "Payment section title")
        let orderNotesTitle = NSLocalizedString("ORDER NOTES", comment: "Order notes section title")

        var titles = [
            summaryTitle,
            itemsTitle,
            customerNoteTitle,
            customerInfoTitle,
            paymentTitle,
            orderNotesTitle
        ]

        if customerNoteIsEmpty() {
            titles.remove(at: 2)
        }

        return titles
    }

    func rowCount(for section: Int) -> Int {
        if section == summarySection
        || section == fulfillItemsSection
        || section == customerNoteSection
        || section == paymentSection {
            return 1
        }

        if section == customerInfoSection {
            let shippingRow = 1
            let billingAddressRow = 1
            let billingPhoneRow =  order.billingAddress.phone?.isEmpty == false ? 1 : 0
            let billingEmailRow = order.billingAddress.email?.isEmpty == false ? 1 : 0
            return shippingRow + billingAddressRow + billingPhoneRow + billingEmailRow
        }

        if section == orderNotesSection {
            let titleRow = 1
            let addNoteRow = 1
            let totalNotes = 0

            return titleRow + addNoteRow + totalNotes
        }

        return 0
    }

    func cellForSummarySection(indexPath: IndexPath, tableView: UITableView) -> SingleOrderSummaryCell {
        let cell: SingleOrderSummaryCell = tableView.dequeueReusableCell(withIdentifier: SingleOrderSummaryCell.reuseIdentifier, for: indexPath) as! SingleOrderSummaryCell
        cell.configureCell(order: order)
        return cell
    }

    func cellForCustomerNoteSection(indexPath: IndexPath, tableView: UITableView) -> SingleOrderCustomerNoteCell {
        let cell: SingleOrderCustomerNoteCell = tableView.dequeueReusableCell(withIdentifier: SingleOrderCustomerNoteCell.reuseIdentifier, for: indexPath) as! SingleOrderCustomerNoteCell
        cell.configureCell(note: order.customerNote)
        return cell
    }

    func cellForCustomerInfoSection(indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        let shippingRow = 0
        let billingRow = 1
        var billingPhoneRow = -1
        var billingEmailRow = -2

        if order.billingAddress.phone?.isEmpty == false {
            billingPhoneRow = 2
        }

        if order.billingAddress.email?.isEmpty == false {
            billingEmailRow = 3
        }

        if indexPath.row == shippingRow {
            let cell = tableView.dequeueReusableCell(withIdentifier: SingleOrderCustomerInfoCell.reuseIdentifier, for: indexPath) as! SingleOrderCustomerInfoCell
            let title = NSLocalizedString("Shipping details", comment: "Shipping title for customer info cell")
            let contact: CNContact = order.shippingAddress.createContact()
            let fullName = CNContactFormatter.string(from: contact, style: .fullName)
            let address = CNPostalAddressFormatter.string(from: contact.postalAddresses[0].value, style: .mailingAddress)
            cell.configureCell(title: title, name: fullName, address: address)
            cell.separatorInset = UIEdgeInsets.zero
            return cell
        }

        if indexPath.row == billingRow {
            let cell = tableView.dequeueReusableCell(withIdentifier: SingleOrderCustomerInfoCell.reuseIdentifier, for: indexPath) as! SingleOrderCustomerInfoCell
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
                    cell.textLabel?.applyBodyStyle()
                    cell.textLabel?.adjustsFontSizeToFitWidth = true
                } catch {
                    NSLog("error parsing sanitized billing phone number: %@", strippedPhoneNumber)
                }
            }
            return cell
        }

        if indexPath.row == billingEmailRow {
            let contact: CNContact = order.billingAddress.createContact()
            let cell = UITableViewCell(style: .default, reuseIdentifier: "BillingPhoneCell")
            let emailButton = UIButton(type: .custom)
            emailButton.frame = CGRect(x: 8, y: 0, width: 44, height: 44)
            emailButton.setImage(Gridicon.iconOfType(.mail), for: .normal)
            emailButton.contentHorizontalAlignment = .right
            emailButton.tintColor = StyleManager.wooCommerceBrandColor
            cell.accessoryView = emailButton
            if let email = contact.emailAddresses.first?.value {
                cell.textLabel?.text = email as String
                cell.textLabel?.applyBodyStyle()
                cell.textLabel?.adjustsFontSizeToFitWidth = true
            }
            cell.separatorInset = UIEdgeInsets.zero
            return cell
        }

        return UITableViewCell()
    }

    private func customerNoteIsEmpty() -> Bool {
        if let customerNote = order.customerNote {
            return customerNote.isEmpty
        }
        return true
    }

    private func configureSections() {

    }
}
