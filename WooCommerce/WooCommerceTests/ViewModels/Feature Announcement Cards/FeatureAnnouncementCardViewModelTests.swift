import XCTest
@testable import WooCommerce
import Yosemite

private typealias FeatureCardEvent = WooAnalyticsEvent.FeatureCard

final class FeatureAnnouncementCardViewModelTests: XCTestCase {

    var sut: FeatureAnnouncementCardViewModel!

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)

        let config = FeatureAnnouncementCardViewModel.Configuration(
            source: .paymentMethods,
            campaign: .upsellCardReaders,
            title: "Buy a reader",
            message: "With a card reader, you can accept card payments",
            buttonTitle: "Buy now",
            image: .paymentsFeatureBannerImage,
            dismissAlertTitle: "Dismiss alert",
            dismissAlertMessage: "Press here to dismiss alert"
        )

        sut = FeatureAnnouncementCardViewModel(
            analytics: analytics,
            configuration: config)

        super.setUp()
    }

    func test_onAppear_logs_shown_analytics_event() {
        // Given

        // When
        sut.onAppear()

        // Then
        let expectedSource = FeatureCardEvent.Source.paymentMethods
        let expectedCampaign = FeatureAnnouncementCampaign.upsellCardReaders
        let expectedEvent = WooAnalyticsEvent.FeatureCard.shown(source: expectedSource, campaign: expectedCampaign)

        XCTAssert(analyticsProvider.receivedEvents.contains(where: { $0 == expectedEvent.statName.rawValue
        }))

        verifyUpsellCardProperties(expectedSource: expectedSource, expectedCampaign: expectedCampaign)
    }

    func test_dontShowAgainTapped_logs_dismissed_analytics_event() {
        // Given

        // When
        sut.dontShowAgainTapped()

        // Then
        assertLogsDismissedAnalyticsEvent()
    }

    func test_remindLaterTapped_logs_dismissed_analytics_event() {
        // Given

        // When
        sut.remindLaterTapped()

        // Then
        assertLogsDismissedAnalyticsEvent()
    }

    func test_ctaTapped_logs_analytics_event() {
        // Given

        // When
        sut.ctaTapped()

        // Then
        let expectedSource = FeatureCardEvent.Source.paymentMethods
        let expectedCampaign = FeatureAnnouncementCampaign.upsellCardReaders
        let expectedEvent = WooAnalyticsEvent.FeatureCard.ctaTapped(source: expectedSource, campaign: expectedCampaign)

        XCTAssert(analyticsProvider.receivedEvents.contains(where: { $0 == expectedEvent.statName.rawValue
        }))

        verifyUpsellCardProperties(expectedSource: expectedSource, expectedCampaign: expectedCampaign)
    }

    private func assertLogsDismissedAnalyticsEvent() {
        let expectedSource = FeatureCardEvent.Source.paymentMethods
        let expectedCampaign = FeatureAnnouncementCampaign.upsellCardReaders
        let expectedEvent = WooAnalyticsEvent.FeatureCard.dismissed(source: expectedSource, campaign: expectedCampaign, remindLater: true)

        XCTAssert(analyticsProvider.receivedEvents.contains(where: { $0 == expectedEvent.statName.rawValue
        }))

        verifyUpsellCardProperties(expectedSource: expectedSource, expectedCampaign: expectedCampaign)
    }

    private func verifyUpsellCardProperties(
        expectedSource: FeatureCardEvent.Source,
        expectedCampaign: FeatureAnnouncementCampaign) {
        guard let actualProperties = analyticsProvider.receivedProperties.first(where: { $0.keys.contains("source")
        }) else {
            return XCTFail("Expected properties were not logged")
        }

        assertEqual(expectedSource.rawValue, actualProperties["source"] as? String)
        assertEqual(expectedCampaign.rawValue, actualProperties["campaign"] as? String)
    }
}
