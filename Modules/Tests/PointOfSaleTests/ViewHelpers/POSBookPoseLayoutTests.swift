import Foundation
import Testing
@testable import PointOfSale

struct POSBookPoseLayoutTests {
    @Test func test_layout_when_centered_book_division_then_uses_two_pages_and_gap() {
        // Given
        let size = CGSize(width: 1000, height: 700)
        let division = CGRect(x: 480, y: 0, width: 40, height: 700)

        // When
        let layout = POSBookPoseLayout(size: size, defaultLeadingFraction: 0.65, divisionFrames: [division])

        // Then
        #expect(layout.leadingWidth == 480)
        #expect(layout.trailingWidth == 480)
        #expect(layout.spacing == 40)
    }

    @Test func test_layout_when_local_insets_are_asymmetric_then_keeps_distinct_page_widths() {
        // Given
        let size = CGSize(width: 940, height: 700)
        let division = CGRect(x: 420, y: -30, width: 40, height: 760)

        // When
        let layout = POSBookPoseLayout(size: size, defaultLeadingFraction: 0.65, divisionFrames: [division])

        // Then
        #expect(layout.leadingWidth == 420)
        #expect(layout.trailingWidth == 480)
        #expect(layout.spacing == 40)
        #expect(layout.leadingWidth + layout.spacing + layout.trailingWidth == size.width)
    }

    @Test func test_layout_when_input_is_rtl_mirrored_then_preserves_semantic_leading_page() {
        // Given: the geometry query has already mirrored the division into semantic coordinates.
        let size = CGSize(width: 940, height: 700)
        let mirroredDivision = CGRect(x: 480, y: 0, width: 40, height: 700)

        // When
        let layout = POSBookPoseLayout(size: size, defaultLeadingFraction: 0.65, divisionFrames: [mirroredDivision])

        // Then
        #expect(layout.leadingWidth == 480)
        #expect(layout.trailingWidth == 420)
        #expect(layout.spacing == 40)
    }

    @Test(arguments: [CGFloat(0.35), CGFloat(0.65)])
    func test_layout_when_no_division_then_preserves_callers_default_fraction(fraction: CGFloat) {
        // Given
        let size = CGSize(width: 1000, height: 700)

        // When
        let layout = POSBookPoseLayout(size: size, defaultLeadingFraction: fraction)

        // Then
        #expect(layout.leadingWidth == 1000 * fraction)
        #expect(layout.trailingWidth == 1000 - layout.leadingWidth)
        #expect(layout.spacing == 0)
    }

    @Test(arguments: [
        CGRect(x: -80, y: 0, width: 40, height: 700), // Outside the local window.
        CGRect(x: 1020, y: 0, width: 40, height: 700),
        CGRect(x: 0, y: 330, width: 1000, height: 40), // Tabletop division.
        CGRect(x: 480, y: 40, width: 40, height: 620), // Does not span the local height.
        CGRect(x: 0, y: 0, width: 40, height: 700), // No leading page.
        CGRect(x: 960, y: 0, width: 40, height: 700), // No trailing page.
        CGRect(x: 480, y: 0, width: 0, height: 700),
        CGRect.null,
        CGRect.infinite
    ])
    func test_layout_when_division_cannot_separate_two_pages_then_uses_default(division: CGRect) {
        // Given
        let size = CGSize(width: 1000, height: 700)

        // When
        let layout = POSBookPoseLayout(size: size, defaultLeadingFraction: 0.65, divisionFrames: [division])

        // Then
        #expect(layout.leadingWidth == 650)
        #expect(layout.trailingWidth == 350)
        #expect(layout.spacing == 0)
    }
}
