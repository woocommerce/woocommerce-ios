import SwiftUI
import Testing
import UIKit
@testable import StoreDesignSystem

@Suite struct StoreNoticeBannerToneTests {

    @Test func test_error_tone_when_resolving_action_colors_then_uses_alert_red_roles() {
        // Given / When
        let sut = StoreNoticeBannerTone.error.appearance

        // Then
        #expect(sut.actionBackground == .storeAlertRed)
        #expect(sut.actionForeground == .storeOnAlertRed)
    }

    @Test func test_error_tone_in_dark_mode_then_action_foreground_differs_from_background() {
        // Given
        let traits = UITraitCollection(userInterfaceStyle: .dark)
        let sut = StoreNoticeBannerTone.error.appearance

        // When
        let background = UIColor(sut.actionBackground).resolvedColor(with: traits)
        let foreground = UIColor(sut.actionForeground).resolvedColor(with: traits)

        // Then
        #expect(foreground != background)
    }
}
