import Foundation
import UIKit

// MARK: - TableFooterView
//
class TableFooterView: UIView {

    @IBOutlet private var icon: UIImageView!
    @IBOutlet private var footnote: UILabel!
    @IBOutlet private var iconHeight: NSLayoutConstraint!
    @IBOutlet private var iconWidth: NSLayoutConstraint!

    static let reuseIdentifier = "TableFooterView"

    override func awakeFromNib() {
        super.awakeFromNib()

        footnote.applyFootnoteStyle()
    }

    override func layoutSubviews() {
        if iconImage == nil {
            icon.removeFromSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

// MARK: - Public methods
//
extension TableFooterView {

    /// Icon image view image.
    ///
    var iconImage: UIImage? {
        get {
            return icon?.image
        }
        set {
            icon?.image = newValue
        }
    }

    /// Icon image view tint color.
    ///
    var iconColor: UIColor? {
        get {
            return icon?.tintColor
        }
        set {
            icon?.tintColor = newValue
        }
    }

    /// Footnote label text.
    ///
    var footnoteText: String? {
        get {
            return footnote?.text
        }
        set {
            footnote?.text = newValue
        }
    }

    /// Footnote label color.
    ///
    var footnoteColor: UIColor? {
        get {
            return footnote?.textColor
        }
        set {
            footnote?.textColor = newValue
        }
    }
}
