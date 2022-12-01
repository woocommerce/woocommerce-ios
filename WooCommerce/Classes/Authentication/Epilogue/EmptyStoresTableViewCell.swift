import Foundation
import UIKit


/// Empty Stores: Displayed whenever there are no available WooCommerce Stores associated with the active account.
///
final class EmptyStoresTableViewCell: UITableViewCell {

    /// LegendLabel: To be displayed below the ImageView.
    ///
    @IBOutlet private var legendLabel: UILabel! {
        didSet {
            legendLabel.textColor = .text
            legendLabel.font = .title3SemiBold
            legendLabel.text = Localization.legend
        }
    }

    @IBOutlet private var subtitleLabel: UILabel! {
        didSet {
            subtitleLabel.textColor = .secondaryLabel
            subtitleLabel.font = .body
            subtitleLabel.text = Localization.subtitle
        }
    }

    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var emptyStoresImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()

        configureStackView()
        configureImageView()
    }
}


private extension EmptyStoresTableViewCell {

    func configureStackView() {
        stackView.spacing = 24
        stackView.alignment = .center
    }

    func configureImageView() {
        emptyStoresImageView.contentMode = .scaleAspectFit
        emptyStoresImageView.image = .emptyStorePickerImage
    }
}

private extension EmptyStoresTableViewCell {
    enum Localization {
        static let legend =
            NSLocalizedString("Add your first store",
                              comment: "Displayed during the Login flow, whenever the user has no woo stores associated.")
        static let subtitle = NSLocalizedString("Quickly get up and selling with a beautiful online store.",
                                                comment: "Subtitle displayed during the Login flow, whenever the user has no woo stores associated.")
    }
}
