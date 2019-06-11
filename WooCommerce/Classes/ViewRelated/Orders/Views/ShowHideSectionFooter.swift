import UIKit
import Gridicons

// MARK: - ShowHideFooterCell
//
class ShowHideSectionFooter: UITableViewHeaderFooterView {
    @IBOutlet private weak var footerLabel: UILabel!
    @IBOutlet private weak var footerArrow: UIImageView!
    @IBOutlet private weak var footerButton: UIButton!
    var didSelectFooter: (() -> Void)?

    @IBAction func footerButtonTapped(sender: UIButton) {
        didSelectFooter?()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        styleLabel()
        styleArrow()
    }

    private func styleLabel() {
        footerLabel.applyFootnoteStyle()
        footerLabel.textColor = StyleManager.sectionTitleColor
    }

    private func styleArrow() {
        footerArrow.tintColor = StyleManager.wooCommerceBrandColor
    }

    func configure(text: String, image: UIImage) {
        footerLabel.text = text
        footerLabel.isAccessibilityElement = false

        footerButton.isAccessibilityElement = true
        footerButton.accessibilityTraits = .button
        footerButton.accessibilityLabel = text

        footerArrow.image = image
        footerArrow.isAccessibilityElement = false
    }
}
