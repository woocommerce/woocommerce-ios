import UIKit

/// Vertically aligns the image to the top of the cell instead of basic cell's center alignment.
///
class TopLeftImageTableViewCell: UITableViewCell {
    /// The style of the cell, particularly the font size.
    enum Style {
        /// Uses the body font size. This is the default.
        case body
        /// Uses the footnote font size.
        case footnote

        fileprivate static let `default` = Self.body
    }

    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var customImageView: UIImageView!
    @IBOutlet private weak var label: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        configureStackView()
        configureImageView()
        configureTextLabel()
    }

    /// Configures the image and text with optional color for customization.
    func configure(image: UIImage?,
                   imageTintColor: UIColor? = nil,
                   text: String?,
                   textColor: UIColor? = nil) {
        customImageView.image = image
        if let imageTintColor = imageTintColor {
            customImageView.tintColor = imageTintColor
        }
        label.text = text
        if let textColor = textColor {
            label.textColor = textColor
        }
    }

    /// Applies the style for the cell.
    func apply(style: Style) {
         switch style {
         case .footnote:
            label.applyFootnoteStyle()
         case .body:
            label.applyBodyStyle()
         }
     }
}


private extension TopLeftImageTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func configureStackView() {
        stackView.spacing = Constants.stackViewSpacing
        stackView.alignment = .top
    }

    func configureImageView() {
        customImageView.setContentHuggingPriority(.required, for: .horizontal)
        customImageView.setContentHuggingPriority(.required, for: .vertical)
        customImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        customImageView.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    func configureTextLabel() {
        apply(style: .default)
        label.numberOfLines = 0
    }
}

private extension TopLeftImageTableViewCell {
    enum Constants {
        static let stackViewSpacing = CGFloat(16)
    }
}
