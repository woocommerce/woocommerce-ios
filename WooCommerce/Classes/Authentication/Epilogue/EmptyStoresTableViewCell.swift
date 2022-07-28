import Foundation
import UIKit


/// Empty Stores: Displayed whenever there are no available WooCommerce Stores associated with the active account.
///
final class EmptyStoresTableViewCell: UITableViewCell {

    var onJetpackSetupButtonTapped: (() -> Void)?

    var onCloseAccountButtonTapped: (() -> Void)?

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
    @IBOutlet private weak var removeAppleIDAccessButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        configureStackView()
        configureImageView()
        configureActionButton()
        configureRemoveAppleIDAccessButton()
        updateRemoveAppleIDAccessButtonVisibility(isVisible: false)
    }

    func updateRemoveAppleIDAccessButtonVisibility(isVisible: Bool) {
        removeAppleIDAccessButton.isHidden = !isVisible
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

    func configureRemoveAppleIDAccessButton() {
        removeAppleIDAccessButton.applyLinkButtonStyle()
        removeAppleIDAccessButton.setTitle(Localization.closeAccountTitle, for: .normal)
        removeAppleIDAccessButton.on(.touchUpInside) { [weak self] _ in
            self?.onCloseAccountButtonTapped?()
        }
    }
}

private extension EmptyStoresTableViewCell {
    enum Localization {
        static let actionTitle = NSLocalizedString("Connect your store with Jetpack",
                                                   comment: "Link on the store picker when there are no stores available. Opens a webview about Jetpack setup.")
        static let closeAccountTitle = NSLocalizedString(
            "Close Account",
            comment: "Link on the store picker for users who signed in with Apple to close their WordPress.com account."
        )
        static let legend =
            NSLocalizedString("If you already have a store, you’ll need to install the free Jetpack plugin and connect it to your WordPress.com account.",
                              comment: "Displayed during the Login flow, whenever the user has no woo stores associated.")
    }
}
