import UIKit

class ValueOneTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()

        textLabel?.applyBodyStyle()
        detailTextLabel?.applySubheadlineStyle()
    }
}
