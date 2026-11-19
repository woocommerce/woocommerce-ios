import SwiftUI
import Testing
@testable import StoreDesignSystem

@Suite struct StoreNoticeBannerToneTests {

    @Test func test_error_tone_when_resolving_action_colors_then_uses_alert_red_roles() {
        // Given / When
        let sut = StoreNoticeBannerTone.error.appearance

        // Then
        #expect(sut.actionBackground == .storeAlertRed)
        #expect(sut.actionForeground == .storeOnAlertRed)
    }
}
