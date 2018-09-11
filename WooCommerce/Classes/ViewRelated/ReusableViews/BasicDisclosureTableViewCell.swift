import UIKit

class BasicDisclosureTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()

        textLabel?.applyBodyStyle()
    }

    func configure(text: String?) {
        textLabel?.text = text
    }
}
