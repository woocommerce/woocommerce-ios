import XCTest
import TestKit
import Fakes
import Yosemite
import Combine
import Networking

@testable import WooCommerce

final class JustInTimeMessageViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    private var webviewPublishes: [WebViewSheetViewModel]!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: Analytics!
    private var stores: MockStoresManager!
    private var sut: JustInTimeMessageViewModel!

    override func setUp() {
        subscriptions = Set<AnyCancellable>()
        webviewPublishes = [WebViewSheetViewModel]()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        stores = MockStoresManager(sessionManager: .makeForTesting())
    }

    func setUp(with message: Yosemite.JustInTimeMessage) {
        sut = JustInTimeMessageViewModel(justInTimeMessage: message,
                                                         screenName: "my_store",
                                                         siteID: 1234,
                                                         stores: stores,
                                                         analytics: analytics)

        sut.$showWebViewSheet
            .sink { [weak self] webViewSheetViewModel in
                if let webViewSheetViewModel = webViewSheetViewModel {
                    self?.webviewPublishes.append(webViewSheetViewModel)
                }
            }
            .store(in: &self.subscriptions)
    }

    func test_ctaTapped_presents_a_webview_with_the_url_adding_correct_utm_parameters() throws {
        // Given
        setUp(with: Yosemite.JustInTimeMessage.fake().copy(messageID: "message_id",
                                                           featureClass: "feature_class",
                                                           url: "https://woocommerce.com/take-action"))

        // When
        sut.ctaTapped()

        // Then
        let actualUrl = try XCTUnwrap(webviewPublishes.last?.url)
        let query = try XCTUnwrap(URLComponents(url: actualUrl, resolvingAgainstBaseURL: false)?.query)
        assertThat(query, contains: "utm_source=my_store")
        assertThat(query, contains: "utm_campaign=jitm_group_feature_class")
        assertThat(query, contains: "utm_content=jitm_message_id")
        assertThat(query, contains: "utm_term=1234")
    }

    func test_ctaTapped_presents_an_authenticated_webview_for_woocommerce() throws {
        // Given
        setUp(with: Yosemite.JustInTimeMessage.fake().copy(url: "https://woocommerce.com/take-action"))

        // When
        sut.ctaTapped()

        // Then
        let webViewViewModel = try XCTUnwrap(webviewPublishes.last)
        XCTAssertTrue(webViewViewModel.authenticated)
    }

    func test_ctaTapped_presents_an_authenticated_webview_for_wordpress() throws {
        // Given
        setUp(with: Yosemite.JustInTimeMessage.fake().copy(url: "https://wordpress.com/take-action"))

        // When
        sut.ctaTapped()

        // Then
        let webViewViewModel = try XCTUnwrap(webviewPublishes.last)
        XCTAssertTrue(webViewViewModel.authenticated)
    }

    func test_ctaTapped_presents_an_unauthenticated_webview_for_other_url() throws {
        // Given
        setUp(with: Yosemite.JustInTimeMessage.fake().copy(url: "https://example.com/take-action"))

        // When
        sut.ctaTapped()

        // Then
        let webViewViewModel = try XCTUnwrap(webviewPublishes.last)
        XCTAssertFalse(webViewViewModel.authenticated)
    }

    func test_ctaTapped_tracks_jitm_cta_tapped_event() {
        let message = Yosemite.JustInTimeMessage.fake().copy(messageID: "test-message-id", featureClass: "test-feature-class")
        setUp(with: message)

        // When
        sut.ctaTapped()

        // Then
        assertAnalyticEventLogged(name: "jitm_cta_tapped", message: message)
    }

    func test_dismiss_tracks_jitm_dismissed_event() {
        // Given
        let message = Yosemite.JustInTimeMessage.fake().copy(messageID: "test-message-id", featureClass: "test-feature-class")
        setUp(with: message)

        // When
        sut.dontShowAgainTapped()

        // Then
        assertAnalyticEventLogged(name: "jitm_dismissed", message: message)
    }

    func test_success_response_on_dismissal_tracks_jitm_dismiss_success_event() {
        // Given
        let message = Yosemite.JustInTimeMessage.fake().copy(messageID: "test-message-id", featureClass: "test-feature-class")
        setUp(with: message)

        stores.whenReceivingAction(ofType: JustInTimeMessageAction.self) { action in
            switch action {
            case .dismissMessage(_, _, let completion):
                completion(Result.success(true))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }

        // When
        sut.dontShowAgainTapped()

        // Then
        assertAnalyticEventLogged(name: "jitm_dismiss_success", message: message)
    }

    func test_failed_response_on_dismissal_tracks_jitm_dismiss_failed_event() {
        // Given
        let message = Yosemite.JustInTimeMessage.fake().copy(messageID: "test-message-id", featureClass: "test-feature-class")
        setUp(with: message)
        let expectedError = DotcomError.resourceDoesNotExist as NSError

        stores.whenReceivingAction(ofType: JustInTimeMessageAction.self) { action in
            switch action {
            case .dismissMessage(_, _, let completion):
                completion(Result.failure(expectedError))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }

        // When
        sut.dontShowAgainTapped()

        // Then
        assertAnalyticEventLogged(name: "jitm_dismiss_failure", message: message, error: expectedError)
    }

    func test_onAppear_tracks_just_in_time_message_displayed_analytic_event() {
        let message = Yosemite.JustInTimeMessage.fake().copy(messageID: "test-message-id", featureClass: "test-feature-class")
        setUp(with: message)

        // When
        sut.onAppear()

        // Then
        assertAnalyticEventLogged(name: "jitm_displayed", message: message)
    }

    private func assertAnalyticEventLogged(name: String, message: Yosemite.JustInTimeMessage) {
        let expectedProperties = ["jitm_id": message.messageID,
                                  "jitm_group": message.featureClass,
                                  "source": "my_store"]
        assertAnalyticEventLogged(name: name, expectedProperties: expectedProperties)
    }

    private func assertAnalyticEventLogged(name: String, message: Yosemite.JustInTimeMessage, error: Error) {
        let error = error as NSError
        let expectedProperties = ["jitm_id": message.messageID,
                                  "jitm_group": message.featureClass,
                                  "source": "my_store",
                                  "error_domain": String(error.domain),
                                  "error_description": error.debugDescription,
                                  "error_code": String(error.code)]
        assertAnalyticEventLogged(name: name, expectedProperties: expectedProperties)
    }

    private func assertAnalyticEventLogged(name: String, expectedProperties: [String: String]) {
        guard let eventIndex = analyticsProvider.receivedEvents.firstIndex(of: name),
              let properties = analyticsProvider.receivedProperties[eventIndex] as? [String: AnyHashable]
        else {
            return XCTFail("Analytics not logged")
        }

        for property in expectedProperties {
            XCTAssert(properties.contains(where: { $0 == property }))
        }
    }
}
