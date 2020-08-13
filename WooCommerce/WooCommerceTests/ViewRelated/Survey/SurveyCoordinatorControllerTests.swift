import Foundation
import WebKit
import XCTest

@testable import WooCommerce

/// Test cases for `SurveyCoordinatingControllerTests`.
///
final class SurveyCoordinatingControllerTests: XCTestCase {

    func test_it_loads_SurveyViewController_on_start() {
        // Given
        let factory = MockSurveyViewControllersFactory()

        // When
        let coordinator = SurveyCoordinatingController(survey: .inAppFeedback, viewControllersFactory: factory)

        // Then
        XCTAssertTrue(coordinator.topViewController is SurveyViewControllerOutputs)

    }

    func test_it_navigates_to_SurveySubmittedViewController_when_survey_is_submitted() throws {
        // Given
        let factory = MockSurveyViewControllersFactory()
        let coordinator = SurveyCoordinatingController(survey: .inAppFeedback, viewControllersFactory: factory)

        // When
        factory.surveyViewController.onCompletion()

        // Then
        waitUntil {
            coordinator.viewControllers.count > 1
        }
        XCTAssertTrue(coordinator.topViewController is SurveySubmittedViewControllerOutputs)
    }

    func test_it_gets_dismissed_on_backToStore_action() throws {
        // Given
        let factory = MockSurveyViewControllersFactory()
        let coordinator = SurveyCoordinatingController(survey: .inAppFeedback, viewControllersFactory: factory)

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        window.rootViewController?.present(coordinator, animated: false)

        // When
        factory.surveyViewController.onCompletion()
        factory.surveySubmittedViewController.onBackToStoreAction?()

        // Then
        waitUntil {
            coordinator.presentingViewController == nil
        }
    }

    func test_it_invokes_zendesk_on_contactUs_action() throws {
        // Given
        let zendeskManager = MockZendeskManager()
        let factory = MockSurveyViewControllersFactory()
        let coordinator = SurveyCoordinatingController(survey: .inAppFeedback, zendeskManager: zendeskManager, viewControllersFactory: factory)
        assertEmpty(zendeskManager.newRequestIfPossibleInvocations)

        // When
        factory.surveyViewController.onCompletion()
        factory.surveySubmittedViewController.onContactUsAction?()

        // Then
        XCTAssertEqual(zendeskManager.newRequestIfPossibleInvocations.count, 1)

        let invocation = try XCTUnwrap(zendeskManager.newRequestIfPossibleInvocations.first)
        XCTAssertEqual(invocation.controller, coordinator)
        XCTAssertNil(invocation.sourceTag)
    }
}

private final class MockSurveyViewControllersFactory: SurveyViewControllersFactoryProtocol {
    let surveyViewController = MockSurveyViewController()
    let surveySubmittedViewController = MockSurveySubmittedViewController()

    func makeSurveyViewController(survey: SurveyViewController.Source, onCompletion: @escaping () -> Void) -> SurveyViewControllerOutputs {
        surveyViewController.onCompletion = onCompletion
        return surveyViewController
    }

    func makeSurveySubmittedViewController(onContactUsAction: @escaping () -> Void,
                                           onBackToStoreAction: @escaping () -> Void) -> SurveySubmittedViewControllerOutputs {
        surveySubmittedViewController.onContactUsAction = onContactUsAction
        surveySubmittedViewController.onBackToStoreAction = onBackToStoreAction
        return surveySubmittedViewController
    }
}

private final class MockSurveyViewController: UIViewController, SurveyViewControllerOutputs {
    var onCompletion: () -> Void = {}
}

private final class MockSurveySubmittedViewController: UIViewController, SurveySubmittedViewControllerOutputs {
    var onContactUsAction: (() -> Void)?
    var onBackToStoreAction: (() -> Void)?
}
