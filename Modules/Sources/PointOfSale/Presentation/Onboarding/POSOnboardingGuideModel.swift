import UIKit
import struct WooFoundation.WooAnalyticsEvent

/// Decides once per POS session whether the onboarding guide covers POS, and records the merchant's choice.
@MainActor
@Observable
final class POSOnboardingGuideModel {
    enum Visibility: Equatable {
        case undetermined
        case visible
        case hidden
    }

    private(set) var visibility: Visibility = .undetermined
    private(set) var wasShown = false

    private let siteID: Int64
    private let featureFlags: POSFeatureFlagProviding
    private let deviceIdiom: UIUserInterfaceIdiom
    private let preferences: POSOnboardingGuidePreferenceStoring
    private let analytics: POSAnalyticsProviding

    init(siteID: Int64,
         featureFlags: POSFeatureFlagProviding,
         deviceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom,
         preferences: POSOnboardingGuidePreferenceStoring = POSOnboardingGuidePreferences(),
         analytics: POSAnalyticsProviding) {
        self.siteID = siteID
        self.featureFlags = featureFlags
        self.deviceIdiom = deviceIdiom
        self.preferences = preferences
        self.analytics = analytics
    }

    /// Settles once per POS session. The checks that don't need eligibility run first, so POS doesn't wait for it
    /// when the guide can't show. A store that becomes eligible later in the session has already started POS.
    func resolveVisibility(eligibilityState: POSEligibilityState?) {
        guard visibility == .undetermined else {
            return
        }
        // The device idiom, not the size class, so iPad split view never shows the guide.
        guard featureFlags.isFeatureFlagEnabled(.pointOfSaleOnboardingGuide),
              deviceIdiom == .phone,
              !preferences.hasCompletedGuide(for: siteID) else {
            visibility = .hidden
            return
        }
        guard let eligibilityState else {
            return
        }
        guard eligibilityState == .eligible else {
            visibility = .hidden
            return
        }
        visibility = .visible
        wasShown = true
        analytics.track(event: WooAnalyticsEvent.POSOnboardingGuide.shown())
    }

    func stepViewed(_ step: POSOnboardingGuideStep) {
        analytics.track(event: WooAnalyticsEvent.POSOnboardingGuide.stepViewed(step: step))
    }

    func startSellingTapped(on step: POSOnboardingGuideStep) {
        analytics.track(event: WooAnalyticsEvent.POSOnboardingGuide.startSellingTapped(step: step))
        preferences.markGuideCompleted(for: siteID)
        visibility = .hidden
    }

    func exitTapped(on step: POSOnboardingGuideStep) {
        analytics.track(event: WooAnalyticsEvent.POSOnboardingGuide.exitTapped(step: step))
    }

    func videoTapped(on step: POSOnboardingGuideStep) {
        analytics.track(event: WooAnalyticsEvent.POSOnboardingGuide.videoTapped(step: step))
    }
}
