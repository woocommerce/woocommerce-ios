import Testing
@testable import Hardware

struct ReceiptLineItemTests {
    @Test func test_attributesDescription_joins_attributes_with_comma() {
        // Given
        let item = makeItem(attributes: [ReceiptLineAttribute(name: "Color", value: "Blue"),
                                         ReceiptLineAttribute(name: "Size", value: "M")])

        // When / Then
        #expect(item.attributesDescription == "Color Blue, Size M")
    }

    @Test func test_attributesDescription_when_no_attributes_then_is_empty() {
        // Given
        let item = makeItem(attributes: [])

        // When / Then
        #expect(item.attributesDescription.isEmpty)
    }

    @Test func test_attributesDescription_trims_whitespace_and_drops_empty_entries() {
        // Given
        let item = makeItem(attributes: [ReceiptLineAttribute(name: " ", value: " "),
                                         ReceiptLineAttribute(name: "Color", value: "Blue")])

        // When / Then
        #expect(item.attributesDescription == "Color Blue")
    }
}

private extension ReceiptLineItemTests {
    func makeItem(attributes: [ReceiptLineAttribute]) -> ReceiptLineItem {
        ReceiptLineItem(title: "T-Shirt", quantity: "1", amount: "$25.00", attributes: attributes)
    }
}
