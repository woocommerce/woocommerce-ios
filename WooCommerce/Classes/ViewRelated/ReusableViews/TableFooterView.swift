import Foundation
import UIKit


// MARK: - TableFooterView
//
@MainActor
final class TableFooterView: UIView {

    @IBOutlet var icon: UIImageView!
    @IBOutlet var footnote: UITextView!
    @IBOutlet private var iconHeight: NSLayoutConstraint!
    @IBOutlet private var iconWidth: NSLayoutConstraint!

    static let reuseIdentifier = "TableFooterView"

    override func awakeFromNib() {
        super.awakeFromNib()
        // UIKit loads view nibs on the main actor; NSObject's callback is nonisolated.
        MainActor.assumeIsolated { setupFootnoteTextView() }
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

    /// Initialization method for footnote textview
    ///
    func setupFootnoteTextView() {
        footnote.adjustsFontForContentSizeCategory = true
        footnote.textContainerInset = .zero
        footnote.textAlignment = .center
        footnote.linkTextAttributes = [
            .foregroundColor: UIColor.textLink,
            .underlineColor: UIColor.clear,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
    }
}
