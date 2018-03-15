import UIKit

class OrderListCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var totalLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var optionalLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func configureCell(order: Order) {
        let titleString = "#\(order.number) \(order.customer.firstName) \(order.customer.lastName)"
        titleLabel.text = titleString
        totalLabel.text = order.currencySymbol
    }
}
