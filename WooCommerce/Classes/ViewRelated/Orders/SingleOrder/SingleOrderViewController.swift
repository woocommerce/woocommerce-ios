import UIKit

class SingleOrderViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    var order: Order!
    var orderNotes: [OrderNote]?
    var sectionTitles = [String]()
    let summarySection = 0
    let fulfillItemsSection = 1
    let customerNoteSection = 2
    let customerInfoSection = 3
    let paymentSection = 4
    let orderNotesSection = 5

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
        sectionTitles = Order.orderDetailSectionTitles()
        if let customerNote = order.customerNote {
            if customerNote.isEmpty {
                sectionTitles[customerNoteSection] = ""
            }
        }
    }

    func configureNibs() {
        let summaryNib = UINib(nibName: SingleOrderSummaryCell.reuseIdentifier, bundle: nil)
        tableView.register(summaryNib, forCellReuseIdentifier: SingleOrderSummaryCell.reuseIdentifier)
        let noteNib = UINib(nibName: SingleOrderCustomerNoteCell.reuseIdentifier, bundle: nil)
        tableView.register(noteNib, forCellReuseIdentifier: SingleOrderCustomerNoteCell.reuseIdentifier)
    }
}

extension SingleOrderViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitles.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == summarySection ||
            section == fulfillItemsSection ||
            section == paymentSection {
            return 1
        }

        if section == customerNoteSection {
            if let customerNote = order.customerNote {
                if customerNote.isEmpty == false {
                    return 1
                } else {
                    return 0
                }
            } else {
                return 0
            }
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
            var totalNotes = 0
            if let notes = orderNotes {
                totalNotes = notes.count
            }
            return titleRow + addNoteRow + totalNotes
        }

        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == summarySection {
            let cell: SingleOrderSummaryCell = tableView.dequeueReusableCell(withIdentifier: SingleOrderSummaryCell.reuseIdentifier, for: indexPath) as! SingleOrderSummaryCell
            cell.configureCell(order: order)
            return cell
        }

        if indexPath.section == customerNoteSection {
            let cell: SingleOrderCustomerNoteCell = tableView.dequeueReusableCell(withIdentifier: SingleOrderCustomerNoteCell.reuseIdentifier, for: indexPath) as! SingleOrderCustomerNoteCell
            cell.configureCell(note: order.customerNote)
            return cell
        }

        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if sectionTitles[section].isEmpty {
            return nil
        }
        return sectionTitles[section]
    }
}

extension SingleOrderViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
