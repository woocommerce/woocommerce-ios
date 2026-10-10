import SwiftUI
import Testing
@testable import PointOfSale

struct POSContentPaddingTests {
    @Test(arguments: [LayoutDirection.leftToRight, .rightToLeft])
    func test_context_when_pane_does_not_intersect_region_then_credits_reserved_margin(direction: LayoutDirection) {
        // Given: global container coordinates differ from the region's semantic local coordinates.
        let context = POSContentPaddingContext(bounds: CGRect(x: 10, y: 30, width: 1000, height: 700),
                                              regions: [(CGRect(x: 480, y: 0, width: 40, height: 700),
                                                         EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))])
        let frame = CGRect(x: direction == .leftToRight ? 530 : 10, y: 30, width: 480, height: 700)

        // When
        let clearance = context.clearance(for: frame, layoutDirection: direction)

        // Then: 16 points of requested padding need no addition to the existing 20-point clearance.
        #expect(clearance.leading == 20)
        #expect(clearance.trailing == 0)
        #expect(max(0, 16 - clearance.leading) == 0)
    }

    @Test func test_context_when_input_spans_both_pages_then_keeps_full_width_padding() {
        // Given
        let context = POSContentPaddingContext(bounds: CGRect(x: 10, y: 30, width: 1000, height: 700),
                                              regions: [(CGRect(x: 480, y: 0, width: 40, height: 700),
                                                         EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))])

        // When
        let clearance = context.clearance(for: context.bounds, layoutDirection: .leftToRight)

        // Then
        #expect(clearance == EdgeInsets())
    }

    @Test func test_clearance_when_region_precedes_content_then_credits_leading_margin() {
        // Given
        let margins = EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)

        // When
        let clearance = POSContentPadding.clearance(size: CGSize(width: 400, height: 700),
                                                   frame: CGRect(x: -20, y: 0, width: 0, height: 700),
                                                   margins: margins)

        // Then: the container already supplies 20 points of spacing.
        #expect(clearance.leading == 0)
        #expect(clearance.trailing == 0)
    }

    @Test(arguments: [CGFloat(0), CGFloat(8), CGFloat(20), CGFloat(40)])
    func test_clearance_when_content_follows_region_then_credits_only_remaining_margin(distance: CGFloat) {
        // Given
        let margins = EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)

        // When
        let clearance = POSContentPadding.clearance(size: CGSize(width: 400, height: 700),
                                                   frame: CGRect(x: -40 - distance, y: 0, width: 40, height: 700),
                                                   margins: margins)

        // Then
        #expect(clearance.leading == max(0, 20 - distance))
        #expect(clearance.trailing == 0)
    }

    @Test(arguments: [CGFloat(0), CGFloat(8), CGFloat(20), CGFloat(40)])
    func test_clearance_when_content_precedes_region_then_credits_only_remaining_margin(distance: CGFloat) {
        // Given
        let margins = EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)

        // When
        let clearance = POSContentPadding.clearance(size: CGSize(width: 400, height: 700),
                                                   frame: CGRect(x: 400 + distance, y: 0, width: 40, height: 700),
                                                   margins: margins)

        // Then
        #expect(clearance.leading == 0)
        #expect(clearance.trailing == max(0, 20 - distance))
    }

    @Test func test_clearance_when_content_spans_region_then_preserves_edge_padding() {
        // Given
        let margins = EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)

        // When
        let clearance = POSContentPadding.clearance(size: CGSize(width: 1000, height: 700),
                                                   frame: CGRect(x: 480, y: 0, width: 40, height: 700),
                                                   margins: margins)

        // Then
        #expect(clearance == EdgeInsets())
    }
}
