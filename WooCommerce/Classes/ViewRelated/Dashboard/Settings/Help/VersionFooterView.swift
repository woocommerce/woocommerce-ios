import UIKit


// MARK: - VersionFooterView
//
class VersionFooterView: UIView {
    @IBOutlet var footerLabel: UILabel!

    static let reuseIdentifier = "VersionFooterView"

    override func awakeFromNib() {
        super.awakeFromNib()
        
        footerLabel.applyFootnoteStyle()
        footerLabel.textColor = StyleManager.sectionTitleColor
        footerLabel.isAccessibilityElement = true

        backgroundColor = StyleManager.sectionBackgroundColor
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    /// Convenience method
    ///
    class func makeFromNib() -> VersionFooterView {
        return Bundle.main.loadNibNamed("VersionFooterView", owner: self, options: nil)?.first as! VersionFooterView
    }
}
