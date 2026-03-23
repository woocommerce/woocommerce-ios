import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductTypeBottomSheetListSelectorCommandTests: XCTestCase {

    func test_data_returns_all_provider_types_for_creation_form() {
        // Given
        let allTypes: [BottomSheetProductType] = [
            .simple(isVirtual: false),
            .simple(isVirtual: true),
            .subscription,
            .variable,
            .variableSubscription,
            .grouped,
            .affiliate
        ]
        let provider = MockCreatableProductTypeProvider(types: allTypes)

        // When
        let command = ProductTypeBottomSheetListSelectorCommand(
            source: .creationForm,
            productTypeProvider: provider
        ) { _ in }

        // Then
        assertEqual(allTypes, command.data)
    }

    func test_data_returns_reduced_types_for_creation_form() {
        // Given
        let reducedTypes: [BottomSheetProductType] = [
            .simple(isVirtual: false),
            .simple(isVirtual: true),
            .affiliate
        ]
        let provider = MockCreatableProductTypeProvider(types: reducedTypes)

        // When
        let command = ProductTypeBottomSheetListSelectorCommand(
            source: .creationForm,
            productTypeProvider: provider
        ) { _ in }

        // Then
        assertEqual(reducedTypes, command.data)
    }

    func test_data_excludes_selected_type_for_edit_form() {
        // Given
        let allTypes: [BottomSheetProductType] = [
            .simple(isVirtual: false),
            .simple(isVirtual: true),
            .variable,
            .grouped,
            .affiliate
        ]
        let provider = MockCreatableProductTypeProvider(types: allTypes)

        // When
        let command = ProductTypeBottomSheetListSelectorCommand(
            source: .editForm(selected: .variable),
            productTypeProvider: provider
        ) { _ in }

        // Then
        let expectedTypes: [BottomSheetProductType] = [
            .simple(isVirtual: false),
            .simple(isVirtual: true),
            .grouped,
            .affiliate
        ]
        assertEqual(expectedTypes, command.data)
    }

    func test_callback_is_called_on_selection() {
        // Given
        let provider = MockCreatableProductTypeProvider(types: [.simple(isVirtual: false)])
        var selectedActions = [BottomSheetProductType]()
        let command = ProductTypeBottomSheetListSelectorCommand(
            source: .creationForm,
            productTypeProvider: provider
        ) { selected in
            selectedActions.append(selected)
        }

        // When
        command.handleSelectedChange(selected: .simple(isVirtual: true))
        command.handleSelectedChange(selected: .grouped)

        // Then
        let expectedActions: [BottomSheetProductType] = [
            .simple(isVirtual: true),
            .grouped,
        ]
        XCTAssertEqual(selectedActions, expectedActions)
    }

    func test_creation_form_data_does_not_contain_grouped_and_variable_when_ciab_provider() {
        // Given
        let ciabTypes: [BottomSheetProductType] = [
            .simple(isVirtual: false),
            .simple(isVirtual: true),
            .affiliate
        ]
        let provider = MockCreatableProductTypeProvider(types: ciabTypes)

        // When
        let command = ProductTypeBottomSheetListSelectorCommand(
            source: .creationForm,
            productTypeProvider: provider
        ) { _ in }

        // Then
        XCTAssertFalse(command.data.contains(.grouped))
        XCTAssertFalse(command.data.contains(.variable))
    }

    func test_creation_form_data_contains_grouped_and_variable_when_standard_provider() {
        // Given
        let standardTypes: [BottomSheetProductType] = [
            .simple(isVirtual: false),
            .simple(isVirtual: true),
            .subscription,
            .variable,
            .variableSubscription,
            .grouped,
            .affiliate
        ]
        let provider = MockCreatableProductTypeProvider(types: standardTypes)

        // When
        let command = ProductTypeBottomSheetListSelectorCommand(
            source: .creationForm,
            productTypeProvider: provider
        ) { _ in }

        // Then
        XCTAssertTrue(command.data.contains(.grouped))
        XCTAssertTrue(command.data.contains(.variable))
    }
}

// MARK: - Mock

private struct MockCreatableProductTypeProvider: CreatableProductTypeProviding {
    let creatableProductTypes: [BottomSheetProductType]

    init(types: [BottomSheetProductType]) {
        self.creatableProductTypes = types
    }
}
