import UIKit

/// A table view cell with linkable text prompting users to learn more
///
class LearnMoreTableViewCell: UITableViewCell {
    @IBOutlet private weak var learnMoreButton: UIButton!
    @IBOutlet private weak var learnMoreLabel: UILabel!

    private var onUrlPressed: ((_ url: URL) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        configureCell()
    }

    private func configureCell() {
        learnMoreButton.setImage(.infoOutlineImage, for: .normal)
        learnMoreLabel.textColor = .textLink
    }

    func configure(text: String?) {
        learnMoreLabel.text = text
    }
}
