import Foundation
import UIKit

class RefundConfirmationCardDetailsCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var cardDescriptionLabel: UILabel!
    @IBOutlet weak var cardBrandImageView: UIImageView!
    var cardBrandImageAspectRatioConstraint: NSLayoutConstraint?

    override func awakeFromNib() {
        super.awakeFromNib()

        configureDefaultBackgroundConfiguration()
        titleLabel.applyHeadlineStyle()
        cardDescriptionLabel.applyBodyStyle()
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        updateDefaultBackgroundConfiguration(using: state)
    }

    func update(title: String,
                cardDescription: String,
                cardIcon: UIImage?,
                accessibilityDescription: NSAttributedString) {
        titleLabel.text = title
        cardDescriptionLabel.text = cardDescription
        cardBrandImageView.image = cardIcon
        updateCardBrandImageViewRatio(for: cardIcon)
        cardBrandImageView.isHidden = cardIcon == nil
        isAccessibilityElement = true
        accessibilityAttributedLabel = accessibilityDescription
    }

    private func updateCardBrandImageViewRatio(for image: UIImage?) {
        cardBrandImageAspectRatioConstraint?.isActive = false
        guard let image, image.size.height > 0 else {
            return
        }

        let aspectRatioConstraint = NSLayoutConstraint(
            item: cardBrandImageView as Any,
            attribute: .width,
            relatedBy: .equal,
            toItem: cardBrandImageView,
            attribute: .height,
            multiplier: image.size.width / image.size.height,
            constant: 0)
        aspectRatioConstraint.isActive = true
        cardBrandImageAspectRatioConstraint = aspectRatioConstraint
    }
}
