import Foundation
import Testing
@testable import PointOfSale

@MainActor
struct POSOnboardingGuideModelTests {
    private let siteID: Int64 = 123
    private let preferences = MockPOSOnboardingGuidePreferences()
    private let cardPaymentHistory = MockPOSCardPaymentHistory()
    private let analytics = MockPOSAnalytics()

    private func makeSUT(isEnabled: Bool = true) -> POSOnboardingGuideModel {
        POSOnboardingGuideModel(siteID: siteID,
                                isEnabled: isEnabled,
                                preferences: preferences,
                                cardPaymentHistory: cardPaymentHistory,
                                analytics: analytics)
    }

    private var steps: [POSOnboardingGuideStep] { POSOnboardingGuideStep.all }

    // MARK: - Visibility

    @Test func init_when_disabled_then_guide_is_hidden() {
        // When
        let sut = makeSUT(isEnabled: false)

        // Then
        #expect(sut.visibility == .hidden)
    }

    @Test func init_when_store_already_started_selling_then_guide_is_hidden() {
        // Given
        preferences.completedSiteIDs = [siteID]

        // When
        let sut = makeSUT()

        // Then
        #expect(sut.visibility == .hidden)
    }

    @Test func init_when_enabled_for_new_store_then_visibility_is_undetermined() {
        // When
        let sut = makeSUT()

        // Then
        #expect(sut.visibility == .undetermined)
    }

    @Test func resolveVisibility_when_eligibility_unknown_then_stays_undetermined() async {
        // Given
        let sut = makeSUT()

        // When
        await sut.resolveVisibility(eligibilityState: nil)

        // Then
        #expect(sut.visibility == .undetermined)
        #expect(cardPaymentHistory.requestedSiteIDs.isEmpty)
    }

    @Test func resolveVisibility_when_eligible_without_card_payment_then_guide_shows_and_tracks_shown() async {
        // Given
        let sut = makeSUT()

        // When
        await sut.resolveVisibility(eligibilityState: .eligible)

        // Then
        #expect(sut.visibility == .visible)
        #expect(cardPaymentHistory.requestedSiteIDs == [siteID])
        #expect(analytics.events.map(\.eventName) == ["pos_onboarding_shown"])
    }

    @Test func resolveVisibility_when_card_payment_recorded_then_guide_is_hidden() async {
        // Given
        cardPaymentHistory.hasRecordedCardPayment = true
        let sut = makeSUT()

        // When
        await sut.resolveVisibility(eligibilityState: .eligible)

        // Then
        #expect(sut.visibility == .hidden)
        #expect(analytics.events.isEmpty)
    }

    @Test func resolveVisibility_when_card_payment_history_unavailable_then_guide_shows() async {
        // Given
        let sut = POSOnboardingGuideModel(siteID: siteID,
                                          isEnabled: true,
                                          preferences: preferences,
                                          cardPaymentHistory: nil,
                                          analytics: analytics)

        // When
        await sut.resolveVisibility(eligibilityState: .eligible)

        // Then
        #expect(sut.visibility == .visible)
    }

    @Test func resolveVisibility_when_ineligible_then_guide_is_hidden_without_checking_payments() async {
        // Given
        let sut = makeSUT()

        // When
        await sut.resolveVisibility(eligibilityState: .ineligible(reason: .unsupportedCountry))

        // Then
        #expect(sut.visibility == .hidden)
        #expect(cardPaymentHistory.requestedSiteIDs.isEmpty)
    }

    @Test func resolveVisibility_when_store_becomes_eligible_after_being_ineligible_then_guide_stays_hidden() async {
        // Given
        let sut = makeSUT()
        await sut.resolveVisibility(eligibilityState: .ineligible(reason: .noInternetConnection))

        // When
        await sut.resolveVisibility(eligibilityState: .eligible)

        // Then
        #expect(sut.visibility == .hidden)
        #expect(analytics.events.isEmpty)
    }

    @Test func resolveVisibility_when_called_again_after_showing_then_tracks_shown_once() async {
        // Given
        let sut = makeSUT()
        await sut.resolveVisibility(eligibilityState: .eligible)

        // When
        await sut.resolveVisibility(eligibilityState: .eligible)

        // Then
        #expect(analytics.events.map(\.eventName) == ["pos_onboarding_shown"])
    }

    // MARK: - Buttons

    @Test func startSellingTapped_then_saves_choice_hides_guide_and_tracks_step() async throws {
        // Given
        let sut = makeSUT()
        await sut.resolveVisibility(eligibilityState: .eligible)
        let step = try #require(steps.last)

        // When
        sut.startSellingTapped(on: step)

        // Then
        #expect(sut.visibility == .hidden)
        #expect(preferences.markedSiteIDs == [siteID])
        let event = try #require(analytics.events.last)
        #expect(event.eventName == "pos_onboarding_start_selling_tapped")
        #expect(event.properties["step"] as? String == "step_3")
    }

    @Test func exitTapped_then_tracks_step_without_saving_choice() async throws {
        // Given
        let sut = makeSUT()
        await sut.resolveVisibility(eligibilityState: .eligible)

        // When
        sut.exitTapped(on: steps[1])

        // Then
        #expect(preferences.markedSiteIDs.isEmpty)
        #expect(sut.visibility == .visible)
        let event = try #require(analytics.events.last)
        #expect(event.eventName == "pos_onboarding_exit_tapped")
        #expect(event.properties["step"] as? String == "step_2")
    }

    // MARK: - Steps

    @Test func stepViewed_then_tracks_step() throws {
        // Given
        let sut = makeSUT()

        // When
        sut.stepViewed(steps[0])

        // Then
        let event = try #require(analytics.events.last)
        #expect(event.eventName == "pos_onboarding_step_viewed")
        #expect(event.properties["step"] as? String == "step_1")
    }

    @Test func videoTapped_then_tracks_step() throws {
        // Given
        let sut = makeSUT()

        // When
        sut.videoTapped(on: steps[2])

        // Then
        let event = try #require(analytics.events.last)
        #expect(event.eventName == "pos_onboarding_video_tapped")
        #expect(event.properties["step"] as? String == "step_3")
    }
}
