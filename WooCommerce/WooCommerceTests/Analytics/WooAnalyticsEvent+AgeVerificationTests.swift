import Foundation
import Testing
@testable import WooCommerce

struct WooAnalyticsEvent_AgeVerificationTests {

    // MARK: - restrictionChecked

    @Test func test_restrictionChecked_when_given_each_decision_then_maps_decision_and_reason() {
        // Given
        let cases: [(AppAccessDecision, String, String?)] = [
            (.allow, "allowed", nil),
            (.allowConsentGranted, "allowed", nil),
            (.denyAndLogout, "restricted", "below_minimum_age"),
            (.restrictConsentRequired, "wall_consent_required", "consent_required"),
            (.restrictPendingConsent, "wall_consent_pending", "consent_pending"),
            (.restrictDeniedConsent, "wall_consent_denied", "consent_denied")
        ]

        for (decision, expectedDecision, expectedReason) in cases {
            // When
            let event = WooAnalyticsEvent.AgeVerification.restrictionChecked(
                trigger: .login,
                decision: decision,
                result: .eligible(significantAppChangeApprovalRequired: true, isMinor: true),
                consentState: nil
            )

            // Then
            #expect(event.statName == .accountAgeRestrictionChecked)
            #expect(event.properties["final_decision"] as? String == expectedDecision)
            #expect(event.properties["restriction_reason"] as? String == expectedReason)
        }
    }

    @Test func test_restrictionChecked_when_given_each_result_then_maps_coarse_outcome() {
        // Given
        let cases: [(AgeRangeVerificationResult, String)] = [
            (.eligible(significantAppChangeApprovalRequired: false, isMinor: false), "eligible"),
            (.eligible(significantAppChangeApprovalRequired: false, isMinor: true), "age_13_17"),
            (.ineligible, "below_13"),
            (.declinedSharing, "declined_sharing"),
            (.ineligibleForAgeFeatures, "not_applicable"),
            (.featureUnavailable, "unavailable"),
            (.invalidUIState, "invalid_ui_state"),
            (.sdkError(AgeRangeProviderError.notAvailable), "unavailable"),
            (.sdkError(AgeRangeProviderError.other(NSError(domain: "test", code: 1))), "sdk_error"),
            (.unknown, "unknown")
        ]

        for (result, expected) in cases {
            // When
            let event = WooAnalyticsEvent.AgeVerification.restrictionChecked(trigger: .login, decision: .allow, result: result, consentState: nil)

            // Then
            #expect(event.properties["age_range_outcome"] as? String == expected)
        }
    }

    @Test func test_restrictionChecked_when_given_each_consent_state_then_maps_significant_change_status() {
        // Given
        let cases: [(SignificantChangeConsentState, String)] = [
            (.notRequired, "not_applicable"),
            (.required, "required"),
            (.granted, "approved"),
            (.pending, "pending"),
            (.denied, "declined"),
            (.notAvailable, "unavailable")
        ]

        for (state, expected) in cases {
            // When
            let event = WooAnalyticsEvent.AgeVerification.restrictionChecked(trigger: .login, decision: .allow, result: .unknown, consentState: state)

            // Then
            #expect(event.properties["significant_change_status"] as? String == expected)
        }
    }

    @Test func test_restrictionChecked_when_sdk_error_then_records_domain_and_code_but_not_message() {
        // Given
        let underlying = NSError(domain: "com.apple.DeclaredAgeRange", code: 7, userInfo: [NSLocalizedDescriptionKey: "Sensitive message"])

        // When
        let event = WooAnalyticsEvent.AgeVerification.restrictionChecked(
            trigger: .login,
            decision: .allow,
            result: .sdkError(AgeRangeProviderError.other(underlying)),
            consentState: nil
        )

        // Then
        #expect(event.properties["sdk_error_domain"] as? String == "com.apple.DeclaredAgeRange")
        #expect(event.properties["sdk_error_code"] as? Int64 == 7)
        #expect(event.error == nil)
        #expect(event.properties.values.contains { ($0 as? String)?.contains("Sensitive") == true } == false)
    }

    @Test func test_restrictionChecked_when_api_not_available_then_records_no_error_properties() {
        // When
        let event = WooAnalyticsEvent.AgeVerification.restrictionChecked(
            trigger: .login,
            decision: .allow,
            result: .sdkError(AgeRangeProviderError.notAvailable),
            consentState: nil
        )

        // Then
        #expect(event.properties["sdk_error_domain"] == nil)
        #expect(event.properties["sdk_error_code"] == nil)
    }

    @Test func test_restrictionChecked_when_given_each_trigger_then_maps_trigger() {
        // Given
        let cases: [(AgeVerificationTrigger, String)] = [
            (.login, "login"),
            (.consentResolution, "consent_resolution"),
            (.foregroundRecheck, "foreground_recheck"),
            (.wallAction, "wall_action")
        ]

        for (trigger, expected) in cases {
            // When
            let event = WooAnalyticsEvent.AgeVerification.restrictionChecked(trigger: trigger, decision: .allow, result: .unknown, consentState: nil)

            // Then
            #expect(event.properties["trigger"] as? String == expected)
        }
    }

    // MARK: - Blocking screen

    @Test func test_screen_and_action_when_given_each_blocking_context_then_map_to_android_aligned_values() {
        // Given
        let cases: [(SignificantChangeBlockingContext, String, String)] = [
            (.approvalNeeded, "consent_needed", "request_approval"),
            (.pendingApproval, "consent_pending", "check_again"),
            (.approvalDenied, "consent_denied", "ask_again"),
            (.approvalGranted, "consent_granted", "continue")
        ]

        for (context, expectedScreen, expectedAction) in cases {
            // When
            let shown = WooAnalyticsEvent.AgeVerification.dialogShown(for: context)
            let action = WooAnalyticsEvent.AgeVerification.action(for: context)

            // Then
            #expect(shown.statName == .accountAgeRestrictionDialogShown)
            #expect(shown.properties["screen"] as? String == expectedScreen)
            #expect(action.statName == .accountAgeVerificationAction)
            #expect(action.properties["action"] as? String == expectedAction)
        }
    }

    // MARK: - Consent request / resolution

    @Test func test_consentRequested_when_built_then_contains_only_categorical_properties() {
        // When
        let event = WooAnalyticsEvent.AgeVerification.consentRequested(changeType: .manual, result: .failed, isReask: true)

        // Then
        #expect(event.statName == .accountAgeConsentRequested)
        #expect(event.properties["change_type"] as? String == "manual")
        #expect(event.properties["result"] as? String == "failed")
        #expect(event.properties["is_reask"] as? Bool == true)
        #expect(event.properties.count == 3)
    }

    @Test func test_consentResolved_when_built_then_contains_resolution_and_path() {
        // When
        let event = WooAnalyticsEvent.AgeVerification.consentResolved(resolution: .granted, via: .listener)

        // Then
        #expect(event.statName == .accountAgeConsentResolved)
        #expect(event.properties["resolution"] as? String == "granted")
        #expect(event.properties["via"] as? String == "listener")
        #expect(event.properties.count == 2)
    }
}
