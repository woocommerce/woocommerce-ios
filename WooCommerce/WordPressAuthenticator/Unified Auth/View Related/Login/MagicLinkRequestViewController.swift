import UIKit
import SwiftUI
import WordPressShared

class MagicLinkRequestViewController: LoginViewController {
    private let stackView = UIStackView()
    let fallbackAction: FallbackAction

    init(fallbackAction: FallbackAction) {
        self.fallbackAction = fallbackAction
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var sourceTag: WordPressSupportSourceTag {
        get {
            return .loginMagicLink
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let email = loginFields.username
        if !email.isValidEmail() {
            assert(email.isValidEmail(), "The value of loginFields.username was not a valid email address.")
        }

        configureStackView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        WordPressAuthenticator.track(.loginMagicLinkRequestFormViewed)
    }
}

// MARK: UI Setup
private extension MagicLinkRequestViewController {
    private func configureStackView() {
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 16
        stackView.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        stackView.pinSubviewToAllEdges(view, insets: view.safeAreaInsets)

        let header = createHeader()
        stackView.addArrangedSubview(header)
        pinSubviewToHorizontalEdges(header)

        let message = UILabel()
        message.text = Localization.description
        message.font = .preferredFont(forTextStyle: .body)
        message.numberOfLines = 0
        stackView.addArrangedSubview(message)
        pinSubviewToHorizontalEdges(message)

        let fallbackButton = createFallbackButton()
        stackView.addArrangedSubview(fallbackButton)

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        stackView.addArrangedSubview(spacer)

        let primaryButton = NUXButton()
        primaryButton.isPrimary = true
        submitButton = primaryButton
        primaryButton.setTitle(Localization.sendMagicLink, for: .normal)
        stackView.addArrangedSubview(primaryButton)
        pinSubviewToHorizontalEdges(primaryButton)
    }

    private func createHeader() -> UIView {
        let headerStackView = UIStackView()
        headerStackView.spacing = 16
        headerStackView.layoutMargins = UIEdgeInsets(top: 24, left: 16, bottom: 24, right: 16)
        headerStackView.isLayoutMarginsRelativeArrangement = true
        headerStackView.axis = .horizontal

        let gravatar = UIImageView()
        gravatar.addConstraints([
            gravatar.widthAnchor.constraint(equalToConstant: 32),
            gravatar.heightAnchor.constraint(equalToConstant: 32)
        ])
        let placeholder = UIImage.gridicon(.userCircle, size: CGSize(width: 32, height: 32))
        gravatar.downloadGravatarWithEmail(loginFields.username, placeholderImage: placeholder)
        gravatar.tintColor = WordPressAuthenticator.shared.unifiedStyle?.borderColor ?? WordPressAuthenticator.shared.style.primaryNormalBorderColor
        headerStackView.addArrangedSubview(gravatar)


        let emailLabel = UILabel()
        emailLabel.text = loginFields.username
        emailLabel.font = .preferredFont(forTextStyle: .body)
        emailLabel.textColor = WordPressAuthenticator.shared.unifiedStyle?.gravatarEmailTextColor ?? WordPressAuthenticator.shared.unifiedStyle?.textSubtleColor ?? WordPressAuthenticator.shared.style.subheadlineColor
        headerStackView.addArrangedSubview(emailLabel)

        headerStackView.layer.cornerRadius = 8
        headerStackView.layer.borderWidth = 1
        headerStackView.layer.borderColor = UIColor.systemGray3.cgColor

        return headerStackView
    }

    private func createFallbackButton() -> UIButton {
        let fallbackButton = NUXButton()
        fallbackButton.contentInsets = .zero
        fallbackButton.buttonStyle = .linkButtonStyle
        fallbackButton.customizeFont(.preferredFont(forTextStyle: .body))

        fallbackButton.setTitle(fallbackAction.buttonTitle(), for: .normal)
        fallbackButton.on(.touchUpInside) { [weak self] _ in
            guard let self else { return }
            guard let passwordVC = PasswordViewController.instantiate(from: .password) else {
                return
            }

            passwordVC.loginFields = self.loginFields

            self.navigationController?.pushViewController(passwordVC, animated: true)
        }
        return fallbackButton
    }

    private func pinSubviewToHorizontalEdges(_ subView: UIView) {
        subView.translatesAutoresizingMaskIntoConstraints = false
        subView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: stackView.layoutMargins.left).isActive = true
        subView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: -stackView.layoutMargins.right).isActive = true
    }
}

private extension MagicLinkRequestViewController {
    struct Localization {
        static let description = NSLocalizedString(
            "login.magicLinkRequest.description",
            value: "We'll email you a link that'll log you in instantly, no password needed.",
            comment: "Description text for the magic link request form."
        )
        static let sendMagicLink = NSLocalizedString(
            "login.magicLinkRequest.sendMagicLink",
            value: "Send link by email",
            comment: "Button title to send the magic link."
        )
        static let passwordFallback = NSLocalizedString(
            "login.magicLinkRequest.passwordFallback",
            value: "Use your password instead",
            comment: "Button title to fallback to password login."
        )
        static let wpcomUsernamePasswordFallback = NSLocalizedString(
            "login.magicLinkRequest.wpcomUsernamePasswordFallback",
            value: "Use username and password instead",
            comment: "Button title to fallback to WordPress.com username and password login."
        )
    }
}

extension MagicLinkRequestViewController {
    enum FallbackAction {
        case password
        case wpcomUsernamePassword

        func buttonTitle() -> String {
            switch self {
            case .password:
                return Localization.passwordFallback
            case .wpcomUsernamePassword:
                return Localization.wpcomUsernamePasswordFallback
            }
        }
    }
}
