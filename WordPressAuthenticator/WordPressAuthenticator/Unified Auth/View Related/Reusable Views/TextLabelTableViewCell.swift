import UIKit


/// TextLabelTableViewCell: a text label in a UITableViewCell.
///
public final class TextLabelTableViewCell: UITableViewCell {

    /// Private properties
    ///
    @IBOutlet private weak var label: UILabel!

    /// Public properties
    ///
    public static let reuseIdentifier = "TextLabelTableViewCell"

    public func configureLabel(text: String?, style: TextLabelStyle = .body) {
        label.text = text

        switch style {
        case .body:
            label.textColor = WordPressAuthenticator.shared.unifiedStyle?.textColor ?? WordPressAuthenticator.shared.style.instructionColor
            label.font = UIFont.preferredFont(forTextStyle: .body)
        }
    }
}

public extension TextLabelTableViewCell {
    /// The label style to display
    ///
    enum TextLabelStyle {
        case body
    }
}
