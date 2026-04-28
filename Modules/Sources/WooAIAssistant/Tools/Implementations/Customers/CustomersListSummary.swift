import Foundation

enum CustomersListSummary {
    static func make(from rows: [AnyCodableJSON]) -> AnyCodableJSON {
        var ids: [AnyCodableJSON] = []
        var matches: [AnyCodableJSON] = []
        for row in rows {
            guard let id = RESTResponseParsing.intField(row, "id") else { continue }
            ids.append(.int(id))
            var match: [String: AnyCodableJSON] = ["id": .int(id)]
            if let first = RESTResponseParsing.stringField(row, "first_name") {
                match["first_name"] = .string(first)
            }
            if let last = RESTResponseParsing.stringField(row, "last_name") {
                match["last_name"] = .string(last)
            }
            if let email = RESTResponseParsing.stringField(row, "email") {
                match["email"] = .string(email)
            }
            matches.append(.object(match))
        }
        return .object([
            "count": .int(Int64(rows.count)),
            "ids": .array(ids),
            "matches": .array(matches)
        ])
    }
}
