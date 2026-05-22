import Foundation

enum OrderSummary {
    static let detailLineItemLimit = 15
    // Kept modest because the list path multiplies this cap across every order row,
    // so it weighs far heavier on the payload budget than the single-order detail cap.
    static let listLineItemLimit = 7
    static let adjustmentLineLimit = 10
    static let customerNoteLimit = 500

    static func make(from entity: AnyCodableJSON) -> AnyCodableJSON {
        orderRow(from: entity, lineItemLimit: detailLineItemLimit)
    }

    static func orderRow(from entity: AnyCodableJSON, lineItemLimit: Int) -> AnyCodableJSON {
        let projected = RESTResponseParsing.project(entity, keys: [
            "id", "number", "status", "total", "currency",
            "date_created", "date_modified", "payment_method_title",
            "customer_id", "date_paid", "total_tax",
            "shipping_total", "discount_total"
        ])
        guard case .object(var fields) = projected else { return projected }

        if let billing = RESTResponseParsing.objectField(entity, "billing") {
            if let name = customerName(from: billing) {
                fields["customer_name"] = .string(name)
            }
            if let email = RESTResponseParsing.stringField(billing, "email") {
                fields["customer_email"] = .string(email)
            }
            fields["billing"] = compactAddress(billing, includeEmail: true)
        }
        if let shipping = RESTResponseParsing.objectField(entity, "shipping") {
            fields["shipping"] = compactAddress(shipping, includeEmail: false)
        }

        if let note = RESTResponseParsing.stringField(entity, "customer_note") {
            let capped = capCustomerNote(note)
            fields["customer_note"] = .string(capped.value)
            if capped.truncated {
                fields["customer_note_truncated"] = .bool(true)
            }
        }

        let allLineItems = RESTResponseParsing.arrayItems(
            RESTResponseParsing.objectField(entity, "line_items") ?? .null
        ) ?? []
        fields["line_items_count"] = .int(Int64(allLineItems.count))
        if allLineItems.count > lineItemLimit {
            fields["line_items_truncated"] = .bool(true)
        }
        fields["line_items"] = .array(allLineItems.prefix(lineItemLimit).map(compactLineItem))

        let coupons = RESTResponseParsing.arrayItems(
            RESTResponseParsing.objectField(entity, "coupon_lines") ?? .null
        ) ?? []
        fields["coupon_lines"] = .array(coupons.prefix(adjustmentLineLimit).map(compactCouponLine))

        let fees = RESTResponseParsing.arrayItems(
            RESTResponseParsing.objectField(entity, "fee_lines") ?? .null
        ) ?? []
        fields["fee_lines"] = .array(fees.prefix(adjustmentLineLimit).map(compactFeeLine))

        let taxes = RESTResponseParsing.arrayItems(
            RESTResponseParsing.objectField(entity, "tax_lines") ?? .null
        ) ?? []
        fields["tax_lines"] = .array(taxes.prefix(adjustmentLineLimit).map(compactTaxLine))

        return .object(fields)
    }

    private static func customerName(from billing: AnyCodableJSON) -> String? {
        let first = RESTResponseParsing.stringField(billing, "first_name") ?? ""
        let last = RESTResponseParsing.stringField(billing, "last_name") ?? ""
        let combined = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
        return combined.isEmpty ? nil : combined
    }

    private static func compactAddress(_ source: AnyCodableJSON, includeEmail: Bool) -> AnyCodableJSON {
        var keys = ["first_name", "last_name", "phone", "city", "state", "postcode", "country"]
        if includeEmail { keys.insert("email", at: 2) }
        var out: [String: AnyCodableJSON] = [:]
        for key in keys {
            if let raw = RESTResponseParsing.stringField(source, key), !raw.isEmpty {
                out[key] = .string(raw)
            }
        }
        return .object(out)
    }

    private static func compactLineItem(_ item: AnyCodableJSON) -> AnyCodableJSON {
        var out: [String: AnyCodableJSON] = [:]
        if let id = RESTResponseParsing.intField(item, "id") { out["id"] = .int(id) }
        if let name = RESTResponseParsing.stringField(item, "name") { out["name"] = .string(name) }
        if let qty = RESTResponseParsing.intField(item, "quantity") { out["quantity"] = .int(qty) }
        if let sku = RESTResponseParsing.stringField(item, "sku") { out["sku"] = .string(sku) }
        if let total = RESTResponseParsing.stringField(item, "total") { out["total"] = .string(total) }
        if let target = lineItemTarget(from: item) { out["target"] = target }
        return .object(out)
    }

    /// Pre-bakes the products_update target shape so the model never has to interpret
    /// product_id vs variation_id; copying `target` straight into a write call is unambiguous.
    static func lineItemTarget(from item: AnyCodableJSON) -> AnyCodableJSON? {
        let productID = RESTResponseParsing.intField(item, "product_id") ?? 0
        let variationID = RESTResponseParsing.intField(item, "variation_id") ?? 0
        if variationID > 0 {
            return .object([
                "kind": .string("variation"),
                "id": .int(variationID),
                "parent_id": .int(productID)
            ])
        }
        if productID > 0 {
            return .object([
                "kind": .string("product"),
                "id": .int(productID)
            ])
        }
        return nil
    }

    private static func compactCouponLine(_ item: AnyCodableJSON) -> AnyCodableJSON {
        var out: [String: AnyCodableJSON] = [:]
        if let id = RESTResponseParsing.intField(item, "id") { out["id"] = .int(id) }
        if let code = RESTResponseParsing.stringField(item, "code") { out["code"] = .string(code) }
        if let discount = RESTResponseParsing.stringField(item, "discount") { out["discount"] = .string(discount) }
        if let tax = RESTResponseParsing.stringField(item, "discount_tax") { out["discount_tax"] = .string(tax) }
        return .object(out)
    }

    private static func compactFeeLine(_ item: AnyCodableJSON) -> AnyCodableJSON {
        var out: [String: AnyCodableJSON] = [:]
        if let id = RESTResponseParsing.intField(item, "id") { out["id"] = .int(id) }
        if let name = RESTResponseParsing.stringField(item, "name") { out["name"] = .string(name) }
        if let total = RESTResponseParsing.stringField(item, "total") { out["total"] = .string(total) }
        if let totalTax = RESTResponseParsing.stringField(item, "total_tax") { out["total_tax"] = .string(totalTax) }
        if let status = RESTResponseParsing.stringField(item, "tax_status") { out["tax_status"] = .string(status) }
        return .object(out)
    }

    private static func compactTaxLine(_ item: AnyCodableJSON) -> AnyCodableJSON {
        var out: [String: AnyCodableJSON] = [:]
        if let id = RESTResponseParsing.intField(item, "id") { out["id"] = .int(id) }
        if let rateID = RESTResponseParsing.intField(item, "rate_id") { out["rate_id"] = .int(rateID) }
        if let code = RESTResponseParsing.stringField(item, "rate_code") { out["rate_code"] = .string(code) }
        if let label = RESTResponseParsing.stringField(item, "label") { out["label"] = .string(label) }
        if let total = RESTResponseParsing.stringField(item, "tax_total") { out["tax_total"] = .string(total) }
        if let shipping = RESTResponseParsing.stringField(item, "shipping_tax_total") {
            out["shipping_tax_total"] = .string(shipping)
        }
        return .object(out)
    }

    private struct CappedText {
        let value: String
        let truncated: Bool
    }

    private static func capCustomerNote(_ value: String) -> CappedText {
        if value.count > customerNoteLimit {
            return CappedText(value: String(value.prefix(customerNoteLimit)), truncated: true)
        }
        return CappedText(value: value, truncated: false)
    }
}
