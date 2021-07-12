import XCTest

@testable import Yosemite

final class User_RolesTests: XCTestCase {

    func test_user_when_fullName_exists_displayName_returns_fullName() {
        // Given
        let user: Yosemite.User = makeUser()

        // When
        let displayName = user.displayName()

        // Then
        XCTAssertEqual(displayName, "Johnny Appleseed")
    }

    func test_user_when_fullName_isEmpty_displayName_returns_username() {
        // Given
        let user = makeUser(firstName: "", lastName: "")

        // When
        let displayName = user.displayName()

        // Then
        XCTAssertEqual(displayName, "johnny_appleseed")
    }

    func test_user_when_fullName_and_username_isEmpty_displayName_returns_email() {
        // Given
        let user = makeUser(firstName: "", lastName: "", username: "")

        // When
        let displayName = user.displayName()

        // Then
        XCTAssertEqual(displayName, "johnny@email.blog")
    }

    func test_user_with_eligible_roles_hasEligibleRoles_returns_true() {
        // Given
        let adminUser = makeUser(roles: ["administrator"])
        let managerUser = makeUser(roles: ["editor", "shop_manager"])

        // When
        let adminIsEligible = adminUser.hasEligibleRoles()
        let managerIsEligible = managerUser.hasEligibleRoles()

        // Then
        XCTAssertTrue(adminIsEligible)
        XCTAssertTrue(managerIsEligible)
    }

    func test_user_with_ineligible_roles_hasEligibleRoles_returns_false() {
        // Given
        let user = makeUser()

        // When
        let isEligible = user.hasEligibleRoles()

        // Then
        XCTAssertFalse(isEligible)
    }
}

private extension User_RolesTests {
    func makeUser(firstName: String = "Johnny", lastName: String = "Appleseed", username: String = "johnny_appleseed",
                  email: String = "johnny@email.blog", roles: [String] = ["author", "editor"]) -> User {
        return User(localID: 0, siteID: 0, wpcomID: 0, email: email, username: username,
                    firstName: firstName, lastName: lastName, nickname: "", roles: roles)
    }
}
