import SwiftUI
import Testing
@testable import PointOfSale

@MainActor
struct POSFlowButtonsViewTests {
    @Test func test_usesStackedLayout_when_horizontalSizeClass_is_compact_then_returns_true() {
        // Given
        let sizeClass: UserInterfaceSizeClass = .compact

        // When
        let result = POSFlowButtonsView.usesStackedLayout(horizontalSizeClass: sizeClass)

        // Then
        #expect(result == true)
    }

    @Test func test_usesStackedLayout_when_horizontalSizeClass_is_regular_then_returns_false() {
        // Given
        let sizeClass: UserInterfaceSizeClass = .regular

        // When
        let result = POSFlowButtonsView.usesStackedLayout(horizontalSizeClass: sizeClass)

        // Then
        #expect(result == false)
    }

    @Test func test_usesStackedLayout_when_horizontalSizeClass_is_nil_then_returns_false() {
        // Given
        let sizeClass: UserInterfaceSizeClass? = nil

        // When
        let result = POSFlowButtonsView.usesStackedLayout(horizontalSizeClass: sizeClass)

        // Then
        #expect(result == false)
    }

    @Test func test_visibleConfiguration_when_full_screen_flow_then_leaves_out_the_back_button() {
        // Given
        let configuration = PointOfSaleFlowButtonConfiguration(
            primaryButton: .init(title: "Next", action: {}),
            secondaryButton: .init(title: "Back", isBack: true, action: {}))

        // When
        let visible = POSFlowButtonsView.visibleConfiguration(for: configuration, isFullScreenFlow: true)

        // Then
        #expect(visible.primaryButton?.title == "Next")
        #expect(visible.secondaryButton == nil)
    }

    @Test func test_visibleConfiguration_when_not_full_screen_flow_then_keeps_the_back_button() {
        // Given
        let configuration = PointOfSaleFlowButtonConfiguration(
            primaryButton: .init(title: "Next", action: {}),
            secondaryButton: .init(title: "Back", isBack: true, action: {}))

        // When
        let visible = POSFlowButtonsView.visibleConfiguration(for: configuration, isFullScreenFlow: false)

        // Then
        #expect(visible.primaryButton?.title == "Next")
        #expect(visible.secondaryButton?.title == "Back")
    }

    @Test func test_visibleConfiguration_when_full_screen_flow_and_no_back_button_then_keeps_all_buttons() {
        // Given
        let configuration = PointOfSaleFlowButtonConfiguration(
            primaryButton: .init(title: "Retry", action: {}),
            secondaryButton: .init(title: "Keep searching", action: {}))

        // When
        let visible = POSFlowButtonsView.visibleConfiguration(for: configuration, isFullScreenFlow: true)

        // Then
        #expect(visible.primaryButton?.title == "Retry")
        #expect(visible.secondaryButton?.title == "Keep searching")
    }

    @Test func test_backButton_when_secondary_button_is_back_then_returns_it() {
        // Given
        let configuration = PointOfSaleFlowButtonConfiguration(
            primaryButton: .init(title: "Next", action: {}),
            secondaryButton: .init(title: "Back", isBack: true, action: {}))

        // Then
        #expect(configuration.backButton?.title == "Back")
    }

    @Test func test_backButton_when_no_button_is_back_then_returns_nil() {
        // Given
        let configuration = PointOfSaleFlowButtonConfiguration(
            primaryButton: nil,
            secondaryButton: .init(title: "How to set up barcodes on products", action: {}))

        // Then
        #expect(configuration.backButton == nil)
    }
}
