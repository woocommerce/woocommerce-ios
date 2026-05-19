import Testing
import UIKit
@testable import PointOfSale

/// Tests for POSLayoutScale enum and POSFontStyle scale-aware sizing.
///
/// `baseSize(for:)` and `effectiveFontSize(for:contentSizeCategory:)` are `internal` rather than
/// `fileprivate` so that this test suite can reach them without going through the SwiftUI
/// `View.font(_:POSFontStyle)` modifier (which requires a live view hierarchy).
struct POSFontStyleTests {

    // MARK: - POSLayoutScale sanity

    @Test func test_POSLayoutScale_tablet_and_phone_are_distinct_cases() {
        // Verify the two layout scale values exist and are different.
        let tablet = POSLayoutScale.tablet
        let phone = POSLayoutScale.phone

        #expect(tablet != phone)
    }

    // MARK: - baseSize: tablet returns original iPad design sizes

    @Test func test_baseSize_when_tablet_then_posHeadingBold_returns_36() {
        // Given / When
        let size = POSFontStyle.posHeadingBold.baseSize(for: .tablet)

        // Then
        #expect(size == 36)
    }

    @Test func test_baseSize_when_tablet_then_posBodyXLargeRegular_returns_30() {
        // Given / When
        let size = POSFontStyle.posBodyXLargeRegular.baseSize(for: .tablet)

        // Then
        #expect(size == 30)
    }

    @Test func test_baseSize_when_tablet_then_posBodyLargeBold_returns_24() {
        // Given / When
        let size = POSFontStyle.posBodyLargeBold.baseSize(for: .tablet)

        // Then
        #expect(size == 24)
    }

    @Test func test_baseSize_when_tablet_then_posBodyMediumBold_returns_20() {
        // Given / When
        let size = POSFontStyle.posBodyMediumBold.baseSize(for: .tablet)

        // Then
        #expect(size == 20)
    }

    @Test func test_baseSize_when_tablet_then_posBodySmallBold_returns_16() {
        // Given / When
        let size = POSFontStyle.posBodySmallBold().baseSize(for: .tablet)

        // Then
        #expect(size == 16)
    }

    @Test func test_baseSize_when_tablet_then_posCaptionBold_returns_14() {
        // Given / When
        let size = POSFontStyle.posCaptionBold.baseSize(for: .tablet)

        // Then
        #expect(size == 14)
    }

    // MARK: - baseSize: phone returns documented phone-specific sizes

    @Test func test_baseSize_when_phone_then_posHeadingBold_returns_24() {
        // Given / When
        let size = POSFontStyle.posHeadingBold.baseSize(for: .phone)

        // Then — phone heading is smaller than tablet (36 → 24)
        #expect(size == 24)
    }

    @Test func test_baseSize_when_phone_then_posBodyXLargeRegular_returns_22() {
        // Given / When
        let size = POSFontStyle.posBodyXLargeRegular.baseSize(for: .phone)

        // Then
        #expect(size == 22)
    }

    @Test func test_baseSize_when_phone_then_posBodyLargeBold_returns_18() {
        // Given / When
        let size = POSFontStyle.posBodyLargeBold.baseSize(for: .phone)

        // Then
        #expect(size == 18)
    }

    @Test func test_baseSize_when_phone_then_posBodyMediumBold_returns_16() {
        // Given / When
        let size = POSFontStyle.posBodyMediumBold.baseSize(for: .phone)

        // Then
        #expect(size == 16)
    }

    @Test func test_baseSize_when_phone_then_posBodySmallBold_returns_14() {
        // Given / When
        let size = POSFontStyle.posBodySmallBold().baseSize(for: .phone)

        // Then
        #expect(size == 14)
    }

    @Test func test_baseSize_when_phone_then_posCaptionBold_returns_12() {
        // Given / When
        let size = POSFontStyle.posCaptionBold.baseSize(for: .phone)

        // Then
        #expect(size == 12)
    }

    // MARK: - baseSize: phone sizes are always smaller than tablet sizes

    @Test(arguments: [
        POSFontStyle.posHeadingBold,
        POSFontStyle.posHeadingRegular,
        POSFontStyle.posBodyXLargeRegular,
        POSFontStyle.posBodyXLargeBold,
        POSFontStyle.posBodyLargeBold,
        POSFontStyle.posBodyLargeRegular(),
        POSFontStyle.posBodyMediumBold,
        POSFontStyle.posBodyMediumRegular(),
        POSFontStyle.posBodySmallBold(),
        POSFontStyle.posBodySmallRegular(),
        POSFontStyle.posCaptionBold,
        POSFontStyle.posCaptionRegular,
        POSFontStyle.posButtonSymbolXSmall,
        POSFontStyle.posButtonSymbolSmall,
        POSFontStyle.posButtonSymbolMedium,
        POSFontStyle.posButtonSymbolLarge,
    ])
    func test_baseSize_when_phone_then_is_smaller_than_tablet(style: POSFontStyle) {
        // Given
        let tabletSize = style.baseSize(for: .tablet)
        let phoneSize = style.baseSize(for: .phone)

        // Then — phone base sizes must always be <= tablet to avoid bloating the smaller screen
        #expect(phoneSize <= tabletSize)
    }

    // MARK: - MinimumFloor clamping

    /// At the smallest Dynamic Type category (.extraSmall), UIFontMetrics scales a value
    /// *down* from the base. The MinimumFloor clamp prevents the effective size from
    /// dropping below the declared floor.
    ///
    /// posBodySmallBold on phone has a phone base size of 14 pt and a floor of 11 pt.
    /// Without the floor, .extraSmall scaling could produce a value below 11 pt.
    /// With the floor, the result must be >= 11 pt.
    @Test func test_effectiveFontSize_when_phone_and_extraSmall_DynamicType_then_posBodySmallBold_is_not_below_floor() {
        // Given
        let style = POSFontStyle.posBodySmallBold()
        let expectedFloor: CGFloat = 11

        // When — extraSmall is the smallest Dynamic Type category; it scales values down
        let effectiveSize = style.effectiveFontSize(for: .phone, contentSizeCategory: .extraSmall)

        // Then — the floor clamp must keep the size at or above the declared minimum
        #expect(effectiveSize >= expectedFloor)
    }

    @Test func test_effectiveFontSize_when_phone_and_extraSmall_DynamicType_then_posCaptionRegular_is_not_below_floor() {
        // Given — caption has a phone base size of 12 and a floor of 11
        let style = POSFontStyle.posCaptionRegular
        let expectedFloor: CGFloat = 11

        // When
        let effectiveSize = style.effectiveFontSize(for: .phone, contentSizeCategory: .extraSmall)

        // Then
        #expect(effectiveSize >= expectedFloor)
    }

    @Test func test_effectiveFontSize_when_phone_and_extraSmall_DynamicType_then_posBodyMediumRegular_is_not_below_floor() {
        // Given — medium has a phone base of 16 and a floor of 12
        let style = POSFontStyle.posBodyMediumRegular()
        let expectedFloor: CGFloat = 12

        // When
        let effectiveSize = style.effectiveFontSize(for: .phone, contentSizeCategory: .extraSmall)

        // Then
        #expect(effectiveSize >= expectedFloor)
    }

    /// The floor must also hold for button symbols, which share a single buttonSymbol floor of 11.
    @Test func test_effectiveFontSize_when_phone_and_extraSmall_DynamicType_then_posButtonSymbolXSmall_is_not_below_floor() {
        // Given — buttonSymbolXSmall has phone base 14, floor 11
        let style = POSFontStyle.posButtonSymbolXSmall
        let expectedFloor: CGFloat = 11

        // When
        let effectiveSize = style.effectiveFontSize(for: .phone, contentSizeCategory: .extraSmall)

        // Then
        #expect(effectiveSize >= expectedFloor)
    }

    // MARK: - Floor does not clip at normal sizes

    /// At the default (.large) Dynamic Type category the floor should never be the binding
    /// constraint — the unscaled base size is already above the floor.
    @Test(arguments: [
        POSFontStyle.posHeadingBold,
        POSFontStyle.posBodyMediumBold,
        POSFontStyle.posBodySmallBold(),
        POSFontStyle.posCaptionRegular,
        POSFontStyle.posButtonSymbolXSmall,
    ])
    func test_effectiveFontSize_when_phone_and_large_DynamicType_then_exceeds_floor(style: POSFontStyle) {
        // Given — at the default size the metrics do not shrink the value below the base
        let phoneBase = style.baseSize(for: .phone)

        // When
        let effectiveSize = style.effectiveFontSize(for: .phone, contentSizeCategory: .large)

        // Then — at default Dynamic Type the effective size is at least the phone base
        #expect(effectiveSize >= phoneBase)
    }
}
