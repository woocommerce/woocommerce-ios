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

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        configureTextLabel()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        imageView?.frame.size = CGSize(width: Constants.iconW, height: Constants.iconH)
        imageView?.frame.origin.y = Constants.iconY
    }

    /// Applies the style for the cell.
    func apply(style: Style) {
         switch style {
         case .footnote:
            textLabel?.applyFootnoteStyle()
         case .body:
            textLabel?.applyBodyStyle()
         }
     }
}


private extension TopLeftImageTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func configureTextLabel() {
        apply(style: .default)
        textLabel?.numberOfLines = 0
    }
}

extension TopLeftImageTableViewCell {
    struct Constants {
        static let iconW = CGFloat(24)
        static let iconH = CGFloat(24)
        static let iconY = CGFloat(11)
    }
}
