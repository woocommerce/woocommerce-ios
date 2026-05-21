import Foundation

public struct ConfirmationPreview: Equatable, Sendable {
    public let summary: ConfirmationPreviewText
    public let fields: [ConfirmationPreviewField]
    public let isBulk: Bool
    /// Per-entity rows surfaced under the summary on bulk previews so the
    /// merchant can see which ids - and where possible which names - the
    /// pending change applies to before approving.
    public let bulkEntries: [ConfirmationBulkEntry]

    public init(summary: ConfirmationPreviewText,
                fields: [ConfirmationPreviewField] = [],
                isBulk: Bool = false,
                bulkEntries: [ConfirmationBulkEntry] = []) {
        self.summary = summary
        self.fields = fields
        self.isBulk = isBulk
        self.bulkEntries = bulkEntries
    }

    /// True only when there is nothing else to render in the card body. The summary already shows as
    /// the card title, so repeating it in the body is redundant whenever fields or bulk rows exist.
    public var showsSummaryInBody: Bool {
        fields.isEmpty && bulkEntries.isEmpty
    }
}

public struct ConfirmationPreviewField: Equatable, Sendable {
    public let name: String
    public let label: ConfirmationPreviewText
    public let value: ConfirmationPreviewText
    public let priorValue: ConfirmationPreviewText?
    /// Per-entity rendered values keyed by target id. Populated when an update sets the same
    /// field across multiple entries but the value diverges, so the card lists which id gets
    /// which value instead of hiding it behind a "varies" placeholder.
    public let perEntryValues: [Int: ConfirmationPreviewText]?

    public init(name: String,
                label: ConfirmationPreviewText,
                value: ConfirmationPreviewText,
                priorValue: ConfirmationPreviewText? = nil,
                perEntryValues: [Int: ConfirmationPreviewText]? = nil) {
        self.name = name
        self.label = label
        self.value = value
        self.priorValue = priorValue
        self.perEntryValues = perEntryValues
    }
}

public indirect enum ConfirmationPreviewText: Equatable, Sendable {
    case raw(String)
    case localized(LocalizedStringResource, args: [ConfirmationPreviewText] = [])
    case quantity(Int,
                  singular: LocalizedStringResource,
                  plural: LocalizedStringResource,
                  args: [ConfirmationPreviewText] = [])
}
