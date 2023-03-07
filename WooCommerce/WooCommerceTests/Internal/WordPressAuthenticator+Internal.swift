import WordPressAuthenticator

extension WordPressAuthenticator {
    static func initializeAuthenticator() {
        let configuration = WordPressAuthenticatorConfiguration(wpcomClientId: "",
                                                                wpcomSecret: "",
                                                                wpcomScheme: "",
                                                                wpcomTermsOfServiceURL: "",
                                                                wpcomAPIBaseURL: "",
                                                                googleLoginClientId: "",
                                                                googleLoginServerClientId: "",
                                                                googleLoginScheme: "",
                                                                userAgent: "",
                                                                showLoginOptions: true,
                                                                enableSignUp: false,
                                                                enableSignInWithApple: false,
                                                                enableSignupWithGoogle: false,
                                                                enableUnifiedAuth: true,
                                                                continueWithSiteAddressFirst: true)

        let style = WordPressAuthenticatorStyle(primaryNormalBackgroundColor: .red,
                                                primaryNormalBorderColor: .red,
                                                primaryHighlightBackgroundColor: .red,
                                                primaryHighlightBorderColor: .red,
                                                secondaryNormalBackgroundColor: .red,
                                                secondaryNormalBorderColor: .red,
                                                secondaryHighlightBackgroundColor: .red,
                                                secondaryHighlightBorderColor: .red,
                                                disabledBackgroundColor: .red,
                                                disabledBorderColor: .red,
                                                primaryTitleColor: .primaryButtonTitle,
                                                secondaryTitleColor: .red,
                                                disabledTitleColor: .red,
                                                disabledButtonActivityIndicatorColor: .red,
                                                textButtonColor: .red,
                                                textButtonHighlightColor: .red,
                                                instructionColor: .red,
                                                subheadlineColor: .red,
                                                placeholderColor: .red,
                                                viewControllerBackgroundColor: .red,
                                                textFieldBackgroundColor: .red,
                                                buttonViewBackgroundColor: .red,
                                                buttonViewTopShadowImage: nil,
                                                navBarImage: UIImage(),
                                                navBarBadgeColor: .red,
                                                navBarBackgroundColor: .red,
                                                prologueTopContainerChildViewController: nil,
                                                statusBarStyle: .default)

        let displayStrings = WordPressAuthenticatorDisplayStrings(emailLoginInstructions: "",
                                                                  getStartedInstructions: "",
                                                                  jetpackLoginInstructions: "",
                                                                  siteLoginInstructions: "",
                                                                  usernamePasswordInstructions: "",
                                                                  continueWithWPButtonTitle: "",
                                                                  enterYourSiteAddressButtonTitle: "",
                                                                  findSiteButtonTitle: "",
                                                                  signupTermsOfService: "",
                                                                  getStartedTitle: "")

        let unifiedStyle = WordPressAuthenticatorUnifiedStyle(borderColor: .red,
                                                              errorColor: .red,
                                                              textColor: .red,
                                                              textSubtleColor: .red,
                                                              textButtonColor: .red,
                                                              textButtonHighlightColor: .red,
                                                              viewControllerBackgroundColor: .red,
                                                              prologueButtonsBackgroundColor: .red,
                                                              prologueViewBackgroundColor: .red,
                                                              navBarBackgroundColor: .red,
                                                              navButtonTextColor: .red,
                                                              navTitleTextColor: .red)

        let displayImages = WordPressAuthenticatorDisplayImages(
            magicLink: UIImage(),
            siteAddressModalPlaceholder: UIImage()
        )

        WordPressAuthenticator.initialize(configuration: configuration,
                                          style: style,
                                          unifiedStyle: unifiedStyle,
                                          displayImages: displayImages,
                                          displayStrings: displayStrings)
    }
}
