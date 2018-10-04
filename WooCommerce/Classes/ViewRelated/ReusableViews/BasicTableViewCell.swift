import UIKit

class BasicTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()

        textLabel?.applyBodyStyle()
    }

    func configure(text: String?) {
        textLabel?.text = text
    }
}
