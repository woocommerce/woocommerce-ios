import Foundation
import UIKit
import SafariServices


// MARK: - TableFooterView
//
final class TableFooterView: UIView {

    @IBOutlet private var icon: UIImageView!
    @IBOutlet public var footnote: UITextView!
    @IBOutlet private var iconHeight: NSLayoutConstraint!
    @IBOutlet private var iconWidth: NSLayoutConstraint!

    static let reuseIdentifier = "TableFooterView"

    override func awakeFromNib() {
        super.awakeFromNib()

        setupFootnoteLabel()
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
    func setupFootnoteLabel() {
        footnote.attributedText = hiringAttributedText
        footnote.adjustsFontForContentSizeCategory = true
        footnote.textContainerInset = .zero
        footnote.textAlignment = .center
        footnote.linkTextAttributes = [
            .foregroundColor: StyleManager.wooCommerceBrandColor,
            .underlineColor: StyleManager.wooCommerceBrandColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
    }
}


// MARK - Private methods
//
private extension TableFooterView {

    /// Returns the Settings Footer Attributed Text
    /// (which contains a link to the "Work with us" URL)
    ///
    var hiringAttributedText: NSAttributedString {
        let hiringText = NSLocalizedString("Made with love by Automattic. <a href=\"https://automattic.com/work-with-us/\">We’re hiring!</a>",
                                               comment: "Made with love tagline and we're hiring promotional blurb. It reads: 'Made with love by Automattic. We’re hiring!' and it links to a web page on the words 'We’re hiring!'. Place the phrase, \'We’re hiring!' between the opening `<a` tag and the closing `</a>` tags. If a literal translation of 'We’re hiring!' does not make sense in your language, please use a contextually appropriate substitution. For example, you can translate it to say 'See: we are hiring page' or any alternative that sounds natural in your language."
        )
        let hiringAttributes: [NSAttributedString.Key: Any] = [
            .font: StyleManager.footerLabelFont,
            .foregroundColor: StyleManager.wooGreyMid
        ]

        let hiringAttrText = NSMutableAttributedString()
        hiringAttrText.append(hiringText.htmlToAttributedString)
        let range = NSRange(location: 0, length: hiringAttrText.length)
        hiringAttrText.addAttributes(hiringAttributes, range: range)

        return hiringAttrText
    }
}
