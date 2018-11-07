import UIKit

class ValueOneTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()

        textLabel?.applyBodyStyle()
        detailTextLabel?.applySubheadlineStyle()
        detailTextLabel?.lineBreakMode = .byWordWrapping
        detailTextLabel?.numberOfLines = 0
    }
}
