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
        #expect(input.isTaxable == true)
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

    @Test func test_resolvedCustomAmount_when_isTaxable_is_false_then_input_reflects_it() async throws {
        // Given
        let sut = AddCustomAmountFormViewModel(currencySettings: currencySettings)

        // When
        sut.amount = "5.00"
        sut.isTaxable = false

        // Then
        let input = try #require(sut.resolvedCustomAmount())
        #expect(input.isTaxable == false)
    }

    @Test func test_isTaxable_default_is_true() async throws {
        // Given
        let sut = AddCustomAmountFormViewModel(currencySettings: currencySettings)

        // When, Then
        #expect(sut.isTaxable == true)
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

    @Test func test_init_when_editing_existing_then_prefills_fields() async throws {
        // Given
        let id = UUID()
        let existing = POSCustomAmount(id: id, name: "Service fee", amount: "7.50", isTaxable: false)

        // When
        let sut = AddCustomAmountFormViewModel(currencySettings: currencySettings, editing: existing)

        // Then
        #expect(sut.isEditing == true)
        #expect(sut.amount == "7.50")
        #expect(sut.name == "Service fee")
        #expect(sut.isTaxable == false)
    }

    @Test func test_init_when_editing_existing_with_default_name_then_leaves_name_field_empty() async throws {
        // Given — the cart stores the resolved name "Custom amount" when the merchant left it empty
        let existing = POSCustomAmount(name: "Custom amount", amount: "5.00", isTaxable: true)

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

    @Test func test_resolvedCustomAmount_when_adding_then_generates_fresh_id() async throws {
        // Given
        let sut = AddCustomAmountFormViewModel(currencySettings: currencySettings)
        sut.amount = "5.00"

        // When
        let first = try #require(sut.resolvedCustomAmount())
        let second = try #require(sut.resolvedCustomAmount())

        // Then — every call produces a brand-new id when not editing
        #expect(first.id != second.id)
    }
}
