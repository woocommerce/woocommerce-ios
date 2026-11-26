import Testing
import UIKit
@testable import PointOfSale

@MainActor
struct POSOnboardingGuideModelTests {
    private let siteID: Int64 = 123
    private let preferences = MockPOSOnboardingGuidePreferences()
    private let analytics = MockPOSAnalytics()

    private func makeSUT(isFlagEnabled: Bool = true,
                         deviceIdiom: UIUserInterfaceIdiom = .phone) -> POSOnboardingGuideModel {
        let featureFlags = MockFeatureFlagService()
        featureFlags.isFeatureFlagEnabledReturnValue[.pointOfSaleOnboardingGuide] = isFlagEnabled
        return POSOnboardingGuideModel(siteID: siteID,
                                       featureFlags: featureFlags,
                                       deviceIdiom: deviceIdiom,
                                       preferences: preferences,
                                       analytics: analytics)
    }

    private var steps: [POSOnboardingGuideStep] { POSOnboardingGuideStep.all }

    // MARK: - Visibility

    @Test func init_then_visibility_is_undetermined() {
        // When
        let sut = makeSUT()

        // Then
        #expect(sut.visibility == .undetermined)
    }

    @Test func resolveVisibility_when_flag_disabled_then_hides_guide_before_eligibility_is_known() {
        // Given
        let sut = makeSUT(isFlagEnabled: false)

        // When
        sut.resolveVisibility(eligibilityState: nil)

        // Then
        #expect(sut.visibility == .hidden)
    }

    @Test func resolveVisibility_when_on_iPad_then_hides_guide_before_eligibility_is_known() {
        // Given
        let sut = makeSUT(deviceIdiom: .pad)

        // When
        sut.resolveVisibility(eligibilityState: nil)

        // Then
        #expect(sut.visibility == .hidden)
    }

    @Test func resolveVisibility_when_store_already_completed_guide_then_hides_guide() {
        // Given
        preferences.completedSiteIDs = [siteID]
        let sut = makeSUT()

        // When
        sut.resolveVisibility(eligibilityState: .eligible)

        // Then
        #expect(sut.visibility == .hidden)
        #expect(analytics.events.isEmpty)
    }

    @Test func resolveVisibility_when_eligibility_unknown_then_stays_undetermined() {
        // Given
        let sut = makeSUT()

        // When
        sut.resolveVisibility(eligibilityState: nil)

        // Then
        #expect(sut.visibility == .undetermined)
    }

    @Test func resolveVisibility_when_eligible_then_guide_shows_and_tracks_shown() {
        // Given
        let sut = makeSUT()

        // When
        sut.resolveVisibility(eligibilityState: .eligible)

        // Then
        #expect(sut.visibility == .visible)
        #expect(sut.wasShown)
        #expect(analytics.events.map(\.eventName) == ["pos_onboarding_shown"])
    }

    @Test func resolveVisibility_when_ineligible_then_guide_is_hidden() {
        // Given
        let sut = makeSUT()

        // When
        sut.resolveVisibility(eligibilityState: .ineligible(reason: .unsupportedCountry))

        // Then
        #expect(sut.visibility == .hidden)
        #expect(sut.wasShown == false)
    }

    @Test func resolveVisibility_when_store_becomes_eligible_after_being_ineligible_then_guide_stays_hidden() {
        // Given
        let sut = makeSUT()
        sut.resolveVisibility(eligibilityState: .ineligible(reason: .noInternetConnection))

        // When
        sut.resolveVisibility(eligibilityState: .eligible)

        // Then
        #expect(sut.visibility == .hidden)
        #expect(analytics.events.isEmpty)
    }

    @Test func resolveVisibility_when_called_again_after_showing_then_tracks_shown_once() {
        // Given
        let sut = makeSUT()
        sut.resolveVisibility(eligibilityState: .eligible)

        // When
        sut.resolveVisibility(eligibilityState: .eligible)

        // Then
        #expect(analytics.events.map(\.eventName) == ["pos_onboarding_shown"])
    }

    // MARK: - Buttons

    @Test func startSellingTapped_then_saves_choice_hides_guide_and_tracks_step() throws {
        // Given
        let sut = makeSUT()
        sut.resolveVisibility(eligibilityState: .eligible)
        let step = try #require(steps.last)

        // When
        sut.startSellingTapped(on: step)

        // Then
        #expect(sut.visibility == .hidden)
        #expect(sut.wasShown)
        #expect(preferences.markedSiteIDs == [siteID])
        let event = try #require(analytics.events.last)
        #expect(event.eventName == "pos_onboarding_start_selling_tapped")
        #expect(event.properties["step"] as? String == "step_3")
    }

    @Test func exitTapped_then_tracks_step_without_saving_choice() throws {
        // Given
        let sut = makeSUT()
        sut.resolveVisibility(eligibilityState: .eligible)

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
