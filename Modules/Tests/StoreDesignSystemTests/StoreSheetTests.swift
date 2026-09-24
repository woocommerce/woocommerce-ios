import SwiftUI
import Testing
@testable import StoreDesignSystem

@Suite struct StoreSheetSizingTests {

    @Test func test_detents_when_fitContent_and_panel_is_unmeasured_then_opens_at_the_placeholder_detent() {
        // Given a content-fitting sheet whose panel has not been measured yet
        let sut = StoreSheetSizing.fitContent

        // When it resolves its detents with no measurement
        let detents = sut.detents(panelHeight: 0)

        // Then it opens at the placeholder detent rather than a zero-height one
        #expect(detents == [StoreSheetSizing.unmeasuredDetent])
    }

    @Test func test_detents_when_fitContent_and_panel_is_measured_then_uses_the_panel_height() {
        // Given a content-fitting sheet whose panel measures 320 pt
        let sut = StoreSheetSizing.fitContent

        // When it resolves its detents
        let detents = sut.detents(panelHeight: 320)

        // Then the single detent is the panel height
        #expect(detents == [.height(320)])
    }

    @Test func test_detents_when_custom_then_passes_them_through_regardless_of_the_panel_height() {
        // Given a sheet with caller-chosen detents
        let sut = StoreSheetSizing.detents([.medium, .large])

        // When it resolves its detents before and after measurement
        let unmeasured = sut.detents(panelHeight: 0)
        let measured = sut.detents(panelHeight: 320)

        // Then the caller's detents are used as given
        #expect(unmeasured == [.medium, .large])
        #expect(measured == [.medium, .large])
    }
}

@Suite struct StoreSheetLayoutTests {

    @Test func test_bottomInset_when_there_is_no_safe_area_then_adds_the_design_minimum() {
        // Given / When a panel with no system inset under it resolves its bottom padding
        let inset = StoreSheetLayout.bottomInset(safeAreaInset: 0)

        // Then it adds the full p5 minimum
        #expect(inset == StorePadding.p5)
    }

    @Test func test_bottomInset_when_the_safe_area_covers_the_minimum_then_adds_nothing() {
        // Given / When a panel above a home indicator inset larger than p5 resolves its bottom padding
        let inset = StoreSheetLayout.bottomInset(safeAreaInset: 34)

        // Then the system inset stands in for the minimum
        #expect(inset == 0)
    }

    @Test func test_bottomInset_when_the_safe_area_is_smaller_than_the_minimum_then_tops_it_up() {
        // Given / When a panel above a 10 pt system inset resolves its bottom padding
        let inset = StoreSheetLayout.bottomInset(safeAreaInset: 10)

        // Then only the difference to p5 is added
        #expect(inset == StorePadding.p5 - 10)
    }

    @Test func test_panelHeight_when_content_is_measured_then_adds_the_grabber_strip_and_the_bottom_inset() {
        // Given / When a panel with 300 pt of content and no system inset resolves its height
        let height = StoreSheetLayout.panelHeight(contentHeight: 300, safeAreaInset: 0)

        // Then it is the grabber strip, the content and the p5 minimum
        #expect(height == StoreSize.sheetGrabberAreaHeight + 300 + StorePadding.p5)
    }
}
