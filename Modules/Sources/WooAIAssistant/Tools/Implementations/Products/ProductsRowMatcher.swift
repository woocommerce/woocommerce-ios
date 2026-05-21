import Foundation

struct ProductsRowMatcher {

    let args: ProductsListTool.Args
    let allowCategoryFilter: Bool

    func matches(_ row: AnyCodableJSON) -> Bool {
        matchesIDs(row)
            && matchesCategory(row)
            && matchesSKU(row)
            && matchesStatus(row)
            && matchesStockStatus(row)
            && matchesPrice(row)
            && matchesSearch(row)
    }

    private func matchesIDs(_ row: AnyCodableJSON) -> Bool {
        let idsSet: Set<Int> = Set(args.ids ?? [])
        guard !idsSet.isEmpty else { return true }
        guard let id = RESTResponseParsing.intField(row, "id") else { return false }
        return idsSet.contains(Int(id))
    }

    private func matchesCategory(_ row: AnyCodableJSON) -> Bool {
        guard allowCategoryFilter, let category = args.category else { return true }
        return Self.rowHasCategory(row, category: category)
    }

    private func matchesSKU(_ row: AnyCodableJSON) -> Bool {
        let trimmedSKU = args.sku?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        guard !trimmedSKU.isEmpty else { return true }
        let rowSKU = RESTResponseParsing.stringField(row, "sku")?
            .trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        return rowSKU == trimmedSKU
    }

    private func matchesStatus(_ row: AnyCodableJSON) -> Bool {
        let trimmed = args.status?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty, trimmed != "any" else { return true }
        return RESTResponseParsing.stringField(row, "status") == trimmed
    }

    private func matchesStockStatus(_ row: AnyCodableJSON) -> Bool {
        let trimmed = args.stockStatus?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else { return true }
        return RESTResponseParsing.stringField(row, "stock_status") == trimmed
    }

    private func matchesPrice(_ row: AnyCodableJSON) -> Bool {
        let minPrice = args.minPrice.flatMap { Decimal(string: $0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        let maxPrice = args.maxPrice.flatMap { Decimal(string: $0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        let price = Self.effectivePrice(row: row)
        if let minPrice, let price, price < minPrice { return false }
        if let maxPrice, let price, price > maxPrice { return false }
        return true
    }

    private func matchesSearch(_ row: AnyCodableJSON) -> Bool {
        let trimmed = args.search?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        guard !trimmed.isEmpty else { return true }
        let name = RESTResponseParsing.stringField(row, "name")?.lowercased() ?? ""
        let rowSKU = RESTResponseParsing.stringField(row, "sku")?.lowercased() ?? ""
        return name.contains(trimmed) || rowSKU.contains(trimmed)
    }

    private static func rowHasCategory(_ row: AnyCodableJSON, category: Int) -> Bool {
        guard case .object(let fields) = row,
              case .array(let categories) = fields["categories"] ?? .null else {
            return false
        }
        for entry in categories {
            if let identifier = RESTResponseParsing.intField(entry, "id"), Int(identifier) == category {
                return true
            }
        }
        return false
    }

    /// Variations sometimes leave `price` blank when only `regular_price` is set, so fall back
    /// to keep price filters matching the canonical price field WooCommerce displays.
    private static func effectivePrice(row: AnyCodableJSON) -> Decimal? {
        if let price = RESTResponseParsing.decimalField(row, "price") { return price }
        return RESTResponseParsing.decimalField(row, "regular_price")
    }
}
