import Foundation

public struct ConfirmationPreview: Equatable, Sendable {
    public let summary: ConfirmationPreviewText
    public let fields: [ConfirmationPreviewField]
    public let isBulk: Bool

    public init(summary: ConfirmationPreviewText,
                fields: [ConfirmationPreviewField] = [],
                isBulk: Bool = false) {
        self.summary = summary
        self.fields = fields
        self.isBulk = isBulk
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
