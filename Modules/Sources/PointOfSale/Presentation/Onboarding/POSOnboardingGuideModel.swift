import Foundation
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

    private(set) var visibility: Visibility

    private let siteID: Int64
    private let preferences: POSOnboardingGuidePreferenceStoring
    private let cardPaymentHistory: POSCardPaymentHistoryProviding?
    private let analytics: POSAnalyticsProviding

    init(siteID: Int64,
         isEnabled: Bool,
         preferences: POSOnboardingGuidePreferenceStoring,
         cardPaymentHistory: POSCardPaymentHistoryProviding?,
         analytics: POSAnalyticsProviding) {
        self.siteID = siteID
        self.preferences = preferences
        self.cardPaymentHistory = cardPaymentHistory
        self.analytics = analytics
        self.visibility = isEnabled && !preferences.hasCompletedGuide(for: siteID) ? .undetermined : .hidden
    }

    /// The first known eligibility settles the decision: a store that becomes eligible later in the session
    /// has already started POS behind the guide.
    func resolveVisibility(eligibilityState: POSEligibilityState?) async {
        guard visibility == .undetermined, let eligibilityState else {
            return
        }
        guard eligibilityState == .eligible else {
            visibility = .hidden
            return
        }
        let hasRecordedCardPayment = await cardPaymentHistory?.hasRecordedCardPayment(siteID: siteID) ?? false
        guard visibility == .undetermined else {
            return
        }
        visibility = hasRecordedCardPayment ? .hidden : .visible
        if visibility == .visible {
            analytics.track(event: WooAnalyticsEvent.POSOnboardingGuide.shown())
        }
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
