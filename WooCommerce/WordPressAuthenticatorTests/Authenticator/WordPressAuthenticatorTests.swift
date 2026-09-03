import XCTest
@testable import WordPressAuthenticator

// MARK: - WordPressAuthenticator Unit Tests
//
class WordPressAuthenticatorTests: XCTestCase {
    let timeout = TimeInterval(3)

    override class func setUp() {
        super.setUp()

        WordPressAuthenticator.initialize(
          configuration: WordpressAuthenticatorProvider.wordPressAuthenticatorConfiguration(),
          style: WordpressAuthenticatorProvider.wordPressAuthenticatorStyle(.random),
          unifiedStyle: WordpressAuthenticatorProvider.wordPressAuthenticatorUnifiedStyle(.random)
        )
    }

    func testBaseSiteURL() {
        var baseURL = "testsite.wordpress.com"
        var url = WordPressAuthenticator.baseSiteURL(string: "http://\(baseURL)")
        XCTAssert(url == "https://\(baseURL)", "Should force https for a wpcom site having http.")

        url = WordPressAuthenticator.baseSiteURL(string: baseURL)
        XCTAssert(url == "https://\(baseURL)", "Should force https for a wpcom site without a scheme.")

        baseURL = "www.selfhostedsite.com"
        url = WordPressAuthenticator.baseSiteURL(string: baseURL)
        XCTAssert((url == "https://\(baseURL)"), "Should add https:\\ for a non wpcom site missing a scheme.")

        url = WordPressAuthenticator.baseSiteURL(string: "\(baseURL)/wp-login.php")
        XCTAssert((url == "https://\(baseURL)"), "Should remove wp-login.php from the path.")

        url = WordPressAuthenticator.baseSiteURL(string: "\(baseURL)/wp-admin")
        XCTAssert((url == "https://\(baseURL)"), "Should remove /wp-admin from the path.")

        url = WordPressAuthenticator.baseSiteURL(string: "\(baseURL)/wp-admin/")
        XCTAssert((url == "https://\(baseURL)"), "Should remove /wp-admin/ from the path.")

        url = WordPressAuthenticator.baseSiteURL(string: "\(baseURL)/")
        XCTAssert((url == "https://\(baseURL)"), "Should remove a trailing slash from the url.")

        // Check non-latin characters and puny code
        baseURL = "http://例.例"
        let punycode = "http://xn--fsq.xn--fsq"
        url = WordPressAuthenticator.baseSiteURL(string: baseURL)
        XCTAssert(url == punycode)
        url = WordPressAuthenticator.baseSiteURL(string: punycode)
        XCTAssert(url == punycode)
    }

    func testBaseSiteURLKeepsHTTPSchemeForNonWPSites() {
        let url = "http://selfhostedsite.com"
        let correctedURL = WordPressAuthenticator.baseSiteURL(string: url)
        XCTAssertEqual(correctedURL, url)
    }

    // MARK: View Tests
    func testShowLoginForJustWPComPresentsCorrectVC() {
        let presenterSpy = ModalViewControllerPresentingSpy()
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(block: { _, _ -> Bool in
            return presenterSpy.presentedVC != nil
        }), object: .none)

        WordPressAuthenticator.showLoginForJustWPCom(from: presenterSpy)
        wait(for: [expectation], timeout: timeout)

        XCTAssertTrue(presenterSpy.presentedVC is LoginNavigationController)
    }

    func testShowLoginForJustWPComSetsMetaProperties() throws {
        let presenterSpy = ModalViewControllerPresentingSpy()
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(block: { _, _ -> Bool in
            return presenterSpy.presentedVC != nil
        }), object: .none)

        WordPressAuthenticator.showLoginForJustWPCom(from: presenterSpy,
                                                     jetpackLogin: false,
                                                     connectedEmail: "email-address@example.com")

        let navController = try XCTUnwrap(presenterSpy.presentedVC as? LoginNavigationController)
        let controller = try XCTUnwrap(navController.viewControllers.first as? LoginEmailViewController)

        wait(for: [expectation], timeout: timeout)

        XCTAssertEqual(controller.loginFields.restrictToWPCom, true)
        XCTAssertEqual(controller.loginFields.username, "email-address@example.com")
    }

    func testSignInForWPComWithLoginFieldsReturnsVC() throws {
        let navController = try XCTUnwrap(WordPressAuthenticator.signinForWPCom(dotcomEmailAddress: "example@email.com", dotcomUsername: "username") as? UINavigationController)
        let vc = navController.topViewController

        XCTAssertTrue(vc is LoginWPComViewController)
    }

    func testSignInForWPComSetsEmptyLoginFields() throws {
        let navController = try XCTUnwrap(WordPressAuthenticator.signinForWPCom(dotcomEmailAddress: nil, dotcomUsername: nil) as? UINavigationController)
        let vc = try XCTUnwrap(navController.topViewController as? LoginWPComViewController)

        XCTAssertEqual(vc.loginFields.emailAddress, "")
        XCTAssertEqual(vc.loginFields.username, "")
    }

    // MARK: WordPressAuthenticator URL verification Tests
    func testIsWordPressAuthURL() {
        let authenticator = WordpressAuthenticatorProvider.getWordpressAuthenticator()
        let magicLinkURL = URL(string: "https://magic-login")!
        let googleURL = URL(string: "https://google.com")!
        let wordpressComURL = URL(string: "https://WordPress.com")!

        XCTAssertTrue(authenticator.isWordPressAuthUrl(magicLinkURL))
        XCTAssertFalse(authenticator.isWordPressAuthUrl(googleURL))
        XCTAssertFalse(authenticator.isWordPressAuthUrl(wordpressComURL))
    }

    func testHandleWordPressAuthURLReturnsTrueOnSuccess() {
        let authenticator = WordpressAuthenticatorProvider.getWordpressAuthenticator()
        let url = URL(string: "https://wordpress.com/wp-login.php?token=1234567890%26action&magic-login&sr=1&signature=1234567890oienhdtsra&flow=signup")

        XCTAssertTrue(authenticator.handleWordPressAuthUrl(url!, rootViewController: UIViewController(), restoresSiteAddress: false, automatedTesting: true))
    }

    func test_authenticate_site_credentials_when_delegate_only_implements_legacy_api_then_bridges_once() throws {
        // Given
        let adopter = LegacyOnlyWordPressAuthenticatorDelegate()
        let delegate: WordPressAuthenticatorDelegate = adopter
        let credentials = WordPressOrgCredentials(
            username: "merchant",
            password: "secret",
            xmlrpc: "https://example.com/xmlrpc.php",
            options: ["unrelated": "preserved"]
        )
        var receivedCredentials = [WordPressOrgCredentials]()

        // When
        delegate.authenticateSiteCredentials(
            credentials: credentials,
            loginURL: nil,
            adminURL: nil,
            endpointUnderVerification: nil,
            onLoading: { _ in },
            onSuccess: { receivedCredentials.append($0) },
            onRecovery: { _ in XCTFail("Expected legacy success") },
            onFailure: { _, _, _, _ in XCTFail("Expected legacy success") }
        )

        // Then
        XCTAssertEqual(adopter.legacySuccessCallCount, 1)
        XCTAssertEqual(receivedCredentials.count, 1)
        XCTAssertEqual(try XCTUnwrap(receivedCredentials.first).options["unrelated"] as? String, "preserved")
    }

    func test_authenticate_site_credentials_when_legacy_only_delegate_fails_then_bridges_failure_once() {
        // Given
        let expectedError = NSError(domain: "LegacyAuthentication", code: 401)
        let adopter = LegacyOnlyWordPressAuthenticatorDelegate()
        adopter.errorToReturn = expectedError
        adopter.returnsIncorrectCredentials = true
        let delegate: WordPressAuthenticatorDelegate = adopter
        let credentials = WordPressOrgCredentials(
            username: "merchant",
            password: "secret",
            xmlrpc: "https://example.com/xmlrpc.php",
            options: [:]
        )
        var receivedError: NSError?
        var incorrectCredentials: Bool?
        var verifiedLoginURL: String?
        var offersBrowserAlternative: Bool?

        // When
        delegate.authenticateSiteCredentials(
            credentials: credentials,
            loginURL: nil,
            adminURL: nil,
            endpointUnderVerification: nil,
            onLoading: { _ in },
            onSuccess: { _ in XCTFail("Expected legacy failure") },
            onRecovery: { _ in XCTFail("Expected legacy failure") },
            onFailure: {
                receivedError = $0 as NSError
                incorrectCredentials = $1
                verifiedLoginURL = $2
                offersBrowserAlternative = $3
            }
        )

        // Then
        XCTAssertEqual(adopter.legacyFailureCallCount, 1)
        XCTAssertEqual(receivedError?.domain, expectedError.domain)
        XCTAssertEqual(receivedError?.code, expectedError.code)
        XCTAssertEqual(incorrectCredentials, true)
        XCTAssertNil(verifiedLoginURL)
        XCTAssertEqual(offersBrowserAlternative, false)
    }
}

/// A delegate that adopts only the legacy site credential login contract, to prove the default bridge.
private final class LegacyOnlyWordPressAuthenticatorDelegate: WordPressAuthenticatorDelegate {
    let dismissActionEnabled = true
    let supportActionEnabled = true
    let wpcomTermsOfServiceEnabled = true
    let showSupportNotificationIndicator = true
    let supportEnabled = true
    let allowWPComLogin = true
    private(set) var legacySuccessCallCount = 0
    private(set) var legacyFailureCallCount = 0
    var errorToReturn: Error?
    var returnsIncorrectCredentials = false

    func createdWordPressComAccount(username: String, authToken: String) {}
    func userAuthenticatedWithAppleUserID(_ appleUserID: String) {}
    func presentSupportRequest(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag) {}
    func shouldPresentUsernamePasswordController(for siteInfo: WordPressComSiteInfo?,
                                                 onCompletion: @escaping (WordPressAuthenticatorResult) -> Void) {}
    func presentLoginEpilogue(in navigationController: UINavigationController,
                              for credentials: AuthenticatorCredentials,
                              source: SignInSource?,
                              onDismiss: @escaping () -> Void) {}
    func presentSignupEpilogue(in navigationController: UINavigationController,
                               for credentials: AuthenticatorCredentials,
                               socialUser: SocialUser?) {}
    func presentSupport(from sourceViewController: UIViewController,
                        sourceTag: WordPressSupportSourceTag,
                        lastStep: AuthenticatorAnalyticsTracker.Step,
                        lastFlow: AuthenticatorAnalyticsTracker.Flow,
                        siteURL: String?) {}
    func shouldPresentLoginEpilogue(isJetpackLogin: Bool) -> Bool { true }
    func shouldHandleError(_ error: Error) -> Bool { false }
    func handleError(_ error: Error, onCompletion: @escaping (UIViewController) -> Void) {}
    func shouldPresentSignupEpilogue() -> Bool { false }
    func sync(credentials: AuthenticatorCredentials, onCompletion: @escaping () -> Void) {}

    func handleSiteCredentialLogin(credentials: WordPressOrgCredentials,
                                   onLoading: @escaping (Bool) -> Void,
                                   onSuccess: @escaping () -> Void,
                                   onFailure: @escaping (Error, Bool) -> Void) {
        if let errorToReturn {
            legacyFailureCallCount += 1
            onFailure(errorToReturn, returnsIncorrectCredentials)
            return
        }
        legacySuccessCallCount += 1
        onSuccess()
    }

    func handleSiteInfoFailure(siteURL: String, error: Error, completion: @escaping (Bool) -> Void) {
        completion(false)
    }

    func track(event: WPAnalyticsStat) {}
    func track(event: WPAnalyticsStat, properties: [AnyHashable: Any]) {}
    func track(event: WPAnalyticsStat, error: Error) {}
}
