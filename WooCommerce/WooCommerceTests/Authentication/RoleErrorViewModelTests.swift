import XCTest
@testable import WooCommerce

final class RoleErrorViewModelTests: XCTestCase {
    // MARK: Properties

    /// Factory instance to generate mock classes related to this test.
    private let factory = RoleErrorTestsMockFactory()

    // MARK: Default value verifications

    func test_viewModel_provides_expected_name_text() {
        // Given
        let viewModel = factory.makeViewModel()

        // When
        let nameText = viewModel.nameText

        // Then
        XCTAssertEqual(nameText, Expectations.nameText)
    }

    func test_viewModel_provides_expected_roles_text() {
        // Given
        let viewModel = factory.makeViewModel()

        // When
        let roleText = viewModel.roleText

        // Then
        XCTAssertEqual(roleText, Expectations.rolesText)
    }

    func test_given_multipleRoles_viewModel_formats_roles_correctly() {
        // Given
        let testRoles = ["author", "editor"]
        let viewModel = factory.makeViewModel(roles: testRoles)

        // When
        let roleText = viewModel.roleText

        // Then
        XCTAssertEqual(roleText, "Author, Editor")
    }

    func test_given_multipleRoles_containingSnakeCase_viewModel_format_roles_correctly() {
        // Given
        let testRoles = ["gold_customer", "cool_cucumber"]
        let viewModel = factory.makeViewModel(roles: testRoles)

        // When
        let roleText = viewModel.roleText

        // Then
        XCTAssertEqual(roleText, "Gold Customer, Cool Cucumber")
    }

    func test_viewModel_provides_expected_image() {
        // Given
        let viewModel = factory.makeViewModel()

        // When
        let image = viewModel.image

        // Then
        XCTAssertEqual(image, Expectations.image)
    }

    func test_viewModel_provides_expected_description_text() {
        // Given
        let viewModel = factory.makeViewModel()

        // When
        let descriptionText = viewModel.descriptionText

        // Then
        XCTAssertEqual(descriptionText, Expectations.descriptionText)
    }

    func test_viewModel_provides_expected_linkButton_title() {
        // Given
        let viewModel = factory.makeViewModel()

        // When
        let linkButtonTitle = viewModel.auxiliaryButtonTitle

        // Then
        XCTAssertEqual(linkButtonTitle, Expectations.linkButtonTitle)
    }

    func test_viewModel_provides_expected_primaryButton_title() {
        // Given
        let viewModel = factory.makeViewModel()

        // When
        let primaryButtonTitle = viewModel.primaryButtonTitle

        // Then
        XCTAssertEqual(primaryButtonTitle, Expectations.primaryButtonTitle)
    }

    func test_viewModel_provides_expected_secondaryButton_title() {
        // Given
        let viewModel = factory.makeViewModel()

        // When
        let secondaryButtonTitle = viewModel.secondaryButtonTitle

        // Then
        XCTAssertEqual(secondaryButtonTitle, Expectations.secondaryButtonTitle)
    }

    func test_viewModel_provides_expected_helpBarButton_title() {
        // Given
        let viewModel = factory.makeViewModel()

        // When
        let helpBarButtonTitle = viewModel.helpBarButtonTitle

        // Then
        XCTAssertEqual(helpBarButtonTitle, Expectations.helpBarButtonTitle)
    }

    // MARK: Button action behaviors

    func test_when_primaryButton_isTapped_viewModel_should_trigger_retry() {
        // TODO: This test will be implemented in the later part.
    }

    func test_when_retry_succeeded_viewModel_should_redirect_to_main_content() {
        // TODO: This test will be implemented in the later part.
    }

    func test_when_retry_failed_viewModel_should_inform_output_to_notify_error() {
        // TODO: This test will be implemented in the later part.
    }

    func test_when_secondaryButton_isTapped_viewModel_should_trigger_navigation_to_root() {
        // TODO: This test will be implemented in the later part.
    }

    func test_when_auxiliaryButton_isTapped_viewModel_triggers_webContent_correctly() {
        // Given
        let fakeOutput = FakeRoleErrorOutput()
        let viewModel = factory.makeViewModel(output: fakeOutput)

        // When
        viewModel.didTapAuxiliaryButton()

        // Then
        XCTAssertEqual(fakeOutput.displayWebContentCallCount, 1) // ensure method is called once.
        XCTAssertEqual(fakeOutput.lastDisplayedURL, Expectations.linkURL)
    }
}

// MARK: - Test Helpers

private struct RoleErrorTestsMockFactory {
    /// Convenient method to generate RoleErrorViewModel objects with its dependencies injectable
    /// through this method's parameters.
    func makeViewModel(displayName: String = Expectations.nameText,
                       roles: [String] = Expectations.roles,
                       output: RoleErrorOutput = FakeRoleErrorOutput()) -> RoleErrorViewModel {
        let viewModel = RoleErrorViewModel(displayName: displayName, roles: roles)
        viewModel.output = output

        return viewModel
    }
}

/// Convenient fake class for the RoleErrorOutput protocol.
private class FakeRoleErrorOutput: RoleErrorOutput {
    var refreshTitleLabelsCallCount = 0
    var displayWebContentCallCount = 0
    var lastDisplayedURL: URL? = nil

    func refreshTitleLabels() {
        refreshTitleLabelsCallCount += 1
    }

    func displayWebContent(for url: URL) {
        displayWebContentCallCount += 1
        lastDisplayedURL = url
    }
}

// MARK: - Expectations

private enum Expectations {
    static let linkURL = WooConstants.URLs.rolesAndPermissionsInfo.asURL()
    static let nameText = "John Appleseed"
    static let roles = ["editor"]
    static let image = UIImage.incorrectRoleError

    static let rolesText = "Editor"
    static let descriptionText = NSLocalizedString("This app supports only Administrator and Shop Manager user roles. "
                                                    + "Please contact your store owner to upgrade your role.",
                                                   comment: "Message explaining more detail on why the user's role is incorrect.")

    static let linkButtonTitle = NSLocalizedString("Learn more about roles and permissions",
                                                   comment: "Link that points the user to learn more about roles. Clicking will open a web page."
                                                    + "Presented when the user has tries to switch to a store with incorrect permissions.")

    static let primaryButtonTitle = NSLocalizedString("Retry",
                                                      comment: "Action button that will recheck whether user has sufficient permissions to manage the store."
                                                        + "Presented when the user tries to switch to a store with incorrect permissions.")

    static let secondaryButtonTitle = NSLocalizedString("Log In With Another Account",
                                                        comment: "Action button that will restart the login flow."
                                                            + "Presented when logging in with a site address that does not have a valid Jetpack installation")

    static let helpBarButtonTitle = NSLocalizedString("Help", comment: "Help button")
}
