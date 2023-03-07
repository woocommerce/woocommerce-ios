import Foundation
import UIKit



/// AccountHeaderView: Displays an Account's Details: [Gravatar + Email]
///
final class AccountHeaderView: UIView {

    /// Account's Gravatar.
    ///
    @IBOutlet private var gravatarImageView: UIImageView! {
        didSet {
            gravatarImageView.image = .gravatarPlaceholderImage
        }
    }

    /// Account's email.
    ///
    @IBOutlet private var emailLabel: UILabel! {
        didSet {
            emailLabel.textColor = .systemColor(.secondaryLabel)
            emailLabel.font = .body
            emailLabel.accessibilityIdentifier = "email-label"
        }
    }

    /// Action Button
    ///
    @IBOutlet private weak var actionButton: UIButton!

    @IBOutlet private var containerView: UIView!

    /// Closure to be executed whenever the action button is pressed
    ///
    var onActionButtonTapped: ((UIView) -> Void)?

    // MARK: - Overridden Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        setupHelpButton()
        configureContainerView()
    }
}


// MARK: - Public Methods
//
extension AccountHeaderView {

    /// Account's Full Name
    ///
    var email: String? {
        set {
            emailLabel.text = newValue
        }
        get {
            return emailLabel.text
        }
    }

    var isActionButtonEnabled: Bool {
        set {
            actionButton.isHidden = !newValue
            actionButton.isEnabled = newValue
        }
        get {
            return actionButton.isHidden
        }
    }

    /// Downloads (and displays) the Gravatar associated with the specified Email.
    ///
    func downloadGravatar(with email: String) {
        gravatarImageView.downloadGravatarWithEmail(email)
    }
}


// MARK: - Private Methods
//
private extension AccountHeaderView {

    func configureContainerView() {
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.border.cgColor
        containerView.layer.cornerRadius = 8
    }

    func setupHelpButton() {
        actionButton.setImage(.ellipsisImage, for: .normal)
        actionButton.tintColor = .accent
        actionButton.setTitle(nil, for: .normal)
        actionButton.on(.touchUpInside) { [weak self] control in
            self?.onActionButtonTapped?(control)
        }
    }
}
