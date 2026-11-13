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
        let (controller, cells) = try makeScreen(password: "password", nonceInfo: nonceInfo, supportedAuthTypes: ["sms"])
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
        let (controller, cells) = try makeScreen(password: "password", nonceInfo: nonceInfo, supportedAuthTypes: ["sms"])
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
        nonceInfo.supportedAuthTypes = ["sms"]
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
        let (_, cells) = try makeScreen(supportedAuthTypes: ["authenticator"])
        let labelTexts = cells.compactMap { firstSubview(of: UILabel.self, in: $0)?.text }

        // When / Then
        #expect(cells.compactMap { $0 as? TextLinkButtonTableViewCell }.isEmpty)
        #expect(!labelTexts.contains(WordPressAuthenticator.shared.displayStrings.twoFactorOtherFormsInstructions))
    }

    @Test
    func test_two_factor_options_when_social_challenge_lists_sms_then_shows_text_link() throws {
        // Given
        let nonceInfo = SocialLogin2FANonceInfo()
        nonceInfo.supportedAuthTypes = ["authenticator", "sms"]

        // When
        let (_, cells) = try makeScreen(nonceInfo: nonceInfo)

        // Then
        let linkTitles = cells.compactMap { $0 as? TextLinkButtonTableViewCell }.compactMap {
            firstSubview(of: UIButton.self, in: $0)?.title(for: .normal)
        }
        #expect(linkTitles == [WordPressAuthenticator.shared.displayStrings.textCodeButtonTitle])
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
        let (controller, _) = try makeScreen(nonceInfo: nonceInfo, supportedAuthTypes: ["webauthn", "backup"])
        let tableView = try #require(firstSubview(of: UITableView.self, in: controller.view))
        tableView.layoutIfNeeded()
        let links = tableView.visibleCells.compactMap { $0 as? TextLinkButtonTableViewCell }
        let backupLink = try #require(links.first {
            firstSubview(of: UIButton.self, in: $0)?.title(for: .normal) == "Use a backup code instead"
        })

        // When
        backupLink.actionHandler?()
        tableView.layoutIfNeeded()

        // Then
        let instructionCell = try #require(tableView.cellForRow(at: IndexPath(row: 0, section: 0)))
        let codeCell = try #require(tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? TextFieldTableViewCell)
        let instructionLabel = try #require(firstSubview(of: UILabel.self, in: instructionCell))
        let displayedLinks = tableView.indexPathsForVisibleRows?.sorted { $0.row < $1.row }.compactMap {
            tableView.cellForRow(at: $0) as? TextLinkButtonTableViewCell
        } ?? []
        let linkTitles = displayedLinks.compactMap { firstSubview(of: UIButton.self, in: $0)?.title(for: .normal) }
        #expect(instructionLabel.text == "Enter a backup code to continue.")
        #expect(codeCell.textField.isEnabled)
        #expect(linkTitles == [WordPressAuthenticator.shared.displayStrings.securityKeyButtonTitle])
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
    func test_text_code_when_requested_then_shows_text_message_instructions() throws {
        // Given
        let (controller, cells) = try makeScreen(password: "password", supportedAuthTypes: ["authenticator", "sms"])
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
        let (controller, _) = try makeScreen(password: "password", supportedAuthTypes: ["sms"])
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

    @Test
    func test_use_backup_code_when_tapped_in_code_mode_then_shows_backup_instructions_hides_link_and_keeps_typed_code() throws {
        // Given
        let (controller, _) = try makeScreen(supportedAuthTypes: ["backup", "authenticator"])
        let tableView = try #require(firstSubview(of: UITableView.self, in: controller.view))
        tableView.layoutIfNeeded()
        let codeCell = try #require(tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? TextFieldTableViewCell)
        let codeField = try #require(codeCell.textField)
        codeField.text = "12345678"
        let backupLinks = tableView.visibleCells.compactMap { $0 as? TextLinkButtonTableViewCell }
        let backupLink = try #require(backupLinks.first)

        // When
        backupLink.actionHandler?()
        tableView.layoutIfNeeded()

        // Then
        let instructionCell = try #require(tableView.cellForRow(at: IndexPath(row: 0, section: 0)))
        let updatedCodeCell = try #require(tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? TextFieldTableViewCell)
        let instructionLabel = try #require(firstSubview(of: UILabel.self, in: instructionCell))
        #expect(instructionLabel.text == "Enter a backup code to continue.")
        #expect(tableView.visibleCells.compactMap { $0 as? TextLinkButtonTableViewCell }.isEmpty)
        #expect(updatedCodeCell.textField === codeField)
        #expect(updatedCodeCell.textField.text == "12345678")
    }

    @Test
    func test_text_code_when_backup_code_was_requested_then_shows_text_message_instructions_and_all_options_in_order() throws {
        // Given
        let nonceInfo = SocialLogin2FANonceInfo()
        nonceInfo.nonceWebauthn = "webauthn-nonce"
        let (controller, _) = try makeScreen(password: "password",
                                             nonceInfo: nonceInfo,
                                             supportedAuthTypes: ["backup", "authenticator", "sms"])
        controller.loginFacade.wordpressComOAuthClientFacade = MockWordPressComOAuthClientFacade(client: "Fake", secret: "Fake")
        let tableView = try #require(firstSubview(of: UITableView.self, in: controller.view))
        tableView.layoutIfNeeded()
        let codeCell = try #require(tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? TextFieldTableViewCell)
        let codeField = try #require(codeCell.textField)
        codeField.text = "12345678"
        let links = tableView.visibleCells.compactMap { $0 as? TextLinkButtonTableViewCell }
        let displayStrings = WordPressAuthenticator.shared.displayStrings
        let smsLink = try #require(links.first {
            firstSubview(of: UIButton.self, in: $0)?.title(for: .normal) == displayStrings.textCodeButtonTitle
        })
        let backupLink = try #require(links.first {
            firstSubview(of: UIButton.self, in: $0)?.title(for: .normal) == "Use a backup code instead"
        })
        backupLink.actionHandler?()

        // When
        smsLink.actionHandler?()
        tableView.layoutIfNeeded()

        // Then
        let instructionCell = try #require(tableView.cellForRow(at: IndexPath(row: 0, section: 0)))
        let updatedCodeCell = try #require(tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? TextFieldTableViewCell)
        let instructionLabel = try #require(firstSubview(of: UILabel.self, in: instructionCell))
        let displayedLinks = (tableView.indexPathsForVisibleRows ?? []).sorted { $0.row < $1.row }.compactMap {
            tableView.cellForRow(at: $0) as? TextLinkButtonTableViewCell
        }
        let linkTitles = displayedLinks.compactMap {
            firstSubview(of: UIButton.self, in: $0)?.title(for: .normal)
        }
        #expect(instructionLabel.text == "We sent a text message. Enter the verification code from the message.")
        #expect(linkTitles == ["Resend code via SMS", "Use a backup code instead", displayStrings.securityKeyButtonTitle])
        #expect(updatedCodeCell.textField === codeField)
        #expect(updatedCodeCell.textField.text == "12345678")
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
