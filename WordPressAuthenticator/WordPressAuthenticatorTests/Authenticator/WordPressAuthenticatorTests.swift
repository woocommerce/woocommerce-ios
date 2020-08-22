import XCTest
@testable import WordPressAuthenticator

// MARK: - WordPressAuthenticator Unit Tests
//
class WordPressAuthenticatorTests: XCTestCase {
    let timeInterval = TimeInterval(3)

    override class func setUp() {
        super.setUp()

        WordPressAuthenticator.initialize(
          configuration: MockWordpressAuthenticatorProvider.wordPressAuthenticatorConfiguration(),
          style: MockWordpressAuthenticatorProvider.wordPressAuthenticatorStyle(.random),
          unifiedStyle: MockWordpressAuthenticatorProvider.wordPressAuthenticatorUnifiedStyle(.random)
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

    func testEmailAddressTokenHandling() {
        let email = "example@email.com"
        let loginFields = LoginFields()
        loginFields.username = email
        WordPressAuthenticator.storeLoginInfoForTokenAuth(loginFields)

        var retrievedLoginFields = WordPressAuthenticator.retrieveLoginInfoForTokenAuth()
        var retrievedEmail = retrievedLoginFields.username
        XCTAssert(email == retrievedEmail, "The email retrived should match the email that was saved.")

        WordPressAuthenticator.deleteLoginInfoForTokenAuth()
        retrievedLoginFields = WordPressAuthenticator.retrieveLoginInfoForTokenAuth()
        retrievedEmail = retrievedLoginFields.username

        XCTAssert(email != retrievedEmail, "Saved loginFields should be deleted after calling deleteLoginInfoForTokenAuth.")
    }

    // MARK: WordPressAuthenticator Notification Tests
    func testDispatchesSupportPushNotificationReceived() {
        let authenticator = MockWordpressAuthenticatorProvider.getWordpressAuthenticator()
        let _ = expectation(forNotification: .wordpressSupportNotificationReceived, object: nil, handler: nil)

        authenticator.supportPushNotificationReceived()

        waitForExpectations(timeout: timeInterval, handler: nil)
    }

    func testDispatchesSupportPushNotificationCleared() {
        let authenticator = MockWordpressAuthenticatorProvider.getWordpressAuthenticator()
        let _ = expectation(forNotification: .wordpressSupportNotificationCleared, object: nil, handler: nil)

        authenticator.supportPushNotificationCleared()

        waitForExpectations(timeout: timeInterval, handler: nil)
    }

    // MARK: View Tests
    func testWordpressAuthIsAuthenticationViewController() {
        let loginViewcontroller = LoginViewController()
        let nuxViewController = NUXViewController()
        let nuxTableViewController = NUXTableViewController()
        let basicViewController = UIViewController()


        XCTAssertTrue(WordPressAuthenticator.isAuthenticationViewController(loginViewcontroller))
        XCTAssertTrue(WordPressAuthenticator.isAuthenticationViewController(nuxViewController))
        XCTAssertTrue(WordPressAuthenticator.isAuthenticationViewController(nuxTableViewController))
        XCTAssertFalse(WordPressAuthenticator.isAuthenticationViewController(basicViewController))
    }

    func testShowLoginFromPresenterReturnsLoginInitialVC() {
        let presenterSpy = ModalViewControllerPresentingSpy()
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(block: { (_, _) -> Bool in
            return presenterSpy.presentedVC != nil
        }), object: .none)

        WordPressAuthenticator.showLoginFromPresenter(presenterSpy, animated: true)
        wait(for: [expectation], timeout: 3)

        XCTAssertTrue(presenterSpy.presentedVC is LoginNavigationController)
    }

    func testShowLoginForJustWPComPresentsCorrectVC() {
        let presenterSpy = ModalViewControllerPresentingSpy()
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(block: { (_, _) -> Bool in
            return presenterSpy.presentedVC != nil
        }), object: .none)

        WordPressAuthenticator.showLoginForJustWPCom(from: presenterSpy)
        wait(for: [expectation], timeout: 3)

        XCTAssertTrue(presenterSpy.presentedVC is LoginNavigationController)
    }

    func testSignInForWPOrgReturnsVC() {
        let vc = WordPressAuthenticator.signinForWPOrg()

        XCTAssertTrue(vc is LoginSiteAddressViewController)
    }

    func testShowLoginForJustWPComSetsMetaProperties() throws {
        let presenterSpy = ModalViewControllerPresentingSpy()
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(block: { (_, _) -> Bool in
            return presenterSpy.presentedVC != nil
        }), object: .none)

        WordPressAuthenticator.showLoginForJustWPCom(from: presenterSpy,
                                                     xmlrpc: "https://example.com/xmlrpc.php",
                                                     username: "username",
                                                     connectedEmail: "email-address@example.com")

        let navController = try XCTUnwrap(presenterSpy.presentedVC as? LoginNavigationController)
        let controller = try XCTUnwrap(navController.viewControllers.first as? LoginEmailViewController)

        wait(for: [expectation], timeout: 3)

        XCTAssertEqual(controller.loginFields.restrictToWPCom, true)
        XCTAssertEqual(controller.loginFields.meta.jetpackBlogXMLRPC, "https://example.com/xmlrpc.php")
        XCTAssertEqual(controller.loginFields.meta.jetpackBlogUsername, "username")
        XCTAssertEqual(controller.loginFields.username, "email-address@example.com")
    }

    func testShowLoginForSelfHostedSitePresentsCorrectVC() {
        let presenterSpy = ModalViewControllerPresentingSpy()
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(block: { (_, _) -> Bool in
            return presenterSpy.presentedVC != nil
        }), object: .none)

        WordPressAuthenticator.showLoginForSelfHostedSite(presenterSpy)
        wait(for: [expectation], timeout: 3)

        XCTAssertTrue(presenterSpy.presentedVC is LoginNavigationController)
    }

    func testSignInForWPComReturnsVC() {
        let vc = WordPressAuthenticator.signinForWPCom()

        XCTAssertTrue((vc as Any) is LoginEmailViewController)
    }

    func testSignInForWPComWithLoginFieldsReturnsVC() throws {
        let navController = try XCTUnwrap(WordPressAuthenticator.signinForWPCom(dotcomEmailAddress: "example@email.com", dotcomUsername: "username") as? UINavigationController)
        let vc = navController.topViewController

        XCTAssertTrue(vc is LoginWPComViewController)
    }

    func testSignInForWPComSetsEmptyLoginFields() {
        let navController = WordPressAuthenticator.signinForWPCom(dotcomEmailAddress: nil, dotcomUsername: nil) as! UINavigationController
        let vc = navController.topViewController as! LoginWPComViewController

        XCTAssertEqual(vc.loginFields.emailAddress, "")
        XCTAssertEqual(vc.loginFields.username, "")
    }

    // MARK: WordPressAuthenticator URL verification Tests
    func testIsGoogleAuthURL() {
        let authenticator = MockWordpressAuthenticatorProvider.getWordpressAuthenticator()
        let googleURL = URL(string: "com.googleuserconsent.apps/82ekn2932nub23h23hn3")!
        let magicLinkURL = URL(string: "https://magic-login")!
        let wordpressComURL = URL(string: "https://WordPress.com")!

        XCTAssertTrue(authenticator.isGoogleAuthUrl(googleURL))
        XCTAssertFalse(authenticator.isGoogleAuthUrl(magicLinkURL))
        XCTAssertFalse(authenticator.isGoogleAuthUrl(wordpressComURL))
    }

    func testIsWordPressAuthURL() {
        let authenticator = MockWordpressAuthenticatorProvider.getWordpressAuthenticator()
        let magicLinkURL = URL(string: "https://magic-login")!
        let googleURL = URL(string: "https://google.com")!
        let wordpressComURL = URL(string: "https://WordPress.com")!

        XCTAssertTrue(authenticator.isWordPressAuthUrl(magicLinkURL))
        XCTAssertFalse(authenticator.isWordPressAuthUrl(googleURL))
        XCTAssertFalse(authenticator.isWordPressAuthUrl(wordpressComURL))
    }

    func testHandleWordPressAuthURLReturnsTrueOnSucceed() {
        let authenticator = MockWordpressAuthenticatorProvider.getWordpressAuthenticator()
        let url = URL(string: "https://wordpress.com/wp-login.php?token=1234567890%26action&magic-login&sr=1&signature=1234567890oienhdtsra")

        XCTAssertTrue(authenticator.handleWordPressAuthUrl(url!, allowWordPressComAuth: true, rootViewController: UIViewController()))
    }

    func testOpenAuthenticationFailsWithoutQuery() {
        let url = URL(string: "https://WordPress.com/")

        let result = WordPressAuthenticator.openAuthenticationURL(url!, allowWordPressComAuth: false, fromRootViewController: UIViewController())

        XCTAssertFalse(result)
    }

    func testOpenAuthenticationFailsWithoutWpcomAuth() {
        let url = URL(string: "https://WordPress.com/?token=arstdhneio0987654321")
        let loginFields = LoginFields()
        loginFields.username = "user123"
        loginFields.password = "knockknock"

        let result = WordPressAuthenticator.openAuthenticationURL(url!, allowWordPressComAuth: false, fromRootViewController: UIViewController())

        XCTAssertFalse(result)
    }

    // MARK: WordPressAuthenticator OnePassword Tests
    func testFetchOnePasswordCredentialsSucceeds() {
        let onePasswordFetcher = MockOnePasswordFacade(username: "username", password: "knockknock", otp: nil)
        let loginFields = LoginFields()
        loginFields.meta.userIsDotCom = true

        let expect = expectation(description: "Could fetch OnePassword credentials")

        WordPressAuthenticator.fetchOnePasswordCredentials(UIViewController(), sourceView: UIView(), loginFields: loginFields, onePasswordFetcher: onePasswordFetcher) { (credentials) in

            XCTAssertEqual(credentials.username, "username")
            XCTAssertEqual(credentials.password, "knockknock")
            XCTAssertEqual(credentials.multifactorCode, String())
            expect.fulfill()
        }

        waitForExpectations(timeout: timeInterval, handler: nil)
    }
}
