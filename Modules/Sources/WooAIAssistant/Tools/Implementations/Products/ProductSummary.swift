import Foundation

enum ProductSummary {
    enum ImageProjection {
        case array
        case singleImage
    }

    static func make(from entity: AnyCodableJSON) -> AnyCodableJSON {
        project(entity, imageProjection: .array)
    }

    static func listRow(from entity: AnyCodableJSON) -> AnyCodableJSON {
        project(entity, imageProjection: .singleImage)
    }

    private static func project(_ entity: AnyCodableJSON, imageProjection: ImageProjection) -> AnyCodableJSON {
        let projected = RESTResponseParsing.project(entity, keys: [
            "id", "name", "sku", "price", "stock_status", "type", "status",
            "stock_quantity", "regular_price", "sale_price",
            "on_sale", "manage_stock", "date_created", "date_modified",
            "total_sales", "parent_id", "permalink",
            "shipping_class", "weight"
        ])
        guard case .object(var fields) = projected else { return projected }

        let categories = RESTResponseParsing.arrayItems(
            RESTResponseParsing.objectField(entity, "categories") ?? .null
        ) ?? []
        fields["categories"] = .array(categories.prefix(ProductResponseLimits.categoriesLimit).map(compactTerm))
        fields["categories_count"] = .int(Int64(categories.count))
        if categories.count > ProductResponseLimits.categoriesLimit {
            fields["categories_truncated"] = .bool(true)
        }

        let tags = RESTResponseParsing.arrayItems(
            RESTResponseParsing.objectField(entity, "tags") ?? .null
        ) ?? []
        if !tags.isEmpty {
            fields["tags"] = .array(tags.map(compactTerm))
        }

        let attributes = RESTResponseParsing.arrayItems(
            RESTResponseParsing.objectField(entity, "attributes") ?? .null
        ) ?? []
        fields["attributes"] = .array(attributes.prefix(ProductResponseLimits.attributesLimit).map(compactAttribute))
        if attributes.count > ProductResponseLimits.attributesLimit {
            fields["attributes_truncated"] = .bool(true)
        }

        let variations = RESTResponseParsing.arrayItems(
            RESTResponseParsing.objectField(entity, "variations") ?? .null
        ) ?? []
        fields["variations_count"] = .int(Int64(variations.count))
        let variationIDs = variations.compactMap { item -> Int64? in
            switch item {
            case .int(let value): return value
            case .double(let value): return Int64(value)
            default: return nil
            }
        }
        fields["variation_ids"] = .array(variationIDs.prefix(ProductResponseLimits.variationIdsLimit).map { .int($0) })
        if variationIDs.count > ProductResponseLimits.variationIdsLimit {
            fields["variation_ids_truncated"] = .bool(true)
        }

        let images = RESTResponseParsing.arrayItems(
            RESTResponseParsing.objectField(entity, "images") ?? .null
        ) ?? []
        switch imageProjection {
        case .array:
            fields["images"] = .array(images.prefix(ProductResponseLimits.imagesLimit).map(compactImage))
            if images.count > ProductResponseLimits.imagesLimit {
                fields["images_truncated"] = .bool(true)
            }
        case .singleImage:
            if let first = images.first {
                fields["image"] = compactImage(first)
            }
        }

        if let description = RESTResponseParsing.stringField(entity, "description") {
            let capped = capText(description)
            fields["description"] = .string(capped.value)
            if capped.truncated {
                fields["description_truncated"] = .bool(true)
            }
        }
        if let short = RESTResponseParsing.stringField(entity, "short_description") {
            let capped = capText(short)
            fields["short_description"] = .string(capped.value)
            if capped.truncated {
                fields["short_description_truncated"] = .bool(true)
            }
        }

        if let dimensions = RESTResponseParsing.objectField(entity, "dimensions") {
            fields["dimensions"] = compactDimensions(dimensions)
        }

        if let crossSell = idArray(from: entity, key: "cross_sell_ids") {
            fields["cross_sell_ids"] = crossSell
        }
        if let upsell = idArray(from: entity, key: "upsell_ids") {
            fields["upsell_ids"] = upsell
        }
        if let related = idArray(from: entity, key: "related_ids") {
            fields["related_ids"] = related
        }

        return .object(fields)
    }

    private static func compactTerm(_ item: AnyCodableJSON) -> AnyCodableJSON {
        var out: [String: AnyCodableJSON] = [:]
        if let id = RESTResponseParsing.intField(item, "id") { out["id"] = .int(id) }
        if let name = RESTResponseParsing.stringField(item, "name") { out["name"] = .string(name) }
        if let slug = RESTResponseParsing.stringField(item, "slug") { out["slug"] = .string(slug) }
        return .object(out)
    }

    private static func compactAttribute(_ item: AnyCodableJSON) -> AnyCodableJSON {
        var out: [String: AnyCodableJSON] = [:]
        if let id = RESTResponseParsing.intField(item, "id") { out["id"] = .int(id) }
        if let name = RESTResponseParsing.stringField(item, "name") { out["name"] = .string(name) }
        if case .object(let dict) = item {
            if case .bool(let visible) = dict["visible"] {
                out["visible"] = .bool(visible)
            }
            if case .bool(let variation) = dict["variation"] {
                out["variation"] = .bool(variation)
            }
            if case .array(let options) = dict["options"] {
                out["options"] = .array(options.compactMap { value in
                    if case .string = value { return value }
                    return nil
                })
            }
        }
        return .object(out)
    }

    private static func compactImage(_ item: AnyCodableJSON) -> AnyCodableJSON {
        var out: [String: AnyCodableJSON] = [:]
        if let id = RESTResponseParsing.intField(item, "id") { out["id"] = .int(id) }
        if let src = RESTResponseParsing.stringField(item, "src"), !src.isEmpty {
            out["src"] = .string(src)
        }
        if let alt = RESTResponseParsing.stringField(item, "alt"), !alt.isEmpty {
            out["alt"] = .string(alt)
        }
        if let name = RESTResponseParsing.stringField(item, "name"), !name.isEmpty {
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

    private static func idArray(from entity: AnyCodableJSON, key: String) -> AnyCodableJSON? {
        guard case .array(let raw) = RESTResponseParsing.objectField(entity, key) ?? .null else {
            return nil
        }
        let ids = raw.compactMap { item -> Int64? in
            switch item {
            case .int(let value): return value
            case .double(let value): return Int64(value)
            default: return nil
            }
        }
        return .array(ids.map { .int($0) })
    }

    struct CappedText {
        let value: String
        let truncated: Bool
    }

    static func capText(_ value: String) -> CappedText {
        if value.count > ProductResponseLimits.textFieldLimit {
            return CappedText(value: String(value.prefix(ProductResponseLimits.textFieldLimit)), truncated: true)
        }
        return CappedText(value: value, truncated: false)
    }
}
