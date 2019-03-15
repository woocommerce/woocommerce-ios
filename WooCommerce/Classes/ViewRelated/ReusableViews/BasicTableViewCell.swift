import UIKit

class BasicTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()

        textLabel?.applyBodyStyle()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        textLabel?.applyBodyStyle()
        textLabel?.textAlignment = .left
    }
}
