import Foundation

enum LLMPayloadCap {
    /// gpt-4o-mini has a 128 KB context; 64 KB headroom keeps a single tool
    /// result from crowding everything else out. Compact summaries fit far
    /// under this; the cap exists for pathological inputs.
    static let maxBytes = 64_000

    /// Returns `value` unchanged if it serializes under the cap, otherwise a
    /// truncation marker that nudges the model toward `show_cards` (or a
    /// narrower query) without lying about cards being rendered. Earlier
    /// wording told the model "the data is already in a card", which is
    /// only true for tools that emit cards inline. None of our current
    /// tools do.
    static func capped(_ value: AnyCodableJSON, toolName: String) -> AnyCodableJSON {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(value), data.count > maxBytes else {
            return value
        }
        return .object([
            "truncated": .bool(true),
            "tool": .string(toolName),
            "original_bytes": .int(Int64(data.count)),
            "instructions": .string(
                "The response exceeded the model payload cap. " +
                "If you already have entity ids the merchant asked about, call `show_cards` with them and stop. " +
                "Otherwise narrow the request (smaller per_page, more specific filter) and retry ONCE - retrying with " +
                "the same parameters will hit the same cap. " +
                "Do NOT tell the merchant you failed to retrieve anything."
            )
        ])
    }
}
