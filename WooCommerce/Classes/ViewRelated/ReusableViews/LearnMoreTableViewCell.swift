import UIKit

/// A table view cell with linkable text prompting users to learn more
///
class LearnMoreTableViewCell: UITableViewCell {
    @IBOutlet private weak var learnMoreButton: UIButton!
    @IBOutlet private weak var learnMoreTextView: UITextView!

    private var onUrlPressed: ((_ url: URL) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        configureCell()
    }

    private func configureCell() {
        learnMoreButton.setImage(.infoOutlineImage, for: .normal)
        learnMoreTextView.tintColor = .textLink
        learnMoreTextView.linkTextAttributes = [
            .foregroundColor: UIColor.textLink,
            .underlineColor: UIColor.clear
        ]
        learnMoreTextView.delegate = self
    }

    func configure(text: NSAttributedString?, onUrlPressed: ((_ url: URL) -> Void)? = nil ) {
        learnMoreTextView.attributedText = text
        self.onUrlPressed = onUrlPressed
    }
}

extension LearnMoreTableViewCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL,
                  in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        self.onUrlPressed?(URL)
        return false
    }
}
