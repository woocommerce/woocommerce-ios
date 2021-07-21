import XCTest

@testable import Yosemite

final class User_RolesTests: XCTestCase {

    // MARK: Extended User Methods

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

    // MARK: User.Role Enum

    func test_userRole_displayString_returns_correct_localized_value_for_all_roles() {
        for (roleKey, expectedValue) in Expectations.roleTexts {
            // Given
            let role = User.Role(rawValue: roleKey)!

            // When
            let displayString = role.displayString()

            // Then
            XCTAssertEqual(displayString, expectedValue)
        }
    }

    func test_userRole_isEligible_returns_true_when_role_isValid() {
        // Given
        let administratorRole = User.Role(rawValue: "administrator")!
        let shopManagerRole = User.Role(rawValue: "shop_manager")!

        // When
        let administratorIsEligible = administratorRole.isEligible()
        let shopManagerIsEligible = shopManagerRole.isEligible()

        // Then
        XCTAssertTrue(administratorIsEligible && shopManagerIsEligible)
    }

    func test_userRole_isEligible_returns_false_when_role_isNotValid() {
        // Given
        let role = User.Role(rawValue: "contributor")!

        // When
        let isEligible = role.isEligible()

        // Then
        XCTAssertFalse(isEligible)
    }

    func test_userRole_displayText_given_default_role_returns_correct_localized_string() {
        // Given
        let roleString = "shop_manager"
        let expected = Expectations.roleTexts[roleString]

        // When
        let displayText = User.Role.displayText(for: roleString)

        // Then
        XCTAssertEqual(displayText, expected)
    }

    func test_userRole_displayText_given_nonDefault_role_returns_titleCased_string() {
        // Given
        let roleString = "door_holder"
        let expected = "Door Holder"

        // When
        let displayText = User.Role.displayText(for: roleString)

        // Then
        XCTAssertEqual(displayText, expected)
    }
}

private extension User_RolesTests {
    func makeUser(firstName: String = "Johnny", lastName: String = "Appleseed", username: String = "johnny_appleseed",
                  email: String = "johnny@email.blog", roles: [String] = ["author", "editor"]) -> User {
        return User(localID: 0, siteID: 0, wpcomID: 0, email: email, username: username,
                    firstName: firstName, lastName: lastName, nickname: "", roles: roles)
    }

    struct Expectations {
        static let roleTexts: [String: String] = [
            "administrator": NSLocalizedString("Administrator", comment: "User's Administrator role."),
            "author": NSLocalizedString("Author", comment: "User's Author role."),
            "contributor": NSLocalizedString("Contributor", comment: "User's Contributor role."),
            "customer": NSLocalizedString("Customer", comment: "User's Customer role."),
            "editor": NSLocalizedString("Editor", comment: "User's Editor role."),
            "shop_manager": NSLocalizedString("Shop Manager", comment: "User's Shop Manager role."),
            "subscriber": NSLocalizedString("Subscriber", comment: "User's Subscriber role.")
        ]
    }
}
