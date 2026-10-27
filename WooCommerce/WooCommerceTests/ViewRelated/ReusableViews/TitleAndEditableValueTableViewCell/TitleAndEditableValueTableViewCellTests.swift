import XCTest
@testable import WooCommerce

@MainActor
final class TitleAndEditableValueTableViewCellTests: XCTestCase {
    func test_cell_is_non_selectable() throws {
        // Given
        let cell = try makeCell()

        XCTAssertEqual(cell.selectionStyle, UITableViewCell.SelectionStyle.none)
    }

    func test_title_has_footnote_style_applied() throws {
        // Given
        let cell = try makeCell()
        let mirror = try self.mirror(of: cell)

        // When
        let title = mirror.title

        // Then
        XCTAssertEqual(title.font, UIFont.footnote)
        XCTAssertEqual(title.textColor, .systemColor(.secondaryLabel))
    }

    func test_value_has_body_style_applied() throws {
        // Given
        let cell = try makeCell()
        let mirror = try self.mirror(of: cell)

        // When
        let value = mirror.value

        // Then
        XCTAssertEqual(value.font, UIFont.body)
        XCTAssertEqual(value.textColor, .text)
    }

    func test_viewModel_is_updated_when_text_field_is_changed() throws {
        // Given
        let cell = try makeCell()
        let mirror = try self.mirror(of: cell)
        let viewModel = TitleAndEditableValueTableViewCellViewModel(title: "Test")

        cell.update(viewModel: viewModel)

        XCTAssertNil(viewModel.value)

        // When
        mirror.value.text = "Ut ullam itaque"
        mirror.value.sendActions(for: .editingChanged)

        // Then
        XCTAssertEqual(viewModel.value, "Ut ullam itaque")
    }

    func test_updateValue_then_updates_view_model() throws {
        // Given
        let cell = try makeCell()
        let newValue = "test"
        let viewModel = TitleAndEditableValueTableViewCellViewModel(title: "Test")

        // When
        cell.update(viewModel: viewModel)
        cell.updateValue(with: newValue)

        // Then
        XCTAssertEqual(viewModel.value, newValue)
    }

    private func makeCell() throws -> TitleAndEditableValueTableViewCell {
        let nib = try XCTUnwrap(Bundle.main.loadNibNamed("TitleAndEditableValueTableViewCell", owner: nil, options: nil))
        return try XCTUnwrap(nib.first as? TitleAndEditableValueTableViewCell)
    }
}

private extension TitleAndEditableValueTableViewCellTests {
    struct TitleAndEditableValueTableViewCellMirror {
        let title: UILabel
        let value: UITextField
    }

    func mirror(of cell: TitleAndEditableValueTableViewCell) throws -> TitleAndEditableValueTableViewCellMirror {
        let mirror = Mirror(reflecting: cell)

        return TitleAndEditableValueTableViewCellMirror(
            title: try XCTUnwrap(mirror.descendant("title") as? UILabel),
            value: try XCTUnwrap(mirror.descendant("value") as? UITextField)
        )
    }
}
