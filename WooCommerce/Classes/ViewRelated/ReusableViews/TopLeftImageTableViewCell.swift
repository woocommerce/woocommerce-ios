import UIKit

/// Vertically aligns the image to the top of the cell instead of basic cell's center alignment.

///
class TopLeftImageTableViewCell: UITableViewCell {

    @IBOutlet public var leftImageView: UIImageView! {
        didSet {
            let leftInset = leftImageView.frame.origin.x + leftImageView.frame.width + leadingLabelConstraint.constant
            separatorInset = UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: 0)
        }
    }
    @IBOutlet public var label: UILabel!
    @IBOutlet private var leadingLabelConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()

        label?.applyBodyStyle()
    }
}
