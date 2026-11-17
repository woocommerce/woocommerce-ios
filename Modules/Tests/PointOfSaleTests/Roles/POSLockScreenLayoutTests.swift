import Foundation
import Testing
@testable import PointOfSale

struct POSLockScreenLayoutTests {
    @Test func test_layout_when_viewport_is_spacious_then_keeps_preferred_keys_and_padding() {
        // Given
        let viewport = CGSize(width: 834, height: 1190)

        // When
        let layout = makeLayout(viewport)

        // Then
        #expect(layout.keySize == 90)
        #expect(layout.verticalPadding == POSMetrics.regular.padding.xxLarge)
        #expect(layout.showsIllustration)
    }

    @Test func test_layout_when_reduced_padding_is_sufficient_then_keeps_preferred_keys() {
        // Given
        let viewport = CGSize(width: 900, height: 700)

        // When
        let layout = makeLayout(viewport)

        // Then
        #expect(layout.keySize == 90)
        #expect(layout.verticalPadding == POSMetrics.regular.padding.medium)
        #expect(layout.showsIllustration)
    }

    @Test func test_layout_when_height_is_limited_then_reduces_keys_and_keeps_illustration() {
        // Given
        let viewport = CGSize(width: 900, height: 669)

        // When
        let layout = makeLayout(viewport)

        // Then
        #expect(layout.keySize == 86)
        #expect(layout.verticalPadding == POSMetrics.regular.padding.medium)
        #expect(layout.showsIllustration)
    }

    @Test func test_layout_when_illustration_cannot_fit_then_hides_it_before_reducing_keys_further() {
        // Given
        let viewport = CGSize(width: 900, height: 580)

        // When
        let layout = makeLayout(viewport)

        // Then
        #expect(!layout.showsIllustration)
        #expect(layout.keySize == 90)
    }

    @Test func test_layout_when_phone_is_compact_then_keeps_its_preferred_size() {
        // Given
        let viewport = CGSize(width: 375, height: 734)

        // When
        let layout = makeLayout(viewport, preferredKeySize: 72, titleHeight: 26, metrics: .compact)

        // Then
        #expect(layout.keySize == 72)
        #expect(layout.showsIllustration)
    }

    @Test func test_layout_when_phone_has_compact_height_then_fits_keys_beside_header() {
        // Given
        let viewport = CGSize(width: 844, height: 360)

        // When
        let layout = makeLayout(viewport, preferredKeySize: 72, titleHeight: 52, isHorizontal: true, metrics: .compact)

        // Then
        #expect(layout.keySize == 63)
        #expect(layout.showsIllustration)
    }

    @Test(arguments: [CGFloat(72), 90])
    func test_key_size_when_space_is_insufficient_then_preserves_bounded_touch_targets(preferred: CGFloat) {
        // Given
        let availableSize = CGSize(width: 100, height: 100)

        // When
        let size = POSPINEntryViewHelper.lockScreenKeySize(fitting: availableSize, preferred: preferred, metrics: .regular)

        // Then
        #expect(size >= 60)
        #expect(size >= preferred * 0.8)
    }

    @Test func test_key_size_when_width_is_limiting_then_uses_one_uniform_size_that_fits() {
        // Given
        let availableSize = CGSize(width: 265, height: 1000)

        // When
        let size = POSPINEntryViewHelper.lockScreenKeySize(fitting: availableSize, preferred: 90, metrics: .regular)
        let keypadSize = POSPINEntryViewHelper.lockScreenKeypadSize(keySize: size, metrics: .regular)

        // Then
        #expect(size == 83)
        #expect(keypadSize.width <= availableSize.width)
    }
}

private extension POSLockScreenLayoutTests {
    func makeLayout(_ viewport: CGSize, preferredKeySize: CGFloat = 90, titleHeight: CGFloat = 36,
                    isHorizontal: Bool = false, metrics: POSMetrics = .regular) -> POSLockScreenLayout {
        POSLockScreenLayout(viewportSize: viewport, preferredKeySize: preferredKeySize, titleHeight: titleHeight,
                            illustrationHeight: 88, statusHeight: 48, isHorizontal: isHorizontal, metrics: metrics)
    }
}
