import Testing
import Yosemite
@testable import StoreDesignSystem
@testable import WooCommerce

@Suite struct OrderStatusEnumStoreBadgeToneTests {
    @Test func test_store_badge_tone_when_status_changes_then_uses_semantic_design_system_tone() {
        // Given
        let expectations: [(status: OrderStatusEnum, tone: StoreBadgeTone)] = [
            (.processing, .success),
            (.completed, .info),
            (.onHold, .warning),
            (.failed, .error),
            (.autoDraft, .neutral),
            (.pending, .neutral),
            (.cancelled, .neutral),
            (.refunded, .neutral),
            (.custom("custom"), .neutral)
        ]

        for expectation in expectations {
            // When
            let appearance = expectation.status.storeBadgeTone.appearance
            let expectedAppearance = expectation.tone.appearance

            // Then
            #expect(appearance.background == expectedAppearance.background)
            #expect(appearance.foreground == expectedAppearance.foreground)
            #expect(appearance.border == expectedAppearance.border)
        }
    }
}
