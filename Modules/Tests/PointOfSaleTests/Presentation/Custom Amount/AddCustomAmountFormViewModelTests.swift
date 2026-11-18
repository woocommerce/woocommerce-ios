import Foundation
import Testing
import WooFoundation
import struct Yosemite.POSCustomAmount
@testable import PointOfSale

struct AddCustomAmountFormViewModelTests {
    private let currencySettings = CurrencySettings(
        currencyCode: .USD,
        currencyPosition: .left,
        thousandSeparator: ",",
        decimalSeparator: ".",
        numberOfDecimals: 2
    )

    @Test(arguments: [(CurrencySettings.CurrencyPosition.left, "$1,234.50"),
                      (.right, "1,234.50$"),
                      (.leftSpace, "$\u{00a0}1,234.50"),
                      (.rightSpace, "1,234.50\u{00a0}$")])
    func test_formattedAmount_when_currency_position_varies_then_uses_injected_settings(
        position: CurrencySettings.CurrencyPosition, expected: String
    ) {
        // Given
        let settings = CurrencySettings(currencyCode: .USD, currencyPosition: position,
                                        thousandSeparator: ",", decimalSeparator: ".", numberOfDecimals: 2)
        let sut = AddCustomAmountFormViewModel(currencySettings: settings)

        // When
        sut.setAmount(digits: "123450")

        // Then
        #expect(sut.formattedAmount == expected)
    }

    @Test func test_formattedAmount_when_store_uses_comma_decimals_then_formats_euro_amount() {
        // Given
        let settings = CurrencySettings(currencyCode: .EUR, currencyPosition: .rightSpace,
                                        thousandSeparator: ".", decimalSeparator: ",", numberOfDecimals: 2)
        let sut = AddCustomAmountFormViewModel(currencySettings: settings)

        // When
        sut.setAmount(digits: "123450")

        // Then
        #expect(sut.formattedAmount == "1.234,50\u{00a0}€")
        #expect(sut.amount == "1234,50")
    }

    @Test func test_formattedAmount_when_store_has_no_fraction_digits_then_formats_whole_yen_amount() {
        // Given
        let settings = CurrencySettings(currencyCode: .JPY, currencyPosition: .left,
                                        thousandSeparator: ",", decimalSeparator: ".", numberOfDecimals: 0)
        let sut = AddCustomAmountFormViewModel(currencySettings: settings)

        // When
        sut.setAmount(digits: "1500")

        // Then
        #expect(sut.formattedAmount == settings.symbol(from: .JPY) + "1,500")
    }

    @Test func test_formattedAmount_when_amount_changes_then_reflects_latest_draft() {
        // Given
        let sut = AddCustomAmountFormViewModel(currencySettings: currencySettings)
        sut.setAmount("10.00")
        let previousDisplay = sut.formattedAmount

        // When
        sut.setAmount("25.00")

        // Then
        #expect(previousDisplay == "$10.00")
        #expect(sut.formattedAmount == "$25.00")
    }

    @Test func test_isAddEnabled_when_amount_is_empty_then_false() async throws {
        // Given
        let sut = AddCustomAmountFormViewModel(currencySettings: currencySettings)

        // When, Then
        #expect(sut.isAddEnabled == false)
    }

    @Test func test_isAddEnabled_when_amount_is_zero_then_false() async throws {
        // Given
        let sut = AddCustomAmountFormViewModel(currencySettings: currencySettings)

        // When
        sut.amount = "0.00"

        // Then
        #expect(sut.isAddEnabled == false)
    }

    @Test func test_isAddEnabled_when_amount_is_positive_then_true() async throws {
        // Given
        let sut = AddCustomAmountFormViewModel(currencySettings: currencySettings)

        // When
        sut.amount = "10.00"

        // Then
        #expect(sut.isAddEnabled == true)
    }

    @Test func test_resolvedCustomAmount_when_amount_is_invalid_then_returns_nil() async throws {
        // Given
        let sut = AddCustomAmountFormViewModel(currencySettings: currencySettings)

        // When
        sut.amount = ""

        // Then
        #expect(sut.resolvedCustomAmount() == nil)
    }

    @Test func test_resolvedCustomAmount_when_amount_valid_and_name_empty_then_returns_default_name() async throws {
        // Given
        let sut = AddCustomAmountFormViewModel(currencySettings: currencySettings)

        // When
        sut.amount = "12.50"
        sut.name = ""

        // Then
        let input = try #require(sut.resolvedCustomAmount())
        #expect(input.name == "Custom amount")
        #expect(input.amount == "12.50")
        #expect(input.isTaxable == false)
    }

    @Test func test_resolvedCustomAmount_when_name_has_whitespace_only_then_uses_default_name() async throws {
        // Given
        let sut = AddCustomAmountFormViewModel(currencySettings: currencySettings)

        // When
        sut.amount = "5.00"
        sut.name = "   "

        // Then
        let input = try #require(sut.resolvedCustomAmount())
        #expect(input.name == "Custom amount")
    }

    @Test func test_resolvedCustomAmount_when_name_is_provided_then_uses_trimmed_name() async throws {
        // Given
        let sut = AddCustomAmountFormViewModel(currencySettings: currencySettings)

        // When
        sut.amount = "5.00"
        sut.name = "  Service fee  "

        // Then
        let input = try #require(sut.resolvedCustomAmount())
        #expect(input.name == "Service fee")
    }

    @Test func test_resolvedCustomAmount_when_isTaxable_is_true_then_input_reflects_it() async throws {
        // Given
        let sut = AddCustomAmountFormViewModel(currencySettings: currencySettings)

        // When
        sut.amount = "5.00"
        sut.isTaxable = true

        // Then
        let input = try #require(sut.resolvedCustomAmount())
        #expect(input.isTaxable == true)
    }

    @Test func test_isTaxable_when_creating_new_amount_then_defaults_to_false() async throws {
        // Given
        let sut = AddCustomAmountFormViewModel(currencySettings: currencySettings)

        // When, Then
        #expect(sut.isTaxable == false)
    }

    @Test func test_setAmount_when_input_is_valid_then_updates_amount() async throws {
        // Given
        let sut = AddCustomAmountFormViewModel(currencySettings: currencySettings)

        // When
        sut.setAmount("12.34")

        // Then
        #expect(sut.amount == "12.34")
    }

    @Test func test_setAmount_when_input_is_invalid_then_keeps_previous_amount() async throws {
        // Given
        let sut = AddCustomAmountFormViewModel(currencySettings: currencySettings)
        sut.setAmount("12.34")

        // When — too many decimals for a 2-fraction-digit currency
        sut.setAmount("12.345")

        // Then
        #expect(sut.amount == "12.34")
    }

    @Test(arguments: [("1234", "12.34"), ("123456", "1234.56"), ("5", "0.05")])
    func test_setAmount_digits_when_currency_has_two_fraction_digits_then_fills_from_the_right(
        digits: String, expected: String
    ) async throws {
        // Given
        let sut = AddCustomAmountFormViewModel(currencySettings: currencySettings)

        // When
        sut.setAmount(digits: digits)

        // Then
        #expect(sut.amount == expected)
        #expect(sut.isAddEnabled == true)
    }

    @Test func test_setAmount_digits_when_store_uses_comma_and_no_fraction_digits_then_has_no_separators() async throws {
        // Given
        let settings = CurrencySettings(currencyCode: .JPY,
                                        currencyPosition: .left,
                                        thousandSeparator: ".",
                                        decimalSeparator: ",",
                                        numberOfDecimals: 0)
        let sut = AddCustomAmountFormViewModel(currencySettings: settings)

        // When
        sut.setAmount(digits: "1500")

        // Then
        #expect(sut.amount == "1500")
        #expect(sut.resolvedCustomAmount()?.amount == "1500")
    }

    @Test func test_setAmount_digits_when_store_uses_comma_decimal_separator_then_uses_it() async throws {
        // Given
        let settings = CurrencySettings(currencyCode: .EUR,
                                        currencyPosition: .right,
                                        thousandSeparator: ".",
                                        decimalSeparator: ",",
                                        numberOfDecimals: 2)
        let sut = AddCustomAmountFormViewModel(currencySettings: settings)

        // When
        sut.setAmount(digits: "123450")

        // Then
        #expect(sut.amount == "1234,50")
        #expect(sut.isAddEnabled == true)
    }

    @Test func test_setAmount_digits_when_digits_are_cleared_then_amount_is_empty_and_add_is_disabled() async throws {
        // Given
        let sut = AddCustomAmountFormViewModel(currencySettings: currencySettings)
        sut.setAmount(digits: "1234")

        // When
        sut.setAmount(digits: "")

        // Then
        #expect(sut.amount.isEmpty)
        #expect(sut.isAddEnabled == false)
    }

    @Test(arguments: [(".", 2, "25.00", "2500", "25.00"),
                      (",", 2, "1234,50", "123450", "1.234,50"),
                      (".", 0, "1500", "1500", "1,500")])
    func test_makeAmountInputState_when_form_changes_amount_then_restores_current_draft(
        separator: String, decimals: Int, amount: String, digits: String, display: String
    ) throws {
        // Given
        let settings = CurrencySettings(currencyCode: .USD,
                                        currencyPosition: .left,
                                        thousandSeparator: separator == "." ? "," : ".",
                                        decimalSeparator: separator,
                                        numberOfDecimals: decimals)
        let sut = AddCustomAmountFormViewModel(currencySettings: settings)
        sut.setAmount(digits: "1000")
        let previousInput = sut.makeAmountInputState()
        sut.setAmount(amount)

        // When
        let restoredInput = sut.makeAmountInputState()

        // Then
        #expect(restoredInput != previousInput)
        #expect(restoredInput.inputDigits == digits)
        #expect(restoredInput.displayText == display)
        #expect(restoredInput.amount == display)
        #expect(try #require(sut.resolvedCustomAmount()).amount == amount)
    }

    @Test func test_makeAmountInputState_when_amount_is_empty_then_leaves_input_empty() {
        // Given
        let sut = AddCustomAmountFormViewModel(currencySettings: currencySettings)
        sut.setAmount(digits: "1000")
        sut.setAmount("")

        // When
        let input = sut.makeAmountInputState()

        // Then
        #expect(input == POSCashAmountInputState())
        #expect(sut.isAddEnabled == false)
    }

    @Test func test_makeAmountInputState_when_typing_after_restoration_then_replaces_previous_value() throws {
        // Given
        let sut = AddCustomAmountFormViewModel(currencySettings: currencySettings)
        sut.setAmount(digits: "1000")
        sut.setAmount("25.00")
        let input = sut.makeAmountInputState()
        let formatter = POSCashAmountInputFormatter(currencySettings: currencySettings)

        // When
        let digits = try #require(formatter.applyingEdit(from: input.displayText,
                                                        to: input.displayText + "7",
                                                        currentDigits: input.inputDigits,
                                                        isReplacingPreset: input.isDisplayingPreset))
        sut.setAmount(digits: digits)

        // Then
        #expect(sut.amount == "0.07")
        #expect(sut.resolvedCustomAmount()?.amount == "0.07")
    }

    @Test func test_makeAmountDraft_when_edited_then_leaves_details_unchanged() throws {
        // Given
        let existing = POSCustomAmount(name: "Service fee", amount: "10.00", isTaxable: true)
        let sut = AddCustomAmountFormViewModel(currencySettings: currencySettings, editing: existing)
        let draft = sut.makeAmountDraft()

        // When
        draft.setAmount(digits: "2500")

        // Then
        #expect(draft.amount == "25.00")
        #expect(try #require(sut.resolvedCustomAmount()) == existing)
    }

    @Test func test_makeAmountDraft_when_saved_then_updates_only_amount_and_preserves_item_identity() throws {
        // Given
        let existing = POSCustomAmount(name: "Service fee", amount: "10.00", isTaxable: true)
        let sut = AddCustomAmountFormViewModel(currencySettings: currencySettings, editing: existing)
        let draft = sut.makeAmountDraft()
        draft.setAmount(digits: "2500")

        // When
        sut.setAmount(draft.amount)

        // Then
        let result = try #require(sut.resolvedCustomAmount())
        #expect(result.id == existing.id)
        #expect(result.amount == "25.00")
        #expect(result.name == existing.name)
        #expect(result.isTaxable == existing.isTaxable)
    }

    @Test func test_makeAmountDraft_when_invalid_edit_is_discarded_then_reopening_uses_details_amount() {
        // Given
        let sut = AddCustomAmountFormViewModel(currencySettings: currencySettings)
        sut.setAmount("10.00")
        let discardedDraft = sut.makeAmountDraft()
        discardedDraft.setAmount(digits: "")

        // When
        let reopenedDraft = sut.makeAmountDraft()

        // Then
        #expect(discardedDraft.isAddEnabled == false)
        #expect(reopenedDraft.amount == "10.00")
        #expect(reopenedDraft.isAddEnabled)
        #expect(reopenedDraft.makeAmountInputState().inputDigits == "1000")
    }

    @Test func test_makeAmountDraft_when_store_uses_comma_decimals_then_preserves_currency_settings() {
        // Given
        let settings = CurrencySettings(currencyCode: .EUR, currencyPosition: .right,
                                        thousandSeparator: ".", decimalSeparator: ",", numberOfDecimals: 2)
        let sut = AddCustomAmountFormViewModel(currencySettings: settings)
        sut.setAmount("1234,50")

        // When
        let draft = sut.makeAmountDraft()
        draft.setAmount(digits: "2500")

        // Then
        #expect(draft.amount == "25,00")
        #expect(sut.amount == "1234,50")
    }

    @Test(arguments: [true, false])
    func test_init_when_editing_existing_then_prefills_fields(isTaxable: Bool) async throws {
        // Given
        let id = UUID()
        let existing = POSCustomAmount(id: id, name: "Service fee", amount: "7.50", isTaxable: isTaxable)

        // When
        let sut = AddCustomAmountFormViewModel(currencySettings: currencySettings, editing: existing)

        // Then
        #expect(sut.isEditing == true)
        #expect(sut.amount == "7.50")
        #expect(sut.name == "Service fee")
        #expect(sut.isTaxable == isTaxable)
    }

    @Test func test_init_when_editing_existing_with_default_name_then_leaves_name_field_empty() async throws {
        // Given
        let existing = POSCustomAmount(name: AddCustomAmountFormViewModel.Localization.defaultName, amount: "5.00", isTaxable: true)

        // When
        let sut = AddCustomAmountFormViewModel(currencySettings: currencySettings, editing: existing)

        // Then
        #expect(sut.name.isEmpty)
    }

    @Test func test_resolvedCustomAmount_when_editing_then_keeps_existing_id() async throws {
        // Given
        let id = UUID()
        let existing = POSCustomAmount(id: id, name: "Service fee", amount: "7.50", isTaxable: false)
        let sut = AddCustomAmountFormViewModel(currencySettings: currencySettings, editing: existing)

        // When
        sut.amount = "9.00"

        // Then
        let updated = try #require(sut.resolvedCustomAmount())
        #expect(updated.id == id)
        #expect(updated.amount == "9.00")
    }

    @Test func test_resolvedCustomAmount_when_called_repeatedly_then_keeps_the_same_id() async throws {
        // Given
        let sut = AddCustomAmountFormViewModel(currencySettings: currencySettings)
        sut.amount = "5.00"

        // When
        let first = try #require(sut.resolvedCustomAmount())
        let second = try #require(sut.resolvedCustomAmount())

        // Then
        #expect(first.id == second.id)
    }

    @Test func test_resolvedCustomAmount_when_adding_then_uses_a_fresh_id_per_form() async throws {
        // Given
        let firstForm = AddCustomAmountFormViewModel(currencySettings: currencySettings)
        let secondForm = AddCustomAmountFormViewModel(currencySettings: currencySettings)
        firstForm.amount = "5.00"
        secondForm.amount = "5.00"

        // When
        let first = try #require(firstForm.resolvedCustomAmount())
        let second = try #require(secondForm.resolvedCustomAmount())

        // Then
        #expect(first.id != second.id)
    }
}
