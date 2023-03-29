@testable import WordPressAuthenticator
import XCTest

class SocialServiceTests: XCTestCase {

    func testSocialServiceUserApple() throws {
        let socialService = SocialService.apple(user: .init(email: "test@email.com", fullName: "Full Name"))

        XCTAssertEqual(socialService.user.fullName, "Full Name")
        XCTAssertEqual(socialService.user.email, "test@email.com")
    }

    func testSocialServiceUserGoogle() throws {
        let socialService = SocialService.google(user: .init(email: "email@test.com", fullName: "Name Full"))

        XCTAssertEqual(socialService.user.fullName, "Name Full")
        XCTAssertEqual(socialService.user.email, "email@test.com")
    }
}
