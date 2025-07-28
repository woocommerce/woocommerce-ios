import UIKit
import WordPressUI
import SwiftUI
import WordPressShared

class MagicLinkRequestViewController: LoginViewController {
    private let stackView = UIStackView()
    let fallbackAction: MagicLinkFallbackAction

    init(fallbackAction: MagicLinkFallbackAction) {
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

        tracker.set(flow: .loginWithMagicLink)
        tracker.track(step: .start)

        configureStackView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        WordPressAuthenticator.track(.loginMagicLinkRequestFormViewed)
    }
}

// MARK: Actions
private extension MagicLinkRequestViewController {
    func sendMagicLink() {
        Task { @MainActor in
            tracker.track(click: .requestMagicLink)
            configureSubmitButton(animating: true)

            let result = await MagicLinkRequester().requestMagicLink(email: loginFields.username, jetpackLogin: loginFields.meta.jetpackLogin)

            configureSubmitButton(animating: false)

            switch result {
            case .success:
                let vc = MagicLinkRequestedViewController(email: loginFields.username,
                                                          fallbackAction: fallbackAction) { [weak self] in
                    self?.openFallbackScreen()
                }

                vc.loginFields = loginFields
                navigationController?.pushViewController(vc, animated: true)

            case .failure(let error):
                WordPressAuthenticator.track(.loginMagicLinkFailed, error: error)
                displayErrorAlert(Localization.magicLinkError, sourceTag: self.sourceTag)
            }
        }
    }

    func openFallbackScreen() {
        let vc: LoginViewController?
        switch self.fallbackAction {
        case .password:
            tracker.track(click: .loginWithAccountPassword)
            vc = PasswordViewController.instantiate(from: .password)
        case .wpcomUsernamePassword:
            tracker.track(click: .loginWithWPComUsernamePassword)
            vc = SiteCredentialsViewController.instantiate(from: .siteAddress)
        }

        guard let vc else { return }

        vc.loginFields = self.loginFields
        if fallbackAction == .wpcomUsernamePassword {
            vc.loginFields.siteAddress = "https://wordpress.com"
        }

        self.navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: UI Setup
private extension MagicLinkRequestViewController {
    func configureStackView() {
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = Layout.defaultSpacing
        stackView.layoutMargins = UIEdgeInsets(top: Layout.stackViewPadding,
                                               left: Layout.stackViewPadding,
                                               bottom: Layout.stackViewPadding,
                                               right: Layout.stackViewPadding)
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

        let primaryButton = createPrimaryButton()
        stackView.addArrangedSubview(primaryButton)
        pinSubviewToHorizontalEdges(primaryButton)
    }

    func createHeader() -> UIView {
        let headerStackView = UIStackView()
        headerStackView.spacing = Layout.defaultSpacing
        headerStackView.layoutMargins = UIEdgeInsets(top: Layout.headerVerticalPadding,
                                                     left: Layout.headerHorizontalPadding,
                                                     bottom: Layout.headerVerticalPadding,
                                                     right: Layout.headerHorizontalPadding)
        headerStackView.isLayoutMarginsRelativeArrangement = true
        headerStackView.axis = .horizontal

        let gravatar = UIImageView()
        gravatar.addConstraints([
            gravatar.widthAnchor.constraint(equalToConstant: Layout.gravatarSize),
            gravatar.heightAnchor.constraint(equalToConstant: Layout.gravatarSize)
        ])
        let placeholder = UIImage.gridicon(.userCircle, size: CGSize(width: Layout.gravatarSize, height: Layout.gravatarSize))
        gravatar.downloadGravatarWithEmail(loginFields.username, placeholderImage: placeholder)
        gravatar.tintColor = WordPressAuthenticator.shared.unifiedStyle?.borderColor ?? WordPressAuthenticator.shared.style.primaryNormalBorderColor
        headerStackView.addArrangedSubview(gravatar)


        let emailLabel = UILabel()
        emailLabel.text = loginFields.username
        emailLabel.font = .preferredFont(forTextStyle: .body)
        emailLabel.textColor = WordPressAuthenticator.shared.unifiedStyle?.gravatarEmailTextColor ?? WordPressAuthenticator.shared.unifiedStyle?.textSubtleColor ?? WordPressAuthenticator.shared.style.subheadlineColor
        headerStackView.addArrangedSubview(emailLabel)

        headerStackView.layer.cornerRadius = Layout.headerCornerRadius
        headerStackView.layer.borderWidth = Layout.headerBorderWidth
        headerStackView.layer.borderColor = UIColor.systemGray3.cgColor

        return headerStackView
    }

    func createFallbackButton() -> UIButton {
        let fallbackButton = NUXButton()
        fallbackButton.contentInsets = .zero
        fallbackButton.buttonStyle = .linkButtonStyle
        fallbackButton.titleLabel?.numberOfLines = 0
        fallbackButton.customizeFont(.preferredFont(forTextStyle: .body))

        fallbackButton.setTitle(fallbackButtonTitle(), for: .normal)
        fallbackButton.on(.touchUpInside) { [weak self] _ in
            self?.openFallbackScreen()
        }
        return fallbackButton
    }

    func createPrimaryButton() -> UIButton {
        let primaryButton = NUXButton()
        primaryButton.isPrimary = true
        submitButton = primaryButton
        primaryButton.setTitle(Localization.sendMagicLink, for: .normal)
        primaryButton.on(.touchUpInside) { [weak self] _ in
            self?.sendMagicLink()
        }

        return primaryButton
    }

    func pinSubviewToHorizontalEdges(_ subView: UIView) {
        subView.translatesAutoresizingMaskIntoConstraints = false
        subView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: stackView.layoutMargins.left).isActive = true
        subView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: -stackView.layoutMargins.right).isActive = true
    }
}

private extension MagicLinkRequestViewController {
    struct Layout {
        static let defaultSpacing: CGFloat = 16
        static let stackViewPadding: CGFloat = 16
        static let headerVerticalPadding: CGFloat = 24
        static let headerHorizontalPadding: CGFloat = 16
        static let headerCornerRadius: CGFloat = 8
        static let headerBorderWidth: CGFloat = 1
        static let gravatarSize: CGFloat = 32
    }

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
        static let magicLinkError = NSLocalizedString(
            "login.magicLinkRequest.error",
            value: "Something went wrong. Please try again.",
            comment: "Error message when magic link request fails."
        )
    }

    func fallbackButtonTitle() -> String {
        switch fallbackAction {
        case .password:
            return Localization.passwordFallback
        case .wpcomUsernamePassword:
            return Localization.wpcomUsernamePasswordFallback
        }
    }
}
