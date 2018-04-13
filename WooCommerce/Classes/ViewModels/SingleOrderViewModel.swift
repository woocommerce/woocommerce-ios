import UIKit

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
            let billingRow = 1
            let showHideButtonRow = 1
            return shippingRow + billingRow + showHideButtonRow
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

    func cellForCustomerInfoSection(indexPath: IndexPath, tableView: UITableView) -> SingleOrderCustomerInfoCell {
        let shippingRow = 0
        let billingRow = 1
        var billingPhoneRow = -1
        var billingEmailRow = -2
        let showHideRow = 2
        let cell: SingleOrderCustomerInfoCell = tableView.dequeueReusableCell(withIdentifier: SingleOrderCustomerInfoCell.reuseIdentifier, for: indexPath) as! SingleOrderCustomerInfoCell

        if order.billingAddress.phone != nil {
            billingPhoneRow = 2
            billingEmailRow = 3
            
        }

        if indexPath.row == shippingRow {
            let title = NSLocalizedString("Shipping details", comment: "Shipping title for customer info")
            let name = "\(order.shippingAddress.firstName) \(order.shippingAddress.lastName)"
            let address = "\(order.shippingAddress.address1) \n\(order.shippingAddress.city), \(order.shippingAddress.state) \(order.shippingAddress.postcode) \n\(order.shippingAddress.country)"
            cell.configureCell(title: title, name: name, address: address, phone: nil, email: nil, displayExtraBorders: false)
        }

        if indexPath.row == billingRow {
            // configure billing
        }

        if indexPath.row == showHideRow {
            // configure show/hide button row
        }

        return cell
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
