import Foundation
import WordPressAuthenticator
import Yosemite
import struct Networking.Settings


/// Encapsulates all of the interactions with the WordPress Authenticator
///
class AuthenticationManager: Authentication {

    /// Store Picker Coordinator
    ///
    private var storePickerCoordinator: StorePickerCoordinator?

    /// Initializes the WordPress Authenticator.
    ///
    func initialize() {
        let configuration = WordPressAuthenticatorConfiguration(wpcomClientId: ApiCredentials.dotcomAppId,
                                                                wpcomSecret: ApiCredentials.dotcomSecret,
                                                                wpcomScheme: ApiCredentials.dotcomAuthScheme,
                                                                wpcomTermsOfServiceURL: WooConstants.URLs.termsOfService.rawValue,
                                                                wpcomAPIBaseURL: Settings.wordpressApiBaseURL,
                                                                googleLoginClientId: ApiCredentials.googleClientId,
                                                                googleLoginServerClientId: ApiCredentials.googleServerId,
                                                                googleLoginScheme: ApiCredentials.googleAuthScheme,
                                                                userAgent: UserAgent.defaultUserAgent,
                                                                showLoginOptions: true,
                                                                enabledSignUp: false,
                                                                enableSignInWithApple: true)

        let style = WordPressAuthenticatorStyle(primaryNormalBackgroundColor: .primaryButtonBackground,
                                                primaryNormalBorderColor: .primaryButtonDownBackground,
                                                primaryHighlightBackgroundColor: .primaryButtonDownBackground,
                                                primaryHighlightBorderColor: .primaryButtonDownBorder,
                                                secondaryNormalBackgroundColor: .secondaryButtonBackground,
                                                secondaryNormalBorderColor: .secondaryButtonBorder,
                                                secondaryHighlightBackgroundColor: .secondaryButtonDownBackground,
                                                secondaryHighlightBorderColor: .secondaryButtonDownBorder,
                                                disabledBackgroundColor: .buttonDisabledBackground,
                                                disabledBorderColor: .gray(.shade30),
                                                primaryTitleColor: .primaryButtonTitle,
                                                secondaryTitleColor: .secondaryButtonTitle,
                                                disabledTitleColor: .textSubtle,
                                                textButtonColor: .accent,
                                                textButtonHighlightColor: .accentDark,
                                                instructionColor: .textSubtle,
                                                subheadlineColor: .gray(.shade30),
                                                placeholderColor: .placeholderImage,
                                                viewControllerBackgroundColor: .listBackground,
                                                textFieldBackgroundColor: .listForeground,
                                                buttonViewBackgroundColor: .primaryDark,
                                                buttonViewTopShadowImage: nil,
                                                navBarImage: StyleManager.navBarImage,
                                                navBarBadgeColor: .primary,
                                                navBarBackgroundColor: .appBar,
                                                prologueTopContainerChildViewController: LoginPrologueViewController())

        let displayStrings = WordPressAuthenticatorDisplayStrings(emailLoginInstructions: AuthenticationConstants.emailInstructions,
                                                                  jetpackLoginInstructions: AuthenticationConstants.jetpackInstructions,
                                                                  siteLoginInstructions: AuthenticationConstants.siteInstructions,
                                                                  siteCredentialInstructions: WordPressAuthenticatorDisplayStrings.defaultStrings.siteCredentialInstructions,
                                                                  twoFactorInstructions: WordPressAuthenticatorDisplayStrings.defaultStrings.twoFactorInstructions,
                                                                  magicLinkInstructions: WordPressAuthenticatorDisplayStrings.defaultStrings.magicLinkInstructions,
                                                                  googlePasswordInstructions: WordPressAuthenticatorDisplayStrings.defaultStrings.googlePasswordInstructions,
                                                                  applePasswordInstructions: WordPressAuthenticatorDisplayStrings.defaultStrings.applePasswordInstructions,
                                                                  continueButtonTitle: WordPressAuthenticatorDisplayStrings.defaultStrings.continueButtonTitle,
                                                                  magicLinkButtonTitle: WordPressAuthenticatorDisplayStrings.defaultStrings.magicLinkButtonTitle,
                                                                  findSiteButtonTitle: WordPressAuthenticatorDisplayStrings.defaultStrings.findSiteButtonTitle,
                                                                  resetPasswordButtonTitle: WordPressAuthenticatorDisplayStrings.defaultStrings.resetPasswordButtonTitle,
                                                                  textCodeButtonTitle: WordPressAuthenticatorDisplayStrings.defaultStrings.textCodeButtonTitle,
                                                                  gettingStartedTitle: WordPressAuthenticatorDisplayStrings.defaultStrings.gettingStartedTitle,
                                                                  logInTitle: WordPressAuthenticatorDisplayStrings.defaultStrings.logInTitle,
                                                                  signUpTitle: WordPressAuthenticatorDisplayStrings.defaultStrings.signUpTitle,
                                                                  waitingForGoogleTitle: WordPressAuthenticatorDisplayStrings.defaultStrings.waitingForGoogleTitle,
                                                                  usernamePlaceholder: WordPressAuthenticatorDisplayStrings.defaultStrings.usernamePlaceholder,
                                                                  passwordPlaceholder: WordPressAuthenticatorDisplayStrings.defaultStrings.passwordPlaceholder,
                                                                  siteAddressPlaceholder: WordPressAuthenticatorDisplayStrings.defaultStrings.siteAddressPlaceholder,
                                                                  twoFactorCodePlaceholder: WordPressAuthenticatorDisplayStrings.defaultStrings.twoFactorCodePlaceholder)

        let unifiedStyle = WordPressAuthenticatorUnifiedStyle(borderColor: .divider,
                                                              errorColor: .error,
                                                              textColor: .text,
                                                              textSubtleColor: .textSubtle,
                                                              textButtonColor: .brand,
                                                              textButtonHighlightColor: .brand,
                                                              viewControllerBackgroundColor: .basicBackground,
                                                              navBarBackgroundColor: .basicBackground,
                                                              navButtonTextColor: .brand,
                                                              navTitleTextColor: .text)

        let displayImages = WordPressAuthenticatorDisplayImages(
            magicLink: .loginMagicLinkImage,
            siteAddressModalPlaceholder: .loginSiteAddressInfoImage
        )

        WordPressAuthenticator.initialize(configuration: configuration,
                                          style: style,
                                          unifiedStyle: unifiedStyle,
                                          displayImages: displayImages,
                                          displayStrings: displayStrings)
        WordPressAuthenticator.shared.delegate = self
    }

    /// Displays the Login Flow using the specified UIViewController as presenter.
    ///
    func displayAuthentication(from presenter: UIViewController) {
        WordPressAuthenticator.showLogin(from: presenter, animated: false, onLoginButtonTapped: {
            ServiceLocator.analytics.track(.loginPrologueContinueTapped)
        })
    }

    /// Handles an Authentication URL Callback. Returns *true* on success.
    ///
    func handleAuthenticationUrl(_ url: URL, options: [UIApplication.OpenURLOptionsKey: Any], rootViewController: UIViewController) -> Bool {
        let source = options[.sourceApplication] as? String
        let annotation = options[.annotation]

        if WordPressAuthenticator.shared.isGoogleAuthUrl(url) {
            return WordPressAuthenticator.shared.handleGoogleAuthUrl(url, sourceApplication: source, annotation: annotation)
        }

        if WordPressAuthenticator.shared.isWordPressAuthUrl(url) {
            return WordPressAuthenticator.shared.handleWordPressAuthUrl(url, allowWordPressComAuth: true, rootViewController: rootViewController)
        }

        return false
    }
}



// MARK: - WordPressAuthenticator Delegate
//
extension AuthenticationManager: WordPressAuthenticatorDelegate {
    /// When an Apple account is used during the Auth flow, save the Apple user id to the keychain.
    /// It will be used on app launch to check the user id state.
    ///
    func userAuthenticatedWithAppleUserID(_ appleUserID: String) {
//        do {
//            try SFHFKeychainUtils.storeUsername(WPAppleIDKeychainUsernameKey,
//                                                andPassword: appleUserID,
//                                                forServiceName: WPAppleIDKeychainServiceName,
//                                                updateExisting: true)
//        } catch {
//            DDLogInfo("Error while saving Apple User ID: \(error)")
//        }
    }

    var allowWPComLogin: Bool {
        return true
    }

    /// Indicates if the active Authenticator can be dismissed or not.
    ///
    var dismissActionEnabled: Bool {
        // TODO: Return *true* only if there is no default account already set.
        return false
    }

    /// Indicates whether if the Support Action should be enabled, or not.
    ///
    var supportActionEnabled: Bool {
        return true
    }

    /// Indicates if Support is Enabled.
    ///
    var supportEnabled: Bool {
        return ZendeskManager.shared.zendeskEnabled
    }

    /// Indicates if the Support notification indicator should be displayed.
    ///
    var showSupportNotificationIndicator: Bool {
        // TODO: Wire Zendesk
        return false
    }

    /// Executed whenever a new WordPress.com account has been created.
    /// Note: As of now, this is a NO-OP, we're not supporting any signup flows.
    ///
    func createdWordPressComAccount(username: String, authToken: String) { }

    /// Validates that the self-hosted site contains the correct information
    /// and can proceed to the self-hosted username and password view controller.
    ///
    func shouldPresentUsernamePasswordController(for siteInfo: WordPressComSiteInfo?, onCompletion: @escaping (Error?, Bool) -> Void) {
        let isSelfHosted = false

        guard let site = siteInfo, site.hasJetpack == true else {
            let errorInfo = NSLocalizedString(
                "Looks like your site isn't set up to use this app. Make sure your site has Jetpack installed to continue.",
                comment: "Error message that displays on the 'Log in by entering your site address.' screen. " +
                "Jetpack is required for logging into the WooCommerce mobile apps.")
            let error = NSError(domain: "WooCommerceAuthenticationErrorDomain",
                                code: 555,
                                userInfo: [NSLocalizedDescriptionKey: errorInfo])
            onCompletion(error, isSelfHosted)
            return
        }

        onCompletion(nil, isSelfHosted)
    }

    /// Presents the Login Epilogue, in the specified NavigationController.
    ///
    func presentLoginEpilogue(in navigationController: UINavigationController, for credentials: AuthenticatorCredentials, onDismiss: @escaping () -> Void) {
        storePickerCoordinator = StorePickerCoordinator(navigationController, config: .login)
        storePickerCoordinator?.onDismiss = onDismiss
        storePickerCoordinator?.start()
    }

    /// Presents the Signup Epilogue, in the specified NavigationController.
    ///
    func presentSignupEpilogue(in navigationController: UINavigationController, for credentials: AuthenticatorCredentials, service: SocialService?) {
        // NO-OP: The current WC version does not support Signup.
    }

    /// Presents the Support Interface from a given ViewController, with a specified SourceTag.
    ///
    func presentSupport(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag) {
        let identifier = HelpAndSupportViewController.classNameWithoutNamespaces
        guard let supportViewController = UIStoryboard.dashboard.instantiateViewController(withIdentifier: identifier) as? HelpAndSupportViewController else {
            return
        }

        supportViewController.displaysDismissAction = true

        let navController = UINavigationController(rootViewController: supportViewController)
        navController.modalPresentationStyle = .formSheet

        sourceViewController.present(navController, animated: true, completion: nil)
    }

    /// Presents the Support new request, from a given ViewController, with a specified SourceTag.
    ///
    func presentSupportRequest(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag) {
        ZendeskManager.shared.showNewRequestIfPossible(from: sourceViewController, with: sourceTag.name)
    }

    /// Indicates if the Login Epilogue should be presented.
    ///
    func shouldPresentLoginEpilogue(isJetpackLogin: Bool) -> Bool {
        return true
    }

    /// Indicates if the Signup Epilogue should be displayed.
    /// Note: As of now, this is a NO-OP, we're not supporting any signup flows.
    ///
    func shouldPresentSignupEpilogue() -> Bool {
        return false
    }

    /// Synchronizes the specified WordPress Account.
    ///
    func sync(credentials: AuthenticatorCredentials, onCompletion: @escaping () -> Void) {
        guard let wpcom = credentials.wpcom else {
            fatalError("Self Hosted sites are not supported. Please review the Authenticator settings!")
        }

        ServiceLocator.stores.authenticate(credentials: .init(authToken: wpcom.authToken))
        let action = AccountAction.synchronizeAccount { (account, error) in
            if let account = account {
                let credentials = Credentials(username: account.username, authToken: wpcom.authToken, siteAddress: wpcom.siteURL)
                ServiceLocator.stores
                    .authenticate(credentials: credentials)
                    .synchronizeEntities(onCompletion: onCompletion)
            } else {
                ServiceLocator.stores.synchronizeEntities(onCompletion: onCompletion)
            }
        }
        ServiceLocator.stores.dispatch(action)
    }

    /// Tracks a given Analytics Event.
    ///
    func track(event: WPAnalyticsStat) {
        guard let wooEvent = WooAnalyticsStat.valueOf(stat: event) else {
            DDLogWarn("⚠️ Could not convert WPAnalyticsStat with value: \(event.rawValue)")
            return
        }
        ServiceLocator.analytics.track(wooEvent)
    }

    /// Tracks a given Analytics Event, with the specified properties.
    ///
    func track(event: WPAnalyticsStat, properties: [AnyHashable: Any]) {
        guard let wooEvent = WooAnalyticsStat.valueOf(stat: event) else {
            DDLogWarn("⚠️ Could not convert WPAnalyticsStat with value: \(event.rawValue)")
            return
        }
        ServiceLocator.analytics.track(wooEvent, withProperties: properties)
    }

    /// Tracks a given Analytics Event, with the specified error.
    ///
    func track(event: WPAnalyticsStat, error: Error) {
        guard let wooEvent = WooAnalyticsStat.valueOf(stat: event) else {
            DDLogWarn("⚠️ Could not convert WPAnalyticsStat with value: \(event.rawValue)")
            return
        }
        ServiceLocator.analytics.track(wooEvent, withError: error)
    }
}
