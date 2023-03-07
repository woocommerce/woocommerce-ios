import WordPressAuthenticator
import Experiments
import class Networking.UserAgent
import struct Networking.Settings

extension WordPressAuthenticator {
    static func initializeWithCustomConfigs(dotcomAuthScheme: String = ApiCredentials.dotcomAuthScheme,
                                            featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        let isWPComMagicLinkPreferredToPassword = featureFlagService.isFeatureFlagEnabled(.loginMagicLinkEmphasis)
        let isWPComMagicLinkShownAsSecondaryActionOnPasswordScreen = featureFlagService.isFeatureFlagEnabled(.loginMagicLinkEmphasisM2)
        let isStoreCreationMVPEnabled = featureFlagService.isFeatureFlagEnabled(.storeCreationMVP)
        let configuration = WordPressAuthenticatorConfiguration(wpcomClientId: ApiCredentials.dotcomAppId,
                                                                wpcomSecret: ApiCredentials.dotcomSecret,
                                                                wpcomScheme: dotcomAuthScheme,
                                                                wpcomTermsOfServiceURL: WooConstants.URLs.termsOfService.rawValue,
                                                                wpcomAPIBaseURL: Settings.wordpressApiBaseURL,
                                                                whatIsWPComURL: WooConstants.URLs.whatIsWPCom.rawValue,
                                                                googleLoginClientId: ApiCredentials.googleClientId,
                                                                googleLoginServerClientId: ApiCredentials.googleServerId,
                                                                googleLoginScheme: ApiCredentials.googleAuthScheme,
                                                                userAgent: UserAgent.defaultUserAgent,
                                                                showLoginOptions: true,
                                                                enableSignUp: false,
                                                                enableSignInWithApple: true,
                                                                enableSignupWithGoogle: false,
                                                                enableUnifiedAuth: true,
                                                                continueWithSiteAddressFirst: false,
                                                                enableSiteCredentialsLoginForSelfHostedSites: true,
                                                                isWPComLoginRequiredForSiteCredentialsLogin: false,
                                                                isWPComMagicLinkPreferredToPassword: isWPComMagicLinkPreferredToPassword,
                                                                isWPComMagicLinkShownAsSecondaryActionOnPasswordScreen:
                                                                    isWPComMagicLinkShownAsSecondaryActionOnPasswordScreen,
                                                                enableWPComLoginOnlyInPrologue: false,
                                                                enableSiteCreation: isStoreCreationMVPEnabled,
                                                                enableSocialLogin: true,
                                                                emphasizeEmailForWPComPassword: true,
                                                                wpcomPasswordInstructions:
                                                                AuthenticationConstants.wpcomPasswordInstructions,
                                                                skipXMLRPCCheckForSiteDiscovery: true,
                                                                skipXMLRPCCheckForSiteAddressLogin: true,
                                                                enableManualSiteCredentialLogin: true,
                                                                useEnterEmailAddressAsStepValueForGetStartedVC: true,
                                                                enableSiteAddressLoginOnlyInPrologue: true,
                                                                enableSiteCredentialLoginForJetpackSites: false)

        let systemGray3LightModeColor = UIColor(red: 199/255.0, green: 199/255.0, blue: 204/255.0, alpha: 1)
        let systemLabelLightModeColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        let style = WordPressAuthenticatorStyle(primaryNormalBackgroundColor: .primaryButtonBackground,
                                                primaryNormalBorderColor: .primaryButtonDownBackground,
                                                primaryHighlightBackgroundColor: .primaryButtonDownBackground,
                                                primaryHighlightBorderColor: .primaryButtonDownBorder,
                                                secondaryNormalBackgroundColor: .white,
                                                secondaryNormalBorderColor: systemGray3LightModeColor,
                                                secondaryHighlightBackgroundColor: systemGray3LightModeColor,
                                                secondaryHighlightBorderColor: systemGray3LightModeColor,
                                                disabledBackgroundColor: .buttonDisabledBackground,
                                                disabledBorderColor: .gray(.shade30),
                                                primaryTitleColor: .primaryButtonTitle,
                                                secondaryTitleColor: systemLabelLightModeColor,
                                                disabledTitleColor: .textSubtle,
                                                disabledButtonActivityIndicatorColor: .textSubtle,
                                                textButtonColor: .accent,
                                                textButtonHighlightColor: .accentDark,
                                                instructionColor: .textSubtle,
                                                subheadlineColor: .gray(.shade30),
                                                placeholderColor: .placeholderImage,
                                                viewControllerBackgroundColor: .listBackground,
                                                textFieldBackgroundColor: .listForeground(modal: false),
                                                buttonViewBackgroundColor: .authPrologueBottomBackgroundColor,
                                                buttonViewTopShadowImage: nil,
                                                navBarImage: StyleManager.navBarImage,
                                                navBarBadgeColor: .primary,
                                                navBarBackgroundColor: .appBar,
                                                prologueTopContainerChildViewController:
                                                    LoginPrologueViewController(isFeatureCarouselShown: false),
                                                statusBarStyle: .default)

        let getStartedInstructions = AuthenticationConstants.getStartedInstructions

        let continueWithWPButtonTitle = AuthenticationConstants.continueWithWPButtonTitle

        let emailAddressPlaceholder = WordPressAuthenticatorDisplayStrings.defaultStrings.emailAddressPlaceholder

        let displayStrings = WordPressAuthenticatorDisplayStrings(emailLoginInstructions: AuthenticationConstants.emailInstructions,
                                                                  getStartedInstructions: getStartedInstructions,
                                                                  jetpackLoginInstructions: AuthenticationConstants.jetpackInstructions,
                                                                  siteLoginInstructions: AuthenticationConstants.siteInstructions,
                                                                  siteCredentialInstructions: AuthenticationConstants.siteCredentialInstructions,
                                                                  usernamePasswordInstructions: AuthenticationConstants.usernamePasswordInstructions,
                                                                  applePasswordInstructions: AuthenticationConstants.applePasswordInstructions,
                                                                  continueWithWPButtonTitle: continueWithWPButtonTitle,
                                                                  enterYourSiteAddressButtonTitle: AuthenticationConstants.enterYourSiteAddressButtonTitle,
                                                                  signInWithSiteCredentialsButtonTitle: AuthenticationConstants.signInWithSiteCredsButtonTitle,
                                                                  findSiteButtonTitle: AuthenticationConstants.findYourStoreAddressButtonTitle,
                                                                  signupTermsOfService: AuthenticationConstants.signupTermsOfService,
                                                                  whatIsWPComLinkTitle: AuthenticationConstants.whatIsWPComLinkTitle,
                                                                  siteCreationButtonTitle: AuthenticationConstants.createSiteButtonTitle,
                                                                  getStartedTitle: AuthenticationConstants.loginTitle,
                                                                  emailAddressPlaceholder: emailAddressPlaceholder)

        let unifiedStyle = WordPressAuthenticatorUnifiedStyle(borderColor: .divider,
                                                              errorColor: .error,
                                                              textColor: .text,
                                                              textSubtleColor: .textSubtle,
                                                              textButtonColor: .accent,
                                                              textButtonHighlightColor: .accentDark,
                                                              viewControllerBackgroundColor: .basicBackground,
                                                              prologueButtonsBackgroundColor: .authPrologueBottomBackgroundColor,
                                                              prologueViewBackgroundColor: .authPrologueBottomBackgroundColor,
                                                              navBarBackgroundColor: .basicBackground,
                                                              navButtonTextColor: .accent,
                                                              navTitleTextColor: .text,
                                                              gravatarEmailTextColor: .text)

        let displayImages = WordPressAuthenticatorDisplayImages(
            magicLink: .loginMagicLinkImage,
            siteAddressModalPlaceholder: .loginSiteAddressInfoImage
        )

        WordPressAuthenticator.initialize(configuration: configuration,
                                          style: style,
                                          unifiedStyle: unifiedStyle,
                                          displayImages: displayImages,
                                          displayStrings: displayStrings)
        WordPressAuthenticator.shared.setWordPressKitLogger(logger: ServiceLocator.wordPressLibraryLogger)
    }
}
