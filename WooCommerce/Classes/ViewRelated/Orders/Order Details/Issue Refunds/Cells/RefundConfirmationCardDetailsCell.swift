import Foundation
import UIKit

class RefundConfirmationCardDetailsCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var cardDescriptionLabel: UILabel!
    @IBOutlet weak var cardBrandImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()

        applyDefaultBackgroundStyle()
        titleLabel.applyHeadlineStyle()
        cardDescriptionLabel.applyBodyStyle()
    }

    func update(title: String, cardDescription: String, cardIcon: UIImage?, accessibilityDescription: NSAttributedString) {
        titleLabel.text = title
        cardDescriptionLabel.text = cardDescription
        cardBrandImageView.image = cardIcon
        cardBrandImageView.isHidden = cardIcon == nil
        isAccessibilityElement = true
        accessibilityAttributedLabel = accessibilityDescription
    }
}
