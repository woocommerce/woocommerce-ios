import UIKit

class SingleOrderCustomerInfoCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var phoneLabel: UILabel!
    @IBOutlet private weak var emailLabel: UILabel!
    @IBOutlet private weak var moreButton: UIButton!
    @IBOutlet private weak var emailButton: UIButton!
    @IBOutlet private weak var borderLine: UIView!
    @IBOutlet private weak var borderLine2: UIView!

    var title: String!
    var address: String!
    var phone: String? = nil
    var email: String? = nil
    var displaysExtraBorders: Bool!

    static let reuseIdentifier = "SingleOrderCustomerInfoCell"

    override func awakeFromNib() {
        
    }
}
