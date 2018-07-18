import UIKit

class DetailsTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configure(text: String?) {
        textLabel?.text = text
    }
}
