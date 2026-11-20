import SwiftUI
import Testing
@testable import PointOfSale

struct POSMenuLayoutTests {
    @Test func test_layout_when_trigger_is_near_bottom_then_menu_opens_above_with_pointer() {
        // Given
        let metrics = POSMetrics.regular
        let source = CGRect(x: 16, y: 1114, width: 80, height: 80)
        let bounds = CGRect(x: 16, y: 40, width: 802, height: 1154)

        // When
        let layout = POSMenuLayout(source: source, safeBounds: bounds,
                                   preferredSize: CGSize(width: 400, height: 400), isRightToLeft: false, metrics: metrics)
        let card = layout.frame.insetBy(dx: metrics.padding.xxLarge, dy: metrics.padding.xxLarge)

        // Then
        #expect(layout.pointer.edge == .bottom)
        #expect(card.maxY == source.minY - metrics.spacing.small)
        #expect(bounds.contains(card))
        #expect(abs(card.minX + layout.pointer.fraction * card.width - source.midX) < 0.001)
    }

    @Test func test_layout_when_trigger_is_near_top_then_menu_opens_below_with_pointer() {
        // Given
        let metrics = POSMetrics.regular
        let source = CGRect(x: 722, y: 60, width: 80, height: 80)

        // When
        let layout = POSMenuLayout(source: source, safeBounds: CGRect(x: 16, y: 40, width: 802, height: 1154),
                                   preferredSize: CGSize(width: 400, height: 400), isRightToLeft: false, metrics: metrics)
        let card = layout.frame.insetBy(dx: metrics.padding.xxLarge, dy: metrics.padding.xxLarge)

        // Then
        #expect(layout.pointer.edge == .top)
        #expect(card.minY == source.maxY + metrics.spacing.small)
        #expect(card.maxX == source.maxX)
        #expect(abs(card.minX + layout.pointer.fraction * card.width - source.midX) < 0.001)
    }

    @Test(arguments: [false, true])
    func test_layout_when_direction_changes_then_menu_aligns_to_trigger_edge(isRightToLeft: Bool) {
        // Given
        let metrics = POSMetrics.regular
        let source = CGRect(x: 400, y: 60, width: 80, height: 80)

        // When
        let layout = POSMenuLayout(source: source, safeBounds: CGRect(x: 16, y: 40, width: 802, height: 1154),
                                   preferredSize: CGSize(width: 400, height: 400), isRightToLeft: isRightToLeft, metrics: metrics)
        let card = layout.frame.insetBy(dx: metrics.padding.xxLarge, dy: metrics.padding.xxLarge)

        // Then
        #expect(isRightToLeft ? card.minX == source.minX : card.maxX == source.maxX)
        #expect(abs(card.minX + layout.pointer.fraction * card.width - source.midX) < 0.001)
    }

    @Test func test_layout_when_content_exceeds_window_then_card_is_constrained_to_available_space() {
        // Given
        let metrics = POSMetrics.compact
        let source = CGRect(x: 260, y: 72, width: 48, height: 48)
        let bounds = CGRect(x: 12, y: 60, width: 296, height: 400)

        // When
        let layout = POSMenuLayout(source: source, safeBounds: bounds,
                                   preferredSize: CGSize(width: 368, height: 900), isRightToLeft: false, metrics: metrics)
        let card = layout.frame.insetBy(dx: metrics.padding.xxLarge, dy: metrics.padding.xxLarge)

        // Then
        #expect(bounds.contains(card))
        #expect(card.width == bounds.width)
        #expect(card.maxY == bounds.maxY)
        #expect(card.minY == source.maxY + metrics.spacing.small)
    }

    @Test func test_layout_when_window_rotates_then_card_and_pointer_follow_new_bounds() {
        // Given
        let metrics = POSMetrics.compact
        let preferredSize = CGSize(width: 368, height: 368)
        let portraitBounds = CGRect(x: 12, y: 59, width: 378, height: 781)
        let landscapeBounds = CGRect(x: 59, y: 12, width: 756, height: 354)
        let portraitSource = CGRect(x: 330, y: 72, width: 48, height: 48)
        let landscapeSource = CGRect(x: 730, y: 12, width: 48, height: 48)

        // When
        let portrait = POSMenuLayout(source: portraitSource, safeBounds: portraitBounds,
                                     preferredSize: preferredSize, isRightToLeft: false, metrics: metrics)
        let landscape = POSMenuLayout(source: landscapeSource, safeBounds: landscapeBounds,
                                      preferredSize: preferredSize, isRightToLeft: false, metrics: metrics)
        let portraitCard = portrait.frame.insetBy(dx: metrics.padding.xxLarge, dy: metrics.padding.xxLarge)
        let landscapeCard = landscape.frame.insetBy(dx: metrics.padding.xxLarge, dy: metrics.padding.xxLarge)

        // Then
        #expect(portraitBounds.contains(portraitCard))
        #expect(landscapeBounds.contains(landscapeCard))
        #expect(landscapeCard.height < portraitCard.height)
        #expect(abs(landscapeCard.minX + landscape.pointer.fraction * landscapeCard.width - landscapeSource.midX) < 0.001)
    }

    @Test(arguments: [CGFloat(-100), CGFloat(1000)])
    func test_layout_when_trigger_is_outside_horizontal_bounds_then_pointer_stays_on_card(sourceX: CGFloat) {
        // Given
        let metrics = POSMetrics.compact
        let bounds = CGRect(x: 12, y: 60, width: 296, height: 400)

        // When
        let layout = POSMenuLayout(source: CGRect(x: sourceX, y: 72, width: 48, height: 48), safeBounds: bounds,
                                   preferredSize: CGSize(width: 368, height: 368), isRightToLeft: false, metrics: metrics)
        let card = layout.frame.insetBy(dx: metrics.padding.xxLarge, dy: metrics.padding.xxLarge)

        // Then
        #expect(bounds.contains(card))
        #expect((0...1).contains(layout.pointer.fraction))
    }
}
