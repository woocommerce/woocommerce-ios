import Foundation
import WebKit
import XCTest

@testable import WooCommerce

/// Test cases for `SurveyViewController`.
///
final class SurveyViewControllerTests: XCTestCase {

    func testItLoadsTheCorrectInAppFeedbackSurvey() throws {
        // Given
        let viewController = SurveyViewController(survey: .inAppFeedback, onCompletion: {})

        // When
        _ = try XCTUnwrap(viewController.view)
        let mirror = try self.mirror(of: viewController)

        // Then
        XCTAssertTrue(mirror.webView.isLoading)
        XCTAssertEqual(mirror.webView.url, WooConstants.inAppFeedbackURL)
    }

    func testItCompletesAfterReceivingAFormSubmittedPOSTCallbackRequest() throws {
        // Given
        let exp = expectation(description: #function)
        var surveyCompleted = false
        let viewController = SurveyViewController(survey: .inAppFeedback, onCompletion: {
            surveyCompleted = true
            exp.fulfill()
        })

        // When
        _ = try XCTUnwrap(viewController.view)
        let mirror = try self.mirror(of: viewController)

        // Fakes a form submission POST navigation
        let navigationAction = FormSubmittedNavigationAction(httpMethod: "POST")
        viewController.webView(mirror.webView, decidePolicyFor: navigationAction, decisionHandler: { _ in })
        waitForExpectations(timeout: Constants.expectationTimeout)

        // Then
        XCTAssertTrue(surveyCompleted)
    }

    func testItDoesNotCompletesAfterReceivingAFormSubmittedGETCallbackRequest() throws {
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
        let navigationAction = FormSubmittedNavigationAction(httpMethod: "GET")
        viewController.webView(mirror.webView, decidePolicyFor: navigationAction, decisionHandler: { _ in })
        waitForExpectations(timeout: 1)

        // Then
        XCTAssertFalse(surveyCompleted)
    }
}

// MARK: - Mirroring

private extension SurveyViewControllerTests {
    struct SurveyViewControllerMirror {
        let webView: WKWebView
    }

    func mirror(of viewController: SurveyViewController) throws -> SurveyViewControllerMirror {
        let mirror = Mirror(reflecting: viewController)
        return SurveyViewControllerMirror(webView: try XCTUnwrap(mirror.descendant("webView") as? WKWebView))
    }
}


// MARK: - Mock navigation action
private extension SurveyViewControllerTests {
    final class FormSubmittedNavigationAction: WKNavigationAction {

        private let httpMethod: String
        init(httpMethod: String) {
            self.httpMethod = httpMethod
        }

        override var navigationType: WKNavigationType {
            return .formSubmitted
        }

        override var request: URLRequest {
            var request = URLRequest(url: WooConstants.inAppFeedbackURL)
            request.httpMethod = httpMethod
            return request
        }
    }
}
