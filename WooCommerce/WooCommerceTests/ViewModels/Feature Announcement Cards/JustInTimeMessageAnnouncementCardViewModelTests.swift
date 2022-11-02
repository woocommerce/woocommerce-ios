import XCTest
import TestKit
import Fakes
import Yosemite
import Combine

@testable import WooCommerce

final class JustInTimeMessageAnnouncementCardViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    private var webviewPublishes: [WebViewSheetViewModel]!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: Analytics!
    private var sut: JustInTimeMessageAnnouncementCardViewModel!

    override func setUp() {
        subscriptions = Set<AnyCancellable>()
        webviewPublishes = [WebViewSheetViewModel]()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    func setUp(with message: YosemiteJustInTimeMessage) {
        sut = JustInTimeMessageAnnouncementCardViewModel(justInTimeMessage: message,
                                                         screenName: "my_store",
                                                         siteID: 1234,
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
        setUp(with: YosemiteJustInTimeMessage.fake().copy(messageID: "message_id",
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
        setUp(with: YosemiteJustInTimeMessage.fake().copy(url: "https://woocommerce.com/take-action"))

        // When
        sut.ctaTapped()

        // Then
        let webViewViewModel = try XCTUnwrap(webviewPublishes.last)
        XCTAssertTrue(webViewViewModel.wpComAuthenticated)
    }

    func test_ctaTapped_presents_an_authenticated_webview_for_wordpress() throws {
        // Given
        setUp(with: YosemiteJustInTimeMessage.fake().copy(url: "https://wordpress.com/take-action"))

        // When
        sut.ctaTapped()

        // Then
        let webViewViewModel = try XCTUnwrap(webviewPublishes.last)
        XCTAssertTrue(webViewViewModel.wpComAuthenticated)
    }

    func test_ctaTapped_presents_an_unauthenticated_webview_for_other_url() throws {
        // Given
        setUp(with: YosemiteJustInTimeMessage.fake().copy(url: "https://example.com/take-action"))

        // When
        sut.ctaTapped()

        // Then
        let webViewViewModel = try XCTUnwrap(webviewPublishes.last)
        XCTAssertFalse(webViewViewModel.wpComAuthenticated)
    }

    func test_ctaTapped_tracks_jitm_cta_tapped_event() {
        // Given
        setUp(with: YosemiteJustInTimeMessage.fake().copy(messageID: "test-message-id", featureClass: "test-feature-class"))

        // When
        sut.ctaTapped()

        // Then
        guard let eventIndex = analyticsProvider.receivedEvents.firstIndex(of: "jitm_cta_tapped")
        else {
            return XCTFail("Analytics not logged")
        }
        let properties = analyticsProvider.receivedProperties[eventIndex] as? [String: String]
        let expectedProperties = ["jitm_id": "test-message-id",
                                  "jitm_group": "test-feature-class",
                                  "source": "my_store"]
        assertEqual(expectedProperties, properties)
    }
}
