import WebKit
import XCTest
import TestKit

@testable import WooCommerce

/// Test cases for `SurveyCoordinatingControllerTests`.
///
final class SurveyCoordinatingControllerTests: XCTestCase {

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        analytics = nil
        analyticsProvider = nil
        super.tearDown()
    }

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
            coordinator.topViewController is SurveySubmittedViewControllerOutputs
        }
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

    func test_it_tracks_a_surveyScreen_completed_event_when_the_survey_is_submitted() throws {
        // Given
        let factory = MockSurveyViewControllersFactory()
        _ = SurveyCoordinatingController(survey: .inAppFeedback,
                                         viewControllersFactory: factory,
                                         analytics: analytics)

        XCTAssertEqual(analyticsProvider.receivedEvents.count, 1)

        // When
        factory.surveyViewController.onCompletion()

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents.count, 2)
        XCTAssertEqual(analyticsProvider.receivedEvents.last, "survey_screen")

        let properties = try XCTUnwrap(analyticsProvider.receivedProperties.last)
        XCTAssertEqual(properties["context"] as? String, "general")
        XCTAssertEqual(properties["action"] as? String, "completed")
    }

    func test_it_tracks_a_surveyScreen_opened_event_when_started() throws {
        // Given
        let factory = MockSurveyViewControllersFactory()

        // When
        _ = SurveyCoordinatingController(survey: .inAppFeedback,
                                         viewControllersFactory: factory,
                                         analytics: analytics)

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents.count, 1)
        XCTAssertEqual(analyticsProvider.receivedEvents.first, "survey_screen")

        let properties = try XCTUnwrap(analyticsProvider.receivedProperties.first)
        XCTAssertEqual(properties["context"] as? String, "general")
        XCTAssertEqual(properties["action"] as? String, "opened")
    }

    func test_it_tracks_a_surveyScreen_canceled_event_when_it_is_dimissed_without_finishing_the_survey() throws {
        // Given
        let factory = MockSurveyViewControllersFactory()

        let rootViewController = UIViewController()

        // Add the coordinator to a UIWindow and present from a UIViewController so that dismissal
        // properties (e.g. `isBeingDismissed`) will get updated correctly.
        let window = UIWindow(frame: .zero)
        window.rootViewController = rootViewController
        window.isHidden = false

        let coordinator = SurveyCoordinatingController(survey: .inAppFeedback,
                                                       viewControllersFactory: factory,
                                                       analytics: analytics)
        waitForExpectation { exp in
            rootViewController.present(coordinator, animated: false) {
                exp.fulfill()
            }
        }

        // When
        waitForExpectation { exp in
            coordinator.dismiss(animated: false) {
                exp.fulfill()
            }
        }

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents.count, 2)
        XCTAssertEqual(analyticsProvider.receivedEvents.last, "survey_screen")

        let properties = try XCTUnwrap(analyticsProvider.receivedProperties.last)
        XCTAssertEqual(properties["context"] as? String, "general")
        XCTAssertEqual(properties["action"] as? String, "canceled")
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
