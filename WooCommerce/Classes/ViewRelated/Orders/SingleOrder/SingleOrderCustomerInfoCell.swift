import UIKit

class SingleOrderCustomerInfoCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var emailButton: UIButton!
    @IBOutlet weak var borderLine: UIView!
    @IBOutlet weak var borderLine2: UIView!

    static let reuseIdentifier = "SingleOrderCustomerInfoCell"

    func configureCell(address: Address) {
        // uh oh. How do I know which address is being passed here?
    }
}
