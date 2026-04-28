import Foundation

enum LLMPayloadCap {
    /// gpt-4o-mini has a 128 KB context; 64 KB headroom keeps a single tool
    /// result from crowding everything else out. Compact summaries fit far
    /// under this; the cap exists for pathological inputs.
    static let maxBytes = 64_000

    /// Returns `value` unchanged if it serializes under the cap, otherwise a
    /// truncation marker that tells the model the card already answered the
    /// merchant and explicitly forbids retry. Earlier wording asked the model
    /// to "narrow the query" and gpt-4o-mini retried with different sort
    /// params, hit the same cap, and ended up apologizing while a valid card
    /// sat right above the prose.
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
                "The full data is ALREADY rendered in a card visible to the merchant. " +
                "Do NOT call this tool again - a retry will hit the same cap. " +
                "Do NOT tell the merchant you failed to retrieve anything. " +
                "Respond with AT MOST one short conversational sentence, or no text at all."
            )
        ])
    }
}
