import Testing
@testable import WooCommerce
@testable import WordPressAuthenticator

@MainActor
struct WPComLoginCoordinatorTests {
    @Test
    func test_password_login_failure_when_credentials_are_incorrect_then_shows_the_server_error_message() async throws {
        // Given
        let navigationController = UINavigationController()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        defer { window.isHidden = true }

        let accountService = MockWordPressComAccountService()
        accountService.shouldReturnPasswordlessAccount = false
        let coordinator = WPComLoginCoordinator(
            flow: .jetpackSetup(requiresConnectionOnly: false),
            navigationController: navigationController,
            stores: MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false)),
            accountService: accountService,
            completionHandler: { _ in }
        )
        let expectedMessage = "Incorrect username or password."
        let error = WordPressComOAuthError.endpointError(AuthenticationFailure(apiJSONResponse: [
            "error": "invalid_request" as AnyObject,
            "error_description": expectedMessage as AnyObject
        ]))
        await coordinator.start(with: "email@test.com")
        let passwordController = try #require(navigationController.topViewController as? WPComPasswordLoginHostingController)

        // When
        passwordController.viewModel.displayRemoteError(error)

        // Then
        let alert = try #require(navigationController.topmostPresentedViewController as? UIAlertController)
        #expect(alert.title == expectedMessage)
    }
}
