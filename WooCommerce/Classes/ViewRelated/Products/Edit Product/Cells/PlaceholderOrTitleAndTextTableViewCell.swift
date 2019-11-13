import UIKit

/// Displays a title and text, or a placeholder.
///
/// This cell can be in one of two states:
/// 1. the text is empty, a placeholder is shown.
/// 2. the text is not empty, a title and the text are shown.
final class PlaceholderOrTitleAndTextTableViewCell: UITableViewCell {
    enum State {
        case placeholder(placeholder: String)
        case text(title: String, text: String)
    }

    @IBOutlet private weak var placeholderLabel: UILabel!
    @IBOutlet private weak var titleAndTextStackView: UIStackView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!

    private var state: State = .placeholder(placeholder: "")

    override func awakeFromNib() {
        super.awakeFromNib()
        configureLabels()
        configureTitleAndTextStackView()
        updateUI(state: state)
    }

    func update(state: State) {
        self.state = state
        updateUI(state: state)
    }
}

// MARK: Updates
//
private extension PlaceholderOrTitleAndTextTableViewCell {
    func updateUI(state: State) {
        switch state {
        case .placeholder(let placeholder):
            placeholderLabel.text = placeholder

            placeholderLabel.isHidden = false
            titleAndTextStackView.isHidden = true
        case .text(let title, let text):
            titleLabel.text = title
            descriptionLabel.text = text

            placeholderLabel.isHidden = true
            titleAndTextStackView.isHidden = false
        }
    }
}

// MARK: Configurations
//
private extension PlaceholderOrTitleAndTextTableViewCell {
    func configureLabels() {
        placeholderLabel.applyBodyStyle()
        placeholderLabel.textColor = StyleManager.wooGreyMid

        titleLabel.applySubheadlineStyle()

        descriptionLabel.applyFootnoteStyle()
        descriptionLabel.textColor = StyleManager.wooGreyMid
    }

    func configureTitleAndTextStackView() {
        titleAndTextStackView.spacing = 6
    }
}
