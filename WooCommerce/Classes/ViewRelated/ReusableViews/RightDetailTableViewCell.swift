import UIKit

class RightDetailTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()

        textLabel?.applyBodyStyle()
        detailTextLabel?.applyBodyStyle()
        detailTextLabel?.textColor = StyleManager.wooGreyMid
    }
}
