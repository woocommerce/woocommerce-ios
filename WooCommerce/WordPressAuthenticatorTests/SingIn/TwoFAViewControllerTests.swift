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

    private func makeAuthorizationController() -> ASAuthorizationController {
        let request = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: "wordpress.com")
            .createCredentialAssertionRequest(challenge: Data())
        return ASAuthorizationController(authorizationRequests: [request])
    }

    private func makeScreen(
        password: String = "",
        nonceInfo: SocialLogin2FANonceInfo? = nil
    ) throws -> (TwoFAViewController, [UITableViewCell]) {
        WordPressAuthenticator.initializeForTesting()
        let controller = try #require(TwoFAViewController.instantiate(from: .twoFA))
        controller.loginFields.password = password
        controller.loginFields.nonceInfo = nonceInfo
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
