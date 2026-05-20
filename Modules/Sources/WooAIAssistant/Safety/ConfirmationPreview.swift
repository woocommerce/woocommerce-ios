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

    /// The summary already shows as the card title; the body repeats it only when there are no detail rows.
    public var showsSummaryInBody: Bool {
        fields.isEmpty && bulkEntries.isEmpty
    }
}

public struct ConfirmationPreviewField: Equatable, Sendable {
    public let name: String
    public let label: ConfirmationPreviewText
    public let value: ConfirmationPreviewText
    public let priorValue: ConfirmationPreviewText?

    public init(name: String,
                label: ConfirmationPreviewText,
                value: ConfirmationPreviewText,
                priorValue: ConfirmationPreviewText? = nil) {
        self.name = name
        self.label = label
        self.value = value
        self.priorValue = priorValue
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
