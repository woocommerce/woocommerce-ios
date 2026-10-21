import AuthenticationServices
import Testing
import UIKit
@testable import WordPressAuthenticator

@MainActor
struct TwoFAViewControllerTests {

    @Test
    func test_text_code_when_nonce_info_has_no_sms_nonce_then_requests_code_with_password() throws {
        // Given
        let nonceInfo = SocialLogin2FANonceInfo()
        let (controller, cells) = try makeScreen(password: "password", nonceInfo: nonceInfo)
        let smsCells = cells.compactMap { $0 as? TextLinkButtonTableViewCell }
        let smsCell = try #require(smsCells.first)
        let facade = MockWordPressComOAuthClientFacade(client: "Fake", secret: "Fake")
        controller.loginFacade.wordpressComOAuthClientFacade = facade

        // When
        smsCell.actionHandler?()

        // Then
        #expect(facade.oneTimeCodeRequestCount == 1)
        #expect(facade.socialCodeRequestCount == 0)
    }

    @Test
    func test_text_code_when_nonce_info_has_sms_nonce_then_requests_social_code() throws {
        // Given
        let nonceInfo = SocialLogin2FANonceInfo()
        nonceInfo.nonceSMS = "sms-nonce"
        let (controller, cells) = try makeScreen(password: "password", nonceInfo: nonceInfo)
        let smsCells = cells.compactMap { $0 as? TextLinkButtonTableViewCell }
        let smsCell = try #require(smsCells.first)
        let facade = MockWordPressComOAuthClientFacade(client: "Fake", secret: "Fake")
        controller.loginFacade.wordpressComOAuthClientFacade = facade

        // When
        smsCell.actionHandler?()

        // Then
        #expect(facade.oneTimeCodeRequestCount == 0)
        #expect(facade.socialCodeRequestCount == 1)
        #expect(facade.socialCodeRequestNonce == "sms-nonce")
    }

    @Test
    func test_text_code_when_nonce_info_has_no_sms_nonce_and_no_password_then_requests_social_code() throws {
        // Given
        let nonceInfo = SocialLogin2FANonceInfo()
        let (controller, cells) = try makeScreen(password: "", nonceInfo: nonceInfo)
        let smsCells = cells.compactMap { $0 as? TextLinkButtonTableViewCell }
        let smsCell = try #require(smsCells.first)
        let facade = MockWordPressComOAuthClientFacade(client: "Fake", secret: "Fake")
        controller.loginFacade.wordpressComOAuthClientFacade = facade

        // When
        smsCell.actionHandler?()

        // Then
        #expect(facade.oneTimeCodeRequestCount == 0)
        #expect(facade.socialCodeRequestCount == 1)
    }

    @Test
    func test_security_key_prompt_when_cancelled_then_stays_on_screen() throws {
        // Given
        let (controller, _) = try makeScreen()
        let tableView = try #require(firstSubview(of: UITableView.self, in: controller.view))
        tableView.layoutIfNeeded()
        let navigationController = AlertPresentingNavigationController()
        navigationController.setViewControllers([controller], animated: false)
        controller.configureViewLoading(true)

        // When
        controller.authorizationController(
            controller: makeAuthorizationController(),
            didCompleteWithError: ASAuthorizationError(.canceled)
        )

        // Then
        let codeFields = tableView.visibleCells.compactMap { ($0 as? TextFieldTableViewCell)?.textField }
        let codeField = try #require(codeFields.first)
        #expect(navigationController.presentedController == nil)
        #expect(controller.navigationItem.hidesBackButton == false)
        #expect(codeField.isEnabled)
    }

    @Test
    func test_security_key_prompt_when_other_error_occurs_then_presents_alert() throws {
        // Given
        let (controller, _) = try makeScreen()
        let navigationController = AlertPresentingNavigationController()
        navigationController.setViewControllers([controller], animated: false)
        controller.configureViewLoading(true)

        // When
        controller.authorizationController(
            controller: makeAuthorizationController(),
            didCompleteWithError: NSError(domain: "test", code: 1)
        )

        // Then
        #expect(navigationController.presentedController != nil)
    }

    @Test
    func test_two_factor_options_when_sms_is_not_supported_then_hides_text_link_and_alternate_copy() throws {
        // Given
        let (_, cells) = try makeScreen(supportedAuthTypes: ["backup", "authenticator"])
        let labelTexts = cells.compactMap { firstSubview(of: UILabel.self, in: $0)?.text }

        // When / Then
        #expect(cells.compactMap { $0 as? TextLinkButtonTableViewCell }.isEmpty)
        #expect(!labelTexts.contains(WordPressAuthenticator.shared.displayStrings.twoFactorOtherFormsInstructions))
    }

    @Test
    func test_security_key_mode_when_backup_is_available_then_hides_code_and_enables_security_key_primary_action() throws {
        // Given
        let nonceInfo = SocialLogin2FANonceInfo()
        nonceInfo.nonceWebauthn = "webauthn-nonce"
        let (controller, cells) = try makeScreen(nonceInfo: nonceInfo, supportedAuthTypes: ["webauthn", "backup"])
        let button = try #require(controller.submitButton)
        controller.configureSubmitButton(animating: false)

        // When / Then
        #expect(cells.compactMap { $0 as? TextFieldTableViewCell }.isEmpty)
        #expect(button.title(for: .normal) == WordPressAuthenticator.shared.displayStrings.securityKeyButtonTitle)
        #expect(button.title(for: .highlighted) == WordPressAuthenticator.shared.displayStrings.securityKeyButtonTitle)
        #expect(button.accessibilityIdentifier == "Continue Button")
        #expect(button.isEnabled)
        #expect(cells.compactMap { $0 as? TextLinkButtonTableViewCell }.count == 1)
    }

    @Test
    func test_use_backup_code_when_backup_link_is_tapped_then_shows_backup_instructions_and_code_field() throws {
        // Given
        let nonceInfo = SocialLogin2FANonceInfo()
        nonceInfo.nonceWebauthn = "webauthn-nonce"
        let (controller, cells) = try makeScreen(nonceInfo: nonceInfo, supportedAuthTypes: ["webauthn", "backup"])
        let links = cells.compactMap { $0 as? TextLinkButtonTableViewCell }
        let backupLink = try #require(links.first)

        // When
        backupLink.actionHandler?()
        let tableView: UITableView = try #require(firstSubview(of: UITableView.self, in: controller.view))
        let updatedCells = (0..<controller.tableView(tableView, numberOfRowsInSection: 0)).map {
            controller.tableView(tableView, cellForRowAt: IndexPath(row: $0, section: 0))
        }
        let codeFields = updatedCells.compactMap { ($0 as? TextFieldTableViewCell)?.textField }
        let codeField = try #require(codeFields.first)
        let instructionLabels = updatedCells.compactMap { firstSubview(of: UILabel.self, in: $0) }

        // Then
        #expect(instructionLabels.first?.text == "Enter a backup code to continue.")
        #expect(codeField.isEnabled)
        #expect(updatedCells.compactMap { $0 as? TextLinkButtonTableViewCell }.count == 1)
        #expect(controller.submitButton?.title(for: .normal) == WordPressAuthenticator.shared.displayStrings.continueButtonTitle)
    }

    @Test
    func test_security_key_prompt_when_cancelled_in_security_key_mode_then_primary_button_is_enabled() throws {
        // Given
        let nonceInfo = SocialLogin2FANonceInfo()
        nonceInfo.nonceWebauthn = "webauthn-nonce"
        let (controller, _) = try makeScreen(nonceInfo: nonceInfo, supportedAuthTypes: ["webauthn", "backup"])
        let button = try #require(controller.submitButton)
        let navigationController = AlertPresentingNavigationController()
        navigationController.setViewControllers([controller], animated: false)
        controller.configureViewLoading(true)

        // When
        controller.authorizationController(
            controller: makeAuthorizationController(),
            didCompleteWithError: ASAuthorizationError(.canceled)
        )

        // Then
        #expect(navigationController.presentedController == nil)
        #expect(button.isEnabled)
    }

    @Test
    func test_backup_link_when_loading_then_stays_disabled_and_does_not_switch_modes() throws {
        // Given
        let nonceInfo = SocialLogin2FANonceInfo()
        nonceInfo.nonceWebauthn = "webauthn-nonce"
        let (controller, _) = try makeScreen(nonceInfo: nonceInfo, supportedAuthTypes: ["webauthn", "backup"])
        controller.configureViewLoading(true)
        let tableView: UITableView = try #require(firstSubview(of: UITableView.self, in: controller.view))
        let rows = (0..<controller.tableView(tableView, numberOfRowsInSection: 0)).map {
            controller.tableView(tableView, cellForRowAt: IndexPath(row: $0, section: 0))
        }
        let links = rows.compactMap { $0 as? TextLinkButtonTableViewCell }
        let backupLink = try #require(links.first)
        let button = try #require(firstSubview(of: UIButton.self, in: backupLink))

        // When
        backupLink.actionHandler?()

        // Then
        #expect(!button.isEnabled)
        let updatedCells = (0..<controller.tableView(tableView, numberOfRowsInSection: 0)).map {
            controller.tableView(tableView, cellForRowAt: IndexPath(row: $0, section: 0))
        }
        #expect(updatedCells.compactMap { $0 as? TextFieldTableViewCell }.isEmpty)
    }

    @Test
    func test_text_code_when_requested_without_method_list_then_shows_text_message_instructions() throws {
        // Given
        let (controller, cells) = try makeScreen(password: "password")
        let links = cells.compactMap { $0 as? TextLinkButtonTableViewCell }
        let smsLink = try #require(links.first)
        let facade = MockWordPressComOAuthClientFacade(client: "Fake", secret: "Fake")
        controller.loginFacade.wordpressComOAuthClientFacade = facade
        let tableView: UITableView = try #require(firstSubview(of: UITableView.self, in: controller.view))

        // When
        smsLink.actionHandler?()
        let instructionCell = controller.tableView(tableView, cellForRowAt: IndexPath(row: 0, section: 0))
        let instructionLabel = try #require(firstSubview(of: UILabel.self, in: instructionCell))

        // Then
        #expect(facade.oneTimeCodeRequestCount == 1)
        #expect(instructionLabel.text == "We sent a text message. Enter the verification code from the message.")
    }

    @Test
    func test_text_code_when_code_was_typed_then_keeps_the_typed_code() throws {
        // Given
        let (controller, _) = try makeScreen(password: "password")
        controller.loginFacade.wordpressComOAuthClientFacade = MockWordPressComOAuthClientFacade(client: "Fake", secret: "Fake")
        let tableView = try #require(firstSubview(of: UITableView.self, in: controller.view))
        tableView.layoutIfNeeded()
        let codeFields = tableView.visibleCells.compactMap { ($0 as? TextFieldTableViewCell)?.textField }
        let codeField = try #require(codeFields.first)
        codeField.text = "123456"
        let smsLinks = tableView.visibleCells.compactMap { $0 as? TextLinkButtonTableViewCell }
        let smsLink = try #require(smsLinks.first)

        // When
        smsLink.actionHandler?()
        tableView.layoutIfNeeded()

        // Then
        let updatedCodeFields = tableView.visibleCells.compactMap { ($0 as? TextFieldTableViewCell)?.textField }
        #expect(updatedCodeFields.first?.text == "123456")
    }

    private func makeAuthorizationController() -> ASAuthorizationController {
        let request = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: "wordpress.com")
            .createCredentialAssertionRequest(challenge: Data())
        return ASAuthorizationController(authorizationRequests: [request])
    }

    private func makeScreen(
        password: String = "",
        nonceInfo: SocialLogin2FANonceInfo? = nil,
        supportedAuthTypes: [String] = []
    ) throws -> (TwoFAViewController, [UITableViewCell]) {
        WordPressAuthenticator.initializeForTesting()
        let controller = try #require(TwoFAViewController.instantiate(from: .twoFA))
        controller.loginFields.password = password
        controller.loginFields.nonceInfo = nonceInfo
        controller.loginFields.supportedAuthTypes = supportedAuthTypes
        controller.loadViewIfNeeded()

        let tableView = try #require(firstSubview(of: UITableView.self, in: controller.view))
        let cells = (0..<controller.tableView(tableView, numberOfRowsInSection: 0)).map {
            controller.tableView(tableView, cellForRowAt: IndexPath(row: $0, section: 0))
        }
        return (controller, cells)
    }

    private func firstSubview<View: UIView>(of type: View.Type, in view: UIView) -> View? {
        if let match = view as? View {
            return match
        }
        return view.subviews.lazy.compactMap { firstSubview(of: type, in: $0) }.first
    }
}

@MainActor
private final class AlertPresentingNavigationController: UINavigationController {
    private(set) var presentedController: UIViewController?

    override func present(_ viewControllerToPresent: UIViewController, animated: Bool, completion: (() -> Void)?) {
        presentedController = viewControllerToPresent
    }
}
