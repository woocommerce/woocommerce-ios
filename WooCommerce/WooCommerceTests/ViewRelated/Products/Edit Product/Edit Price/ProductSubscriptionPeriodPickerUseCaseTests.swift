import XCTest
@testable import WooCommerce
import enum Yosemite.SubscriptionPeriod

final class ProductSubscriptionPeriodPickerUseCaseTests: XCTestCase {

    func test_numberOfComponents_in_pickerView_is_correct() {
        // Given
        let useCase = ProductSubscriptionPeriodPickerUseCase(initialPeriod: nil, initialInterval: nil, updateHandler: { _, _ in })
        let pickerView = useCase.pickerView

        // When
        let number = useCase.numberOfComponents(in: pickerView)

        // Then
        XCTAssertEqual(number, 2)
    }

    func test_numberOfRows_in_first_component_is_correct() {
        // Given
        let useCase = ProductSubscriptionPeriodPickerUseCase(initialPeriod: nil, initialInterval: nil, updateHandler: { _, _ in })
        let pickerView = useCase.pickerView

        // When
        let number = useCase.pickerView(pickerView, numberOfRowsInComponent: 0)

        // Then
        XCTAssertEqual(number, 6)
    }

    func test_numberOfRows_in_second_component_is_correct() {
        // Given
        let useCase = ProductSubscriptionPeriodPickerUseCase(initialPeriod: nil, initialInterval: nil, updateHandler: { _, _ in })
        let pickerView = useCase.pickerView

        // When
        let number = useCase.pickerView(pickerView, numberOfRowsInComponent: 1)

        // Then
        XCTAssertEqual(number, 4)
    }

    func test_titleForRow_in_first_component_is_correct() {
        // Given
        let useCase = ProductSubscriptionPeriodPickerUseCase(initialPeriod: nil, initialInterval: nil, updateHandler: { _, _ in })
        let pickerView = useCase.pickerView

        // When
        let title = useCase.pickerView(pickerView, titleForRow: 1, forComponent: 0)

        // Then
        XCTAssertEqual(title, "2")
    }

    func test_titleForRow_in_second_component_is_correct_when_first_row_in_first_component_is_selected() {
        // Given
        let useCase = ProductSubscriptionPeriodPickerUseCase(initialPeriod: nil, initialInterval: nil, updateHandler: { _, _ in })
        let pickerView = useCase.pickerView

        // When
        pickerView.selectRow(0, inComponent: 0, animated: false)
        let title = useCase.pickerView(pickerView, titleForRow: 1, forComponent: 1)

        // Then
        XCTAssertEqual(title, SubscriptionPeriod.allCases[1].descriptionSingular)
    }

    func test_titleForRow_in_second_component_is_correct_when_first_row_in_first_component_is_not_selected() {
        // Given
        let useCase = ProductSubscriptionPeriodPickerUseCase(initialPeriod: nil, initialInterval: nil, updateHandler: { _, _ in })
        let pickerView = useCase.pickerView

        // When
        pickerView.selectRow(2, inComponent: 0, animated: false)
        let title = useCase.pickerView(pickerView, titleForRow: 1, forComponent: 1)

        // Then
        XCTAssertEqual(title, SubscriptionPeriod.allCases[1].descriptionPlural)
    }

    func test_pickerView_is_updated_with_initial_selected_rows() {
        // Given
        let useCase = ProductSubscriptionPeriodPickerUseCase(initialPeriod: .month, initialInterval: "2", updateHandler: { _, _ in })
        let pickerView = useCase.pickerView

        // When
        let intervalRowIndex = pickerView.selectedRow(inComponent: 0)
        let periodRowIndex = pickerView.selectedRow(inComponent: 1)

        // Then
        XCTAssertEqual(intervalRowIndex, 1)
        XCTAssertEqual(periodRowIndex, SubscriptionPeriod.allCases.firstIndex(of: .month))
    }

    func test_updateHandler_is_triggered_correctly_upon_selecting_any_row() {
        // Given
        var selectedPeriod: SubscriptionPeriod?
        var selectedInterval: String?
        let useCase = ProductSubscriptionPeriodPickerUseCase(initialPeriod: nil, initialInterval: nil, updateHandler: { period, interval in
            selectedPeriod = period
            selectedInterval = interval
        })
        let pickerView = useCase.pickerView

        // When
        // simulates user's tap - calling this programmatically doesn't trigger the delegate method.
        pickerView.selectRow(1, inComponent: 0, animated: false)
        useCase.pickerView(pickerView, didSelectRow: 1, inComponent: 0)

        // Then
        XCTAssertEqual(selectedPeriod, .day)
        XCTAssertEqual(selectedInterval, "2")

        // When
        // simulates user's tap - calling this programmatically doesn't trigger the delegate method.
        pickerView.selectRow(2, inComponent: 1, animated: false)
        useCase.pickerView(pickerView, didSelectRow: 2, inComponent: 1)

        // Then
        XCTAssertEqual(selectedPeriod, .month)
        XCTAssertEqual(selectedInterval, "2")
    }
}
