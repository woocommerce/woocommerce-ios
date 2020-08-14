import Foundation
import WebKit
import XCTest

@testable import WooCommerce

/// Test cases for `SurveyViewController`.
///
final class SurveyViewControllerTests: XCTestCase {

    func test_it_loads_the_correct_inApp_feedback_survey() throws {
        // Given
        let viewController = SurveyViewController(survey: .inAppFeedback, onCompletion: {})

        // When
        _ = try XCTUnwrap(viewController.view)
        let mirror = try self.mirror(of: viewController)

        // Then
        XCTAssertTrue(mirror.webView.isLoading)
        XCTAssertEqual(mirror.webView.url, WooConstants.URLs.inAppFeedback.asURL())
    }

    func test_it_completes_after_receiving_a_form_submitted_completed_callback_request() throws {
        // Given
        var surveyCompleted = false
        let viewController = SurveyViewController(survey: .inAppFeedback, onCompletion: {
            surveyCompleted = true
        })

        // When
        _ = try XCTUnwrap(viewController.view)
        let mirror = try self.mirror(of: viewController)

        // Fakes a form submission "completed" action navigation
        let navigationAction = FormSubmittedNavigationAction.completedAction
        viewController.webView(mirror.webView, decidePolicyFor: navigationAction, decisionHandler: { _ in })

        // Then
        waitUntil {
            surveyCompleted
        }
    }

    func test_it_does_not_complete_after_receiving_a_form_submitted_non_completed_callback_request() throws {
        // Given
        let exp = expectation(description: #function)
        exp.isInverted = true
        var surveyCompleted = false
        let viewController = SurveyViewController(survey: .inAppFeedback, onCompletion: {
            surveyCompleted = true
            exp.fulfill()
        })

        // When
        _ = try XCTUnwrap(viewController.view)
        let mirror = try self.mirror(of: viewController)

        // Fakes a form submission GET navigation
        let navigationAction = FormSubmittedNavigationAction.nonCompletedAction
        viewController.webView(mirror.webView, decidePolicyFor: navigationAction, decisionHandler: { _ in })
        waitForExpectations(timeout: Constants.expectationTimeout)

        // Then
        XCTAssertFalse(surveyCompleted)
    }

    func test_it_does_not_complete_after_receiving_a_form_submitted_empty_callback_request() throws {
        // Given
        let exp = expectation(description: #function)
        exp.isInverted = true
        var surveyCompleted = false
        let viewController = SurveyViewController(survey: .inAppFeedback, onCompletion: {
            surveyCompleted = true
            exp.fulfill()
        })

        // When
        _ = try XCTUnwrap(viewController.view)
        let mirror = try self.mirror(of: viewController)

        // Fakes a form submission GET navigation
        let navigationAction = FormSubmittedNavigationAction.emptyAction
        viewController.webView(mirror.webView, decidePolicyFor: navigationAction, decisionHandler: { _ in })
        waitForExpectations(timeout: Constants.expectationTimeout)

        // Then
        XCTAssertFalse(surveyCompleted)
    }

    func test_it_shows_the_loading_view_when_loading_a_survey() throws {
        // Given
        let viewController = SurveyViewController(survey: .inAppFeedback, onCompletion: {})

        // When
        _ = try XCTUnwrap(viewController.view)
        let mirror = try self.mirror(of: viewController)

        // Then
        XCTAssertFalse(mirror.loadingView.isHidden)
    }

    func test_it_hides_the_loading_view_after_loading_a_survey() throws {
        // Given
        let viewController = SurveyViewController(survey: .inAppFeedback, onCompletion: {})

        // When
        _ = try XCTUnwrap(viewController.view)
        let mirror = try self.mirror(of: viewController)

        // Fakes a web view loading completion
        let navigation = try XCTUnwrap(mirror.webView.reload())
        viewController.webView(mirror.webView, didFinish: navigation)

        // Then
        waitUntil {
            mirror.loadingView.isHidden
        }
    }
}

// MARK: - Mirroring

private extension SurveyViewControllerTests {
    struct SurveyViewControllerMirror {
        let webView: WKWebView
        let loadingView: SurveyLoadingView
    }

    func mirror(of viewController: SurveyViewController) throws -> SurveyViewControllerMirror {
        let mirror = Mirror(reflecting: viewController)
        return SurveyViewControllerMirror(
            webView: try XCTUnwrap(mirror.descendant("webView") as? WKWebView),
            loadingView: try XCTUnwrap(mirror.descendant("loadingView") as? SurveyLoadingView)
        )
    }
}


// MARK: - Mock navigation action
private extension SurveyViewControllerTests {
    final class FormSubmittedNavigationAction: WKNavigationAction {

        static var emptyAction: FormSubmittedNavigationAction {
            return FormSubmittedNavigationAction(messageParameterValue: nil)
        }

        static var nonCompletedAction: FormSubmittedNavigationAction {
            return FormSubmittedNavigationAction(messageParameterValue: "other")
        }

        static var completedAction: FormSubmittedNavigationAction {
            return FormSubmittedNavigationAction(messageParameterValue: "done")
        }

        private let messageParameterValue: String?
        private init(messageParameterValue: String?) {
            self.messageParameterValue = messageParameterValue
        }

        override var navigationType: WKNavigationType {
            return .formSubmitted
        }

        override var request: URLRequest {
            var urlComponents = URLComponents(url: WooConstants.URLs.inAppFeedback.asURL(), resolvingAgainstBaseURL: false) ?? URLComponents()
            if let messageParameterValue = messageParameterValue {
                let item = URLQueryItem(name: "msg", value: messageParameterValue)
                urlComponents.queryItems = [item]
            }

            let finalURL = (try? urlComponents.asURL()) ?? WooConstants.URLs.inAppFeedback.asURL()
            return URLRequest(url: finalURL)
        }
    }
}
