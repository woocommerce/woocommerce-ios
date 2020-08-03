import XCTest

@testable import WooCommerce

final class SurveySubmittedViewControllerTests: XCTestCase {

    func testWhenTappingContactUsButtonThenTheContactUsPageIsPresented() throws {
        // Given
        let zendeskManager = MockZendeskManager()
        let viewController = SurveySubmittedViewController(zendeskManager: zendeskManager)
        XCTAssertNotNil(viewController.view)

        let mirror = try self.mirror(of: viewController)
        assertEmpty(zendeskManager.newRequestIfPossibleInvocations)

        // When
        mirror.contactUsButton.sendActions(for: .touchUpInside)

        // Then
        XCTAssertEqual(zendeskManager.newRequestIfPossibleInvocations.count, 1)

        let invocation = try XCTUnwrap(zendeskManager.newRequestIfPossibleInvocations.first)
        XCTAssertEqual(invocation.controller, viewController)
        XCTAssertNil(invocation.sourceTag)
    }
}

// MARK: - Mirroring

private extension SurveySubmittedViewControllerTests {
    struct SurveySubmittedViewControllerMirror {
        let contactUsButton: UIButton
    }

    func mirror(of viewController: SurveySubmittedViewController) throws -> SurveySubmittedViewControllerMirror {
        let mirror = Mirror(reflecting: viewController)

        return SurveySubmittedViewControllerMirror(
            contactUsButton: try XCTUnwrap(mirror.descendant("contactUsButton") as? UIButton)
        )
    }
}
