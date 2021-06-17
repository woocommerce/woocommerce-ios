import UIKit

/// A table view cell with linkable text prompting users to learn more
class LearnMoreTableViewCell: UITableViewCell {
    @IBOutlet private weak var learnMoreButton: UIButton!
    @IBOutlet weak var learnMoreTextView: UITextView!

    override func awakeFromNib() {
        super.awakeFromNib()
        learnMoreButton.setImage(.infoOutlineImage, for: .normal)
    }
}
