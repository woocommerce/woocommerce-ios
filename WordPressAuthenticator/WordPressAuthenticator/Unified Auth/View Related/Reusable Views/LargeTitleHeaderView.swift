import UIKit


/// LargeTitleHeaderView: Header view for the entire table. Not a section header.
///
final class LargeTitleHeaderView: UIView {
    @IBOutlet private weak var titleLabel: UILabel?

    public func setTitle(_ titleText: String?, with font: UIFont? = nil) {
        titleLabel?.text = titleText

        if let font = font {
            titleLabel?.font = font
        }
    }
}
