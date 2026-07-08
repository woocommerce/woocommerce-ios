import XCTest
@testable import WooCommerce
@testable import Yosemite

/// Layout tests for `ProductsTabProductTableViewCell`.
final class ProductsTabProductTableViewCellTests: XCTestCase {

    /// Regression test for WOOMOB-3177: in draggable cells (used by the Linked Products
    /// cross-sells/upsells list) the leading drag-handle icon used to be sized to the row
    /// height. A product whose name wrapped to multiple lines produced a taller row, which
    /// widened the square icon and pushed that single product's title to the right.
    ///
    /// The title's leading offset must be the same regardless of how many lines the name occupies.
    func test_draggable_cell_title_left_offset_is_the_same_for_single_line_and_wrapping_names() {
        // Given
        let shortName = "Cap"
        let longName = "Deluxe Handcrafted Artisan Wooden Coffee Table With Reclaimed Oak Finish And Brass Legs"

        // When
        let shortLayout = layoutDraggableCell(name: shortName)
        let longLayout = layoutDraggableCell(name: longName)

        // Then
        // Sanity: the long name actually wraps, producing a taller row — otherwise the test is moot.
        XCTAssertGreaterThan(longLayout.cellHeight, shortLayout.cellHeight,
                             "Expected the long product name to wrap into a taller row")
        // The title starts at the same horizontal offset in both cells.
        XCTAssertEqual(longLayout.titleMinX, shortLayout.titleMinX, accuracy: 0.5,
                       "Draggable cell titles should left-align regardless of name length")
    }
}

private extension ProductsTabProductTableViewCellTests {

    struct CellLayout {
        let titleMinX: CGFloat
        let cellHeight: CGFloat
    }

    /// Builds a draggable cell with the given product name, lays it out at a fixed width,
    /// and returns the name label's leading offset and the resulting cell height.
    func layoutDraggableCell(name: String) -> CellLayout {
        let width: CGFloat = 375
        let product = Product.fake().copy(name: name).toListItem()
        let viewModel = ProductsTabProductViewModel(product: product, isDraggable: true, imageService: MockImageService())

        let cell = ProductsTabProductTableViewCell(style: .default, reuseIdentifier: "cell")
        cell.update(viewModel: viewModel, imageService: MockImageService())

        let height = cell.contentView.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel).height
        cell.frame = CGRect(x: 0, y: 0, width: width, height: height)
        cell.layoutIfNeeded()

        guard let titleLabel = findLabel(in: cell.contentView, withText: name) else {
            XCTFail("Could not find the product name label in the cell hierarchy")
            return CellLayout(titleMinX: 0, cellHeight: height)
        }

        let titleMinX = titleLabel.convert(titleLabel.bounds, to: cell.contentView).minX
        return CellLayout(titleMinX: titleMinX, cellHeight: height)
    }

    func findLabel(in view: UIView, withText text: String) -> UILabel? {
        for subview in view.subviews {
            if let label = subview as? UILabel, label.text == text {
                return label
            }
            if let found = findLabel(in: subview, withText: text) {
                return found
            }
        }
        return nil
    }
}
