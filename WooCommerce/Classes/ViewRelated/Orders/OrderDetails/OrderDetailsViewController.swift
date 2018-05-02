import UIKit

class OrderDetailsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    var order: Order!
    var sectionTitles = [String]()

    enum Section: Int {
        case summary = 0
        case fulfillment = 1
        case customerNote = 2
        case info = 3
        case payment = 4
        case orderNotes = 5
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
    }
}

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
            let billingRow = 1
            let showHideButtonRow = 1
            return shippingRow + billingRow + showHideButtonRow
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
                cell.configureCell(order: order)
                return cell

            case Section.customerNote.rawValue:
                let cell = tableView.dequeueReusableCell(withIdentifier: OrderDetailsCustomerNoteCell.reuseIdentifier, for: indexPath) as! OrderDetailsCustomerNoteCell
                cell.configureCell(note: order.customerNote)
                return cell

            default:
                return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if sectionTitles[section].isEmpty {
            return nil
        }
        return sectionTitles[section]
    }
}

extension OrderDetailsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
