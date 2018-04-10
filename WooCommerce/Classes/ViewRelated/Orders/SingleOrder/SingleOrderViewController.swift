import UIKit

class SingleOrderViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    var order: Order!
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
        let nib = UINib(nibName: SingleOrderSummaryCell.reuseIdentifier, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: SingleOrderSummaryCell.reuseIdentifier)
    }

    func configureSections() {
        sectionTitles = Order.orderDetailSectionTitles()
        if let customerNote = order.customerNote {
            if customerNote.isEmpty {
                sectionTitles[customerNoteSection] = ""
            }
        }
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
            if let orderNotes = order.notes {
                if orderNotes.isEmpty == false {
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
            if let notes = order.notes {
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
        } else  {
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

extension SingleOrderViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
