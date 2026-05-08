import Foundation

enum ProductVariationDetailSummary {
    static func make(from entity: AnyCodableJSON) -> AnyCodableJSON {
        let projected = RESTResponseParsing.project(entity, keys: [
            "id", "status", "sku", "price", "regular_price", "sale_price",
            "on_sale", "manage_stock", "stock_quantity", "stock_status",
            "weight", "tax_class", "date_created", "date_modified",
            "menu_order", "backorders", "permalink", "parent_id"
        ])
        guard case .object(var fields) = projected else { return projected }

        // WC variation REST stores parent under parent_id; CardFamily injects
        // it for the show_cards path so consumers can rely on parent_id.
        if fields["parent_id"] != nil {
            fields["product_id"] = fields["parent_id"]
        }

        let attributes = RESTResponseParsing.arrayItems(
            RESTResponseParsing.objectField(entity, "attributes") ?? .null
        ) ?? []
        fields["attributes"] = .array(attributes.map(compactAttribute))

        if let image = RESTResponseParsing.objectField(entity, "image") {
            fields["image"] = compactImage(image)
        }

        if let description = RESTResponseParsing.stringField(entity, "description") {
            let capped = ProductSummary.capText(description)
            fields["description"] = .string(capped.value)
            if capped.truncated {
                fields["description_truncated"] = .bool(true)
            }
        }

        if let dimensions = RESTResponseParsing.objectField(entity, "dimensions") {
            fields["dimensions"] = compactDimensions(dimensions)
        }

        return .object(fields)
    }

    private static func compactAttribute(_ item: AnyCodableJSON) -> AnyCodableJSON {
        var out: [String: AnyCodableJSON] = [:]
        if let id = RESTResponseParsing.intField(item, "id") { out["id"] = .int(id) }
        if let name = RESTResponseParsing.stringField(item, "name") { out["name"] = .string(name) }
        if let option = RESTResponseParsing.stringField(item, "option") { out["option"] = .string(option) }
        return .object(out)
    }

    private static func compactImage(_ source: AnyCodableJSON) -> AnyCodableJSON {
        var out: [String: AnyCodableJSON] = [:]
        if let id = RESTResponseParsing.intField(source, "id") { out["id"] = .int(id) }
        if let src = RESTResponseParsing.stringField(source, "src"), !src.isEmpty {
            out["src"] = .string(src)
        }
        if let alt = RESTResponseParsing.stringField(source, "alt"), !alt.isEmpty {
            out["alt"] = .string(alt)
        }
        if let name = RESTResponseParsing.stringField(source, "name"), !name.isEmpty {
            out["name"] = .string(name)
        }
        return .object(out)
    }

    private static func compactDimensions(_ source: AnyCodableJSON) -> AnyCodableJSON {
        var out: [String: AnyCodableJSON] = [:]
        for key in ["length", "width", "height"] {
            if let value = RESTResponseParsing.stringField(source, key), !value.isEmpty {
                out[key] = .string(value)
            }
        }
        return .object(out)
    }
}
