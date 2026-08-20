import Testing
import UIKit
@testable import WooCommerce

struct DefaultNoticePresenterTests {
    private let viewBounds = CGRect(x: 0, y: 0, width: 1_024, height: 1_366)

    @Test func test_bottomInset_when_bottom_tab_bar_is_visible_then_uses_tab_bar_height() {
        // Given
        let tabBarFrame = CGRect(x: 0, y: 1_286, width: 1_024, height: 80)

        // When
        let inset = NoticePositioning.bottomInset(viewBounds: viewBounds,
                                                  viewFrameInScreen: viewBounds,
                                                  tabBarFrameInView: tabBarFrame,
                                                  keyboardFrameInScreen: nil)

        // Then
        #expect(inset == 80)
    }

    @Test func test_bottomInset_when_iPad_tab_bar_is_at_top_then_does_not_add_tab_bar_height() {
        // Given
        let tabBarFrame = CGRect(x: 0, y: 0, width: 1_024, height: 80)

        // When
        let inset = NoticePositioning.bottomInset(viewBounds: viewBounds,
                                                  viewFrameInScreen: viewBounds,
                                                  tabBarFrameInView: tabBarFrame,
                                                  keyboardFrameInScreen: nil)

        // Then
        #expect(inset == 0)
    }

    @Test func test_bottomInset_when_keyboard_is_docked_then_positions_notice_above_keyboard() {
        // Given
        let tabBarFrame = CGRect(x: 0, y: 1_286, width: 1_024, height: 80)
        let keyboardFrame = CGRect(x: 0, y: 1_000, width: 1_024, height: 366)

        // When
        let inset = NoticePositioning.bottomInset(viewBounds: viewBounds,
                                                  viewFrameInScreen: viewBounds,
                                                  tabBarFrameInView: tabBarFrame,
                                                  keyboardFrameInScreen: keyboardFrame)

        // Then
        #expect(inset == 366)
    }

    @Test func test_bottomInset_when_iPad_keyboard_is_floating_then_keeps_notice_at_bottom() {
        // Given
        let keyboardFrame = CGRect(x: 600, y: 700, width: 320, height: 260)

        // When
        let inset = NoticePositioning.bottomInset(viewBounds: viewBounds,
                                                  viewFrameInScreen: viewBounds,
                                                  tabBarFrameInView: nil,
                                                  keyboardFrameInScreen: keyboardFrame)

        // Then
        #expect(inset == 0)
    }

    @Test func test_bottomInset_when_keyboard_overlaps_resized_iPad_window_then_uses_only_overlap() {
        // Given
        let resizedWindowFrame = CGRect(x: 0, y: 0, width: 700, height: 900)
        let keyboardFrame = CGRect(x: 0, y: 650, width: 700, height: 400)

        // When
        let inset = NoticePositioning.bottomInset(viewBounds: resizedWindowFrame,
                                                  viewFrameInScreen: resizedWindowFrame,
                                                  tabBarFrameInView: nil,
                                                  keyboardFrameInScreen: keyboardFrame)

        // Then
        #expect(inset == 250)
    }

    @Test func test_bottomInset_when_resized_iPad_window_is_lower_on_screen_then_includes_window_position() {
        // Given
        let resizedWindowFrame = CGRect(x: 160, y: 250, width: 700, height: 900)
        let keyboardFrame = CGRect(x: 0, y: 900, width: 1_024, height: 466)

        // When
        let resizedWindowBounds = CGRect(origin: .zero, size: resizedWindowFrame.size)
        let inset = NoticePositioning.bottomInset(viewBounds: resizedWindowBounds,
                                                  viewFrameInScreen: resizedWindowFrame,
                                                  tabBarFrameInView: nil,
                                                  keyboardFrameInScreen: keyboardFrame)

        // Then
        #expect(inset == 250)
    }

    @Test func test_bottomInset_when_keyboard_is_hidden_in_offset_window_then_uses_local_tab_bar_frame() {
        // Given
        let resizedWindowBounds = CGRect(x: 0, y: 0, width: 700, height: 900)
        let resizedWindowFrame = CGRect(x: 160, y: 250, width: 700, height: 900)
        let tabBarFrameInView = CGRect(x: 0, y: 850, width: 700, height: 50)

        // When
        let inset = NoticePositioning.bottomInset(viewBounds: resizedWindowBounds,
                                                  viewFrameInScreen: resizedWindowFrame,
                                                  tabBarFrameInView: tabBarFrameInView,
                                                  keyboardFrameInScreen: nil)

        // Then
        #expect(inset == 50)
    }
}
