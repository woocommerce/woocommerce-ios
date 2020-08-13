import Foundation
import UIKit


/// Empty Stores: Displayed whenever there are no available WooCommerce Stores associated with the active account.
///
class EmptyStoresTableViewCell: UITableViewCell {

    var onJetpackSetupButtonTapped: (() -> Void)?

    /// LegendLabel: To be displayed below the ImageView.
    ///
    @IBOutlet private var legendLabel: UILabel! {
        didSet {
            legendLabel.textColor = .textSubtle
            legendLabel.font = .subheadline
            legendLabel.text = Localization.legend
        }
    }

    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var emptyStoresImageView: UIImageView!
    @IBOutlet private weak var actionButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        configureStackView()
        configureImageView()
        configureActionButton()
    }
}


private extension EmptyStoresTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func configureStackView() {
        stackView.spacing = 10
        stackView.alignment = .center
    }

    func configureImageView() {
        emptyStoresImageView.contentMode = .scaleAspectFit
    }

    func configureActionButton() {
        actionButton.applyPrimaryButtonStyle()
        actionButton.setTitle(Localization.actionTitle, for: .normal)
        actionButton.on(.touchUpInside) { [weak self] _ in
            self?.onJetpackSetupButtonTapped?()
        }
    }
}

private extension EmptyStoresTableViewCell {
    enum Localization {
        static let actionTitle = NSLocalizedString("Connect your store with Jetpack",
                                                   comment: "Link on the store picker when there are no stores available. Opens a webview about Jetpack setup.")
        static let legend = NSLocalizedString("Unable to find WooCommerce stores connected to this account",
                                              comment: "Displayed during the Login flow, whenever the user has no woo stores associated.")
    }
}
