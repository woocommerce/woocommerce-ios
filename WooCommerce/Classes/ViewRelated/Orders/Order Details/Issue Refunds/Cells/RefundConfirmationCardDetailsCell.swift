import Foundation
import UIKit

class RefundConfirmationCardDetailsCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var cardDescriptionLabel: UILabel!
    @IBOutlet weak var cardBrandImageView: UIImageView!
    var cardBrandImageAspectRatioConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()

        applyDefaultBackgroundStyle()
        titleLabel.applyHeadlineStyle()
        cardDescriptionLabel.applyBodyStyle()
    }

    func update(title: String,
                cardDescription: String,
                cardIcon: UIImage?,
                iconAspectHorizontal: CGFloat,
                accessibilityDescription: NSAttributedString) {
        titleLabel.text = title
        cardDescriptionLabel.text = cardDescription
        cardBrandImageView.image = cardIcon
        updateCardBrandImageViewRatio(horizontalAspect: iconAspectHorizontal)
        cardBrandImageView.isHidden = cardIcon == nil
        isAccessibilityElement = true
        accessibilityAttributedLabel = accessibilityDescription
    }

    private func updateCardBrandImageViewRatio(horizontalAspect: CGFloat) {
        cardBrandImageAspectRatioConstraint = NSLayoutConstraint(
            item: cardBrandImageView as Any,
            attribute: .width,
            relatedBy: .equal,
            toItem: cardBrandImageView,
            attribute: .height,
            multiplier: horizontalAspect,
            constant: 0)
        NSLayoutConstraint.activate([cardBrandImageAspectRatioConstraint])
    }
}
