import UIKit
import Gridicons

// MARK: - ShowHideFooterCell
//
class ShowHideFooterCell: UITableViewHeaderFooterView {
    @IBOutlet private weak var footerLabel: UILabel!
    @IBOutlet private weak var footerArrow: UIImageView!
    @IBOutlet private weak var footerButton: UIButton!
    var didSelectFooter: (() -> Void)?

    @IBAction func footerButtonTapped(sender: UIButton) {
        didSelectFooter?()
    }

    static let reuseIdentifier = "ShowHideFooterCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        footerLabel.applyFootnoteStyle()
        footerLabel.textColor = StyleManager.sectionTitleColor
        footerArrow.tintColor = StyleManager.wooCommerceBrandColor
    }

    func configureCell(isHidden: Bool) {
        if isHidden {
            footerLabel.text = NSLocalizedString("Show billing", comment: "Footer text to show the billing cell")
            footerArrow.image = Gridicon.iconOfType(.chevronDown)
        } else {
            footerLabel.text = NSLocalizedString("Hide billing", comment: "Footer text to hide the billing cell")
            footerArrow.image = Gridicon.iconOfType(.chevronUp)
        }
    }
}
