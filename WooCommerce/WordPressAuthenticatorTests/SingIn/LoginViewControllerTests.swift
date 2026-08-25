@testable import WordPressAuthenticator
import WordPressUI
import XCTest

class LoginViewControllerTests: XCTestCase {
    private var retainedWindows = [UIWindow]()

    // showSignupEpilogue with loginFields.meta.appleUser set will pass SocialService.apple to
    // the delegate
    func testShowingSignupEpilogueWithGoogleUser() throws {
        WordPressAuthenticator.initializeForTesting()
        let delegateSpy = WordPressAuthenticatorDelegateSpy()
        WordPressAuthenticator.shared.delegate = delegateSpy

        // This might be unnecessary because delegateSpy should be deallocated once the test method finished.
        // Leaving it here, just in case.
        addTeardownBlock {
            WordPressAuthenticator.shared.delegate = nil
        }

        let sut = LoginViewController()
        // We need to embed the SUT in a navigation controller because it expects its
        // navigationController property to not be nil.
        _ = UINavigationController(rootViewController: sut)

        sut.loginFields.meta.socialUser = SocialUser(email: "test@email.com", fullName: "Full Name", service: .google)

        sut.showSignupEpilogue(for: AuthenticatorCredentials())

        let service = try XCTUnwrap(delegateSpy.socialUser?.service)
        guard case .google = service else {
            return XCTFail("Expected Google social service, got \(service) instead")
        }
    }

    func test_site_credentials_controller_when_login_moves_to_admin_recovery_then_uses_normalized_login_and_cancel_preserves_credentials() throws {
        // Given
        let delegate = WordPressAuthenticatorDelegateSpy()
        delegate.siteCredentialRecoveries = [
            .login(draftURL: "https://example.com/wp-login.php", error: nil),
            .admin(
                verifiedLoginURL: "https://example.com/normalized-login",
                draftURL: "https://example.com/private-admin/",
                error: nil
            )
        ]
        let controller = try makeSiteCredentialsController(delegate: delegate)

        // When
        try tapContinue(in: controller)

        // Then
        var cells = try renderedCells(in: controller)
        XCTAssertEqual(cells.count, 5)
        XCTAssertEqual(labelText(in: cells[0]), "Where do you sign in to your store?")
        XCTAssertTrue(try XCTUnwrap(label(in: cells[0])).accessibilityTraits.contains(.header))
        XCTAssertFalse(try XCTUnwrap(label(in: cells[1])).accessibilityTraits.contains(.header))
        XCTAssertEqual((cells[2] as? TextFieldTableViewCell)?.textField.text, "https://example.com/wp-login.php")
        XCTAssertEqual(delegate.presentedSiteCredentialBrowserAlternativeCount, 0)

        // When
        try XCTUnwrap((cells[3] as? TextLinkButtonTableViewCell)?.actionHandler)()
        edit(try XCTUnwrap(cells[2] as? TextFieldTableViewCell), text: "https://example.com/custom-login")
        try tapContinue(in: controller)

        // Then
        XCTAssertEqual(delegate.presentedSiteCredentialBrowserAlternativeCount, 1)
        let loginRequest = try XCTUnwrap(delegate.siteCredentialAuthenticationRequests.last)
        XCTAssertEqual(loginRequest.loginURL, "https://example.com/custom-login")
        XCTAssertEqual(loginRequest.endpointUnderVerification, .login)
        cells = try renderedCells(in: controller)
        XCTAssertEqual(labelText(in: cells[0]), "Where is your store’s dashboard?")
        XCTAssertEqual((cells[2] as? TextFieldTableViewCell)?.textField.text, "https://example.com/private-admin/")

        // When
        edit(try XCTUnwrap(cells[2] as? TextFieldTableViewCell), text: "https://example.com/custom-admin")
        delegate.siteCredentialRecoveries.append(.admin(
            verifiedLoginURL: "https://example.com/normalized-login",
            draftURL: "https://example.com/custom-admin/",
            error: .notFound
        ))
        try tapContinue(in: controller)

        // Then
        let adminRequest = try XCTUnwrap(delegate.siteCredentialAuthenticationRequests.last)
        XCTAssertEqual(adminRequest.loginURL, "https://example.com/normalized-login")
        XCTAssertEqual(adminRequest.adminURL, "https://example.com/custom-admin")
        XCTAssertEqual(adminRequest.endpointUnderVerification, .admin)

        // When
        cells = try renderedCells(in: controller)
        try XCTUnwrap((cells[5] as? TextLinkButtonTableViewCell)?.actionHandler)()
        delegate.siteCredentialFailure = (
            NSError(domain: "Authentication", code: 500),
            false,
            nil
        )
        try tapContinue(in: controller)

        // Then
        cells = try renderedCells(in: controller)
        XCTAssertEqual((cells[1] as? TextFieldTableViewCell)?.textField.text, "merchant")
        XCTAssertEqual((cells[2] as? TextFieldTableViewCell)?.textField.text, "secret")
        let credentialRequest = try XCTUnwrap(delegate.siteCredentialAuthenticationRequests.last)
        XCTAssertEqual(credentialRequest.credentials.password, "secret")
        XCTAssertEqual(credentialRequest.loginURL, "https://example.com/normalized-login")
        XCTAssertNil(credentialRequest.adminURL)
        XCTAssertEqual(delegate.presentedSiteCredentialFailureOffersBrowserAlternative, false)
    }

    func test_site_credentials_controller_when_invalid_draft_is_edited_then_clears_error_without_replacing_url_cell() throws {
        // Given
        let delegate = WordPressAuthenticatorDelegateSpy()
        delegate.siteCredentialRecoveries = [
            .login(draftURL: "https://example.com/wp-login.php", error: nil),
            .login(draftURL: "not-a-url", error: .invalidURL)
        ]
        let controller = try makeSiteCredentialsController(delegate: delegate)
        try tapContinue(in: controller)
        var cells = try renderedCells(in: controller)
        edit(try XCTUnwrap(cells[2] as? TextFieldTableViewCell), text: "not-a-url")

        // When
        try tapContinue(in: controller)

        // Then
        cells = try renderedCells(in: controller)
        XCTAssertEqual(cells.count, 6)
        XCTAssertEqual(labelText(in: cells[3]), "Enter a full web address, including http:// or https://.")
        XCTAssertEqual(delegate.presentedSiteCredentialBrowserAlternativeCount, 0)

        // When
        try XCTUnwrap((cells[4] as? TextLinkButtonTableViewCell)?.actionHandler)()

        // Then
        XCTAssertEqual(delegate.presentedSiteCredentialBrowserAlternativeCount, 1)
        let urlCell = try XCTUnwrap(cells[2] as? TextFieldTableViewCell)
        XCTAssertTrue(urlCell.textField.becomeFirstResponder())

        // When
        urlCell.textField.text = "https://example.com/edited-login"
        let cursor = try XCTUnwrap(urlCell.textField.position(from: urlCell.textField.beginningOfDocument, offset: 12))
        urlCell.textField.selectedTextRange = urlCell.textField.textRange(from: cursor, to: cursor)
        urlCell.registerTextFieldAction()

        // Then
        cells = try renderedCells(in: controller)
        XCTAssertEqual(cells.count, 5)
        XCTAssertTrue(cells[2] === urlCell)
        XCTAssertEqual(urlCell.textField.text, "https://example.com/edited-login")
        XCTAssertTrue(urlCell.textField.isFirstResponder)
        XCTAssertEqual(
            urlCell.textField.offset(
                from: urlCell.textField.beginningOfDocument,
                to: try XCTUnwrap(urlCell.textField.selectedTextRange?.start)
            ),
            12
        )
    }

    func test_site_credentials_controller_when_recovery_is_toggled_then_accessibility_elements_follow_visible_field() throws {
        // Given
        let delegate = WordPressAuthenticatorDelegateSpy()
        delegate.siteCredentialRecoveries = [.login(draftURL: "https://example.com/wp-login.php", error: nil)]
        let controller = try makeSiteCredentialsController(delegate: delegate)
        let credentialCells = try renderedCells(in: controller)
        let originalUsernameField = try XCTUnwrap((credentialCells[1] as? TextFieldTableViewCell)?.textField)
        var accessibilityElements = try XCTUnwrap(controller.view.accessibilityElements as? [UIView])
        XCTAssertTrue(accessibilityElements.first === originalUsernameField)

        // When
        try tapContinue(in: controller)

        // Then
        let recoveryCells = try renderedCells(in: controller)
        let recoveryURLField = try XCTUnwrap((recoveryCells[2] as? TextFieldTableViewCell)?.textField)
        accessibilityElements = try XCTUnwrap(controller.view.accessibilityElements as? [UIView])
        XCTAssertTrue(accessibilityElements.first === recoveryURLField)
        XCTAssertFalse(accessibilityElements.contains { $0 === originalUsernameField })

        // When
        try XCTUnwrap((recoveryCells[4] as? TextLinkButtonTableViewCell)?.actionHandler)()

        // Then
        let restoredCredentialCells = try renderedCells(in: controller)
        let restoredUsernameField = try XCTUnwrap((restoredCredentialCells[1] as? TextFieldTableViewCell)?.textField)
        accessibilityElements = try XCTUnwrap(controller.view.accessibilityElements as? [UIView])
        XCTAssertTrue(accessibilityElements.first === restoredUsernameField)
        XCTAssertEqual(accessibilityElements.count, 3)
    }

    func test_site_credentials_controller_when_recovery_has_generic_failure_then_keeps_explicit_browser_action_only() throws {
        // Given
        let delegate = WordPressAuthenticatorDelegateSpy()
        delegate.siteCredentialRecoveries = [.login(draftURL: "https://example.com/wp-login.php", error: nil)]
        let controller = try makeSiteCredentialsController(delegate: delegate)
        try tapContinue(in: controller)
        delegate.siteCredentialFailure = (
            NSError(domain: "Authentication", code: 500),
            false,
            nil
        )

        // When
        try tapContinue(in: controller)

        // Then
        let cells = try renderedCells(in: controller)
        XCTAssertEqual(cells.count, 5)
        XCTAssertEqual(delegate.presentedSiteCredentialFailureCount, 1)
        XCTAssertEqual(delegate.presentedSiteCredentialFailureOffersBrowserAlternative, false)
        XCTAssertEqual(delegate.presentedSiteCredentialBrowserAlternativeCount, 0)

        // When
        try XCTUnwrap((cells[3] as? TextLinkButtonTableViewCell)?.actionHandler)()

        // Then
        XCTAssertEqual(delegate.presentedSiteCredentialBrowserAlternativeCount, 1)
    }

    func test_site_credentials_controller_when_verified_credential_response_fails_then_retains_login_and_offers_browser() throws {
        // Given
        let delegate = WordPressAuthenticatorDelegateSpy()
        delegate.siteCredentialRecoveries = [.login(draftURL: "https://example.com/wp-login.php", error: nil)]
        let controller = try makeSiteCredentialsController(delegate: delegate)
        try tapContinue(in: controller)
        let recoveryCells = try renderedCells(in: controller)
        edit(try XCTUnwrap(recoveryCells[2] as? TextFieldTableViewCell), text: "https://example.com/custom-login")
        delegate.siteCredentialFailure = (
            NSError(domain: "Authentication", code: -1),
            false,
            "https://example.com/custom-login"
        )
        delegate.siteCredentialFailureOffersBrowserAlternative = true

        // When
        try tapContinue(in: controller)

        // Then
        let cells = try renderedCells(in: controller)
        XCTAssertEqual((cells[1] as? TextFieldTableViewCell)?.textField.text, "merchant")
        XCTAssertEqual((cells[2] as? TextFieldTableViewCell)?.textField.text, "secret")
        XCTAssertEqual(delegate.presentedSiteCredentialFailureOffersBrowserAlternative, true)
        XCTAssertEqual(delegate.presentedSiteCredentialBrowserAlternativeCount, 0)

        delegate.defersSiteCredentialAuthentication = true
        try tapContinue(in: controller)
        let retry = try XCTUnwrap(delegate.siteCredentialAuthenticationRequests.last)
        XCTAssertEqual(retry.loginURL, "https://example.com/custom-login")
        XCTAssertNil(retry.endpointUnderVerification)
    }

    func test_site_credentials_controller_when_login_recovery_error_changes_then_copies_each_inline_error_independently() throws {
        // Given
        let delegate = WordPressAuthenticatorDelegateSpy()
        delegate.siteCredentialRecoveries = [
            .login(draftURL: "https://other.example/login", error: .differentSite),
            .login(draftURL: "https://example.com/missing-login", error: .notFound)
        ]
        let controller = try makeSiteCredentialsController(delegate: delegate)

        // When
        try tapContinue(in: controller)

        // Then
        var cells = try renderedCells(in: controller)
        XCTAssertEqual(
            labelText(in: cells[3]),
            "Enter an address on the same site without changing its secure connection or port."
        )

        // When
        edit(try XCTUnwrap(cells[2] as? TextFieldTableViewCell), text: "https://example.com/missing-login")
        try tapContinue(in: controller)

        // Then
        cells = try renderedCells(in: controller)
        XCTAssertEqual(
            labelText(in: cells[3]),
            "We couldn’t find a WordPress sign-in page at that address. Check it and try again."
        )
    }

    func test_site_credentials_controller_when_recovery_is_loading_then_disables_all_actions_until_loading_finishes() throws {
        // Given
        let delegate = WordPressAuthenticatorDelegateSpy()
        delegate.siteCredentialRecoveries = [.login(draftURL: "https://example.com/wp-login.php", error: nil)]
        let controller = try makeSiteCredentialsController(delegate: delegate)
        try tapContinue(in: controller)
        let cells = try renderedCells(in: controller)
        let urlField = try XCTUnwrap((cells[2] as? TextFieldTableViewCell)?.textField)
        let browserButton = try XCTUnwrap(button(in: cells[3]))
        let cancelButton = try XCTUnwrap(button(in: cells[4]))
        delegate.defersSiteCredentialAuthentication = true

        // When
        try tapContinue(in: controller)

        // Then
        XCTAssertFalse(urlField.isEnabled)
        XCTAssertEqual(controller.submitButton?.isEnabled, false)
        XCTAssertFalse(browserButton.isEnabled)
        XCTAssertFalse(cancelButton.isEnabled)

        // When
        delegate.siteCredentialAuthenticationLoadingHandler?(false)

        // Then
        XCTAssertTrue(urlField.isEnabled)
        XCTAssertEqual(controller.submitButton?.isEnabled, true)
        XCTAssertTrue(browserButton.isEnabled)
        XCTAssertTrue(cancelButton.isEnabled)
    }

    func test_site_credentials_controller_when_ordinary_failure_occurs_then_preserves_manual_handling_configuration() throws {
        // Given
        let inlineDelegate = WordPressAuthenticatorDelegateSpy()
        inlineDelegate.siteCredentialFailure = (
            NSError(domain: "Authentication", code: 401),
            true,
            nil
        )
        let inlineController = try makeSiteCredentialsController(delegate: inlineDelegate, manualErrorHandling: false)

        // When
        try tapContinue(in: inlineController)

        // Then
        let inlineCells = try renderedCells(in: inlineController)
        XCTAssertEqual(
            labelText(in: inlineCells[3]),
            "It looks like this username/password isn't associated with this site."
        )
        XCTAssertEqual(inlineDelegate.presentedSiteCredentialFailureCount, 0)

        // Given
        let manualDelegate = WordPressAuthenticatorDelegateSpy()
        manualDelegate.siteCredentialFailure = (
            NSError(domain: "Authentication", code: 500),
            false,
            nil
        )
        let manualController = try makeSiteCredentialsController(delegate: manualDelegate, manualErrorHandling: true)

        // When
        try tapContinue(in: manualController)

        // Then
        XCTAssertEqual(manualDelegate.presentedSiteCredentialFailureCount, 1)
        XCTAssertEqual(manualDelegate.presentedSiteCredentialFailureOffersBrowserAlternative, false)
        XCTAssertEqual(manualDelegate.presentedSiteCredentialBrowserAlternativeCount, 0)
    }

    func test_site_credentials_controller_when_manual_handling_is_disabled_and_general_failure_occurs_then_shows_existing_error_ui() throws {
        // Given
        let testBundlePath = Bundle(for: LoginViewControllerTests.self).bundlePath
        setenv("PACKAGE_RESOURCE_BUNDLE_PATH", testBundlePath, 1)
        addTeardownBlock { unsetenv("PACKAGE_RESOURCE_BUNDLE_PATH") }
        let delegate = WordPressAuthenticatorDelegateSpy()
        delegate.siteCredentialFailure = (
            NSError(
                domain: "Authentication",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Server failure"]
            ),
            false,
            nil
        )
        let controller = try makeSiteCredentialsController(delegate: delegate, manualErrorHandling: false)

        // When
        try tapContinue(in: controller)

        // Then
        XCTAssertTrue(controller.navigationController?.presentedViewController is FancyAlertViewController)
        XCTAssertEqual(delegate.presentedSiteCredentialFailureCount, 0)
    }

    func test_site_credentials_controller_when_admin_recovery_has_invalid_credentials_then_returns_to_visible_credentials_error() throws {
        // Given
        let delegate = WordPressAuthenticatorDelegateSpy()
        delegate.siteCredentialRecoveries = [
            .admin(
                verifiedLoginURL: "https://example.com/normalized-login",
                draftURL: "https://example.com/unverified-admin/",
                error: nil
            )
        ]
        let controller = try makeSiteCredentialsController(delegate: delegate, manualErrorHandling: false)
        try tapContinue(in: controller)
        delegate.siteCredentialFailure = (
            NSError(domain: "Authentication", code: 401),
            true,
            "https://example.com/normalized-login"
        )
        delegate.siteCredentialFailureOffersBrowserAlternative = true

        // When
        try tapContinue(in: controller)

        // Then
        var cells = try renderedCells(in: controller)
        XCTAssertEqual(cells.count, 5)
        XCTAssertEqual((cells[1] as? TextFieldTableViewCell)?.textField.text, "merchant")
        XCTAssertEqual((cells[2] as? TextFieldTableViewCell)?.textField.text, "secret")
        XCTAssertEqual(
            labelText(in: cells[3]),
            "It looks like this username/password isn't associated with this site."
        )

        // When
        delegate.defersSiteCredentialAuthentication = true
        try tapContinue(in: controller)

        // Then
        cells = try renderedCells(in: controller)
        XCTAssertEqual(cells.count, 4)
        let retry = try XCTUnwrap(delegate.siteCredentialAuthenticationRequests.last)
        XCTAssertEqual(retry.loginURL, "https://example.com/normalized-login")
        XCTAssertNil(retry.adminURL)
        XCTAssertNil(retry.endpointUnderVerification)
    }

    func test_site_credentials_controller_when_authentication_succeeds_then_completion_receives_normalized_endpoint_options() throws {
        // Given
        let delegate = WordPressAuthenticatorDelegateSpy()
        delegate.siteCredentialCredentialsToReturn = WordPressOrgCredentials(
            username: "merchant",
            password: "secret",
            xmlrpc: "https://example.com/xmlrpc.php",
            options: [
                "login_url": ["value": "https://example.com/normalized-login"],
                "admin_url": ["value": "https://example.com/normalized-admin/"]
            ]
        )
        var completedCredentials: WordPressOrgCredentials?
        let controller = try makeSiteCredentialsController(delegate: delegate) {
            completedCredentials = $0
        }

        // When
        try tapContinue(in: controller)

        // Then
        let options = try XCTUnwrap(completedCredentials?.options)
        XCTAssertEqual(
            (options["login_url"] as? [String: String])?["value"],
            "https://example.com/normalized-login"
        )
        XCTAssertEqual(
            (options["admin_url"] as? [String: String])?["value"],
            "https://example.com/normalized-admin/"
        )
    }
}

private extension LoginViewControllerTests {
    func makeSiteCredentialsController(delegate: WordPressAuthenticatorDelegateSpy,
                                       manualErrorHandling: Bool = true,
                                       onCompletion: @escaping (WordPressOrgCredentials) -> Void = { _ in }) throws -> SiteCredentialsViewController {
        WordPressAuthenticator.initializeForTesting()
        WordPressAuthenticator.shared.delegate = delegate
        addTeardownBlock { WordPressAuthenticator.shared.delegate = nil }
        let configuration = WordPressAuthenticatorConfiguration(
            wpcomClientId: "a",
            wpcomSecret: "b",
            wpcomScheme: "c",
            wpcomTermsOfServiceURL: try XCTUnwrap(URL(string: "https://w.org")),
            googleLoginClientId: "e",
            googleLoginServerClientId: "f",
            googleLoginScheme: "g",
            userAgent: "h",
            enableManualSiteCredentialLogin: true,
            enableManualErrorHandlingForSiteCredentialLogin: manualErrorHandling
        )
        let controller = try XCTUnwrap(SiteCredentialsViewController.instantiate(from: .siteAddress) { coder in
            SiteCredentialsViewController(
                coder: coder,
                isDismissible: true,
                configuration: configuration,
                onCompletion: onCompletion
            )
        })
        controller.loadViewIfNeeded()
        controller.loginFields.siteAddress = "https://example.com"
        controller.loginFields.username = "merchant"
        controller.loginFields.password = "secret"
        controller.configureSubmitButton(animating: false)
        let navigationController = UINavigationController(rootViewController: controller)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = navigationController
        window.isHidden = false
        retainedWindows.append(window)
        navigationController.view.layoutIfNeeded()
        return controller
    }

    func renderedCells(in controller: SiteCredentialsViewController) throws -> [UITableViewCell] {
        let tableView: UITableView = try XCTUnwrap(firstSubview(in: controller.view))
        tableView.layoutIfNeeded()
        return (0..<controller.tableView(tableView, numberOfRowsInSection: 0)).map {
            let indexPath = IndexPath(row: $0, section: 0)
            return tableView.cellForRow(at: indexPath) ?? controller.tableView(tableView, cellForRowAt: indexPath)
        }
    }

    func firstSubview<View: UIView>(in view: UIView) -> View? {
        if let view = view as? View { return view }
        for subview in view.subviews {
            if let match: View = firstSubview(in: subview) { return match }
        }
        return nil
    }

    func label(in cell: UITableViewCell) -> UILabel? {
        firstSubview(in: cell.contentView)
    }

    func labelText(in cell: UITableViewCell) -> String? {
        label(in: cell)?.text
    }

    func button(in cell: UITableViewCell) -> UIButton? {
        firstSubview(in: cell.contentView)
    }

    func edit(_ cell: TextFieldTableViewCell, text: String) {
        cell.textField.text = text
        cell.registerTextFieldAction()
    }

    func tapContinue(in controller: SiteCredentialsViewController) throws {
        controller.handleContinueButtonTapped(try XCTUnwrap(controller.submitButton))
    }
}
