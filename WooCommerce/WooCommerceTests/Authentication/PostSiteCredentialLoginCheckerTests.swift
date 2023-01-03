import XCTest
import protocol Yosemite.StoresManager
@testable import Networking
@testable import WooCommerce

final class PostSiteCredentialLoginCheckerTests: XCTestCase {
    private let testURL = "https://test.com"
    private var stores: StoresManager!
    private var navigationController: UINavigationController!

    override func setUp() {
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false))
        navigationController = UINavigationController()

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        window.rootViewController = navigationController
        super.setUp()
    }

    override func tearDown() {
        stores = nil
        navigationController = nil
        super.tearDown()
    }

    func test_application_password_disabled_error_is_displayed_when_application_password_is_disabled() {
        // Given
        let useCase = MockApplicationPasswordUseCase(mockGenerationError: ApplicationPasswordUseCaseError.applicationPasswordsDisabled)
        let checker = PostSiteCredentialLoginChecker(applicationPasswordUseCase: useCase)
        var isSuccess = false

        // When
        checker.checkEligibility(for: testURL, from: navigationController) {
            isSuccess = true
        }
        waitUntil {
            self.navigationController.viewControllers.isNotEmpty
        }

        // Then
        XCTAssertFalse(isSuccess)
        XCTAssertTrue(navigationController.topViewController is ULErrorViewController)
    }

    func test_error_alert_is_displayed_when_application_password_cannot_be_fetched() {
        // Given
        let useCase = MockApplicationPasswordUseCase(mockGenerationError: NetworkError.timeout)
        let checker = PostSiteCredentialLoginChecker(applicationPasswordUseCase: useCase)
        var isSuccess = false

        // When
        checker.checkEligibility(for: testURL, from: navigationController) {
            isSuccess = true
        }
        waitUntil {
            self.navigationController.presentedViewController != nil
        }

        // Then
        XCTAssertFalse(isSuccess)
        XCTAssertTrue(navigationController.viewControllers.isEmpty)
        XCTAssertTrue(navigationController.presentedViewController is UIAlertController)
    }
}

/// MOCK: application password use case
///
private final class MockApplicationPasswordUseCase: ApplicationPasswordUseCase {
    var mockApplicationPassword: ApplicationPassword?
    let mockGeneratedPassword: ApplicationPassword?
    let mockGenerationError: Error?
    let mockDeletionError: Error?
    init(mockApplicationPassword: ApplicationPassword? = nil,
         mockGeneratedPassword: ApplicationPassword? = nil,
         mockGenerationError: Error? = nil,
         mockDeletionError: Error? = nil) {
        self.mockApplicationPassword = mockApplicationPassword
        self.mockGeneratedPassword = mockGeneratedPassword
        self.mockGenerationError = mockGenerationError
        self.mockDeletionError = mockDeletionError
    }

    var applicationPassword: Networking.ApplicationPassword? {
        mockApplicationPassword
    }

    func generateNewPassword() async throws -> Networking.ApplicationPassword {
        if let mockGeneratedPassword {
            // Store the newly generated password
            mockApplicationPassword = mockGeneratedPassword
            return mockGeneratedPassword
        }
        throw mockGenerationError ?? NetworkError.notFound
    }

    func deletePassword() async throws {
        throw mockDeletionError ?? NetworkError.notFound
    }
}
