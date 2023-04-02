@testable import WordPressAuthenticator
import XCTest

class LoginViewControllerTests: XCTestCase {

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

        sut.loginFields.meta.googleUser = SocialService.User(email: "test@email.com", fullName: "Full Name")

        sut.showSignupEpilogue(for: AuthenticatorCredentials())

        let socialService = try XCTUnwrap(delegateSpy.socialService)
        guard case .google(let user) = socialService else {
            return XCTFail("Expected Google social service, got \(socialService) instead")
        }
        XCTAssertEqual(user.fullName, "Full Name")
        XCTAssertEqual(user.email, "test@email.com")
    }
}
