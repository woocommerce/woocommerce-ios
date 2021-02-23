import UIKit

class ImageTableViewCell: UITableViewCell {
    @IBOutlet weak var detailImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureCell()
    }

    func configureCell() {
        applyDefaultBackgroundStyle()
        setNeedsLayout()
    }
}
