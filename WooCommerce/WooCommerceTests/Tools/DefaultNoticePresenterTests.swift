import Testing
import UIKit
@testable import WooCommerce

struct DefaultNoticePresenterTests {
    private let viewBounds = CGRect(x: 0, y: 0, width: 1_024, height: 1_366)

    @Test func test_tabBarBottomInset_when_bottom_tab_bar_is_visible_then_uses_tab_bar_height() {
        // Given
        let tabBarFrame = CGRect(x: 0, y: 1_286, width: 1_024, height: 80)

        // When
        let inset = NoticePositioning.tabBarBottomInset(viewBounds: viewBounds, tabBarFrame: tabBarFrame)

        // Then
        #expect(inset == 80)
    }

    @Test func test_tabBarBottomInset_when_iPad_tab_bar_is_at_top_then_does_not_add_tab_bar_height() {
        // Given
        let tabBarFrame = CGRect(x: 0, y: 0, width: 1_024, height: 80)

        // When
        let inset = NoticePositioning.tabBarBottomInset(viewBounds: viewBounds, tabBarFrame: tabBarFrame)

        // Then
        #expect(inset == 0)
    }

    @Test func test_tabBarBottomInset_when_window_is_resized_then_uses_tab_bar_height() {
        // Given
        let resizedWindowBounds = CGRect(x: 0, y: 0, width: 700, height: 900)
        let tabBarFrameInView = CGRect(x: 0, y: 850, width: 700, height: 50)

        // When
        let inset = NoticePositioning.tabBarBottomInset(viewBounds: resizedWindowBounds, tabBarFrame: tabBarFrameInView)

        // Then
        #expect(inset == 50)
    }
}
