import Testing
import UIKit
import Yosemite
@testable import WooCommerce

@MainActor
@Suite(.serialized)
struct StoreProductListViewsTests {
    private let viewModel = ProductsTabProductViewModel(product: Product.fake().copy(name: "Hoodie").toListItem())

    // MARK: - Cell

    @Test
    func test_cell_when_selected_or_highlighted_then_uses_selected_appearance() {
        // Given: the iPad split view highlights the open product through table selection
        let cell = makeCell()
        cell.configure(viewModel: viewModel, showsDivider: true, isChecked: nil)

        // When / Then
        cell.setSelected(true, animated: false)
        cell.updateConfiguration(using: cell.configurationState)
        #expect(cell.usesSelectedAppearance)

        cell.setSelected(false, animated: false)
        cell.setHighlighted(true, animated: false)
        cell.updateConfiguration(using: cell.configurationState)
        #expect(cell.usesSelectedAppearance)
    }

    @Test
    func test_cell_when_placeholder_is_selected_then_does_not_use_selected_appearance() {
        // Given: a loading row is not a product, so it never shows the selection tint
        let cell = makeCell()
        cell.configurePlaceholder()

        // When
        cell.setSelected(true, animated: false)
        cell.updateConfiguration(using: cell.configurationState)

        // Then
        #expect(!cell.usesSelectedAppearance)
    }

    @Test
    func test_cell_when_placeholder_then_hides_it_from_accessibility_and_interaction() {
        // Given: a reused product cell, so stale identifiers must not leak into the skeleton
        let cell = makeCell()
        cell.configure(viewModel: viewModel, showsDivider: true, isChecked: nil)

        // When
        cell.configurePlaceholder()

        // Then
        #expect(cell.accessibilityElementsHidden)
        #expect(!cell.isUserInteractionEnabled)
        #expect(cell.accessibilityIdentifier == nil)
    }

    @Test
    func test_cell_when_placeholder_is_reconfigured_as_product_then_restores_accessibility() {
        // Given
        let cell = makeCell()
        cell.configurePlaceholder()

        // When
        cell.configure(viewModel: viewModel, showsDivider: false, isChecked: nil)

        // Then: UI tests look products up by name
        #expect(!cell.accessibilityElementsHidden)
        #expect(cell.isUserInteractionEnabled)
        #expect(cell.accessibilityIdentifier == "Hoodie")
    }

    @Test
    func test_cell_when_checked_in_select_mode_then_exposes_the_selected_trait() {
        // Given: select mode does not use table selection, so VoiceOver relies on the check
        let cell = makeCell()

        // When
        cell.configure(viewModel: viewModel, showsDivider: true, isChecked: true)

        // Then
        #expect(cell.accessibilityTraits.contains(.selected))

        // When: the row is unchecked, or select mode ends
        cell.configure(viewModel: viewModel, showsDivider: true, isChecked: false)
        let uncheckedTraits = cell.accessibilityTraits
        cell.configure(viewModel: viewModel, showsDivider: true, isChecked: nil)

        // Then
        #expect(!uncheckedTraits.contains(.selected))
        #expect(!cell.accessibilityTraits.contains(.selected))
    }
}

private extension StoreProductListViewsTests {
    func makeCell() -> StoreProductListTableViewCell {
        StoreProductListTableViewCell(style: .default, reuseIdentifier: StoreProductListTableViewCell.reuseIdentifier)
    }
}
