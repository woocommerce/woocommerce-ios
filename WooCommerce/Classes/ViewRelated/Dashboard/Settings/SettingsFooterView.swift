import UIKit
import Gridicons

class SettingsFooterView: UIView {

    @IBOutlet var icon: UIImageView!
    @IBOutlet var footnote: UILabel!

    static let reuseIdentifier = "SettingsFooterView"

    override func awakeFromNib() {
        super.awakeFromNib()
        self.icon.image = Gridicon.iconOfType(.heartOutline)
        self.icon.tintColor = StyleManager.wooGreyMid
        self.footnote.text = NSLocalizedString("Made with love by Automattic", comment: "Tagline after the heart icon, displayed to the user")
        self.footnote.applyFootnoteStyle()
        self.footnote.textColor = StyleManager.wooGreyMid
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    class func makeFromNib() -> SettingsFooterView {
        return Bundle.main.loadNibNamed("SettingsFooterView", owner: self, options: nil)?.first as! SettingsFooterView
    }
}
