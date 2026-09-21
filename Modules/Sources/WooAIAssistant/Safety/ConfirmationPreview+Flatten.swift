import Foundation

extension ConfirmationPreview {
    public func flattenedSummary() -> String {
        let head = summary.flattened()
        guard !fields.isEmpty else { return head }
        let parts = fields.map { field -> String in
            let label = field.label.flattened()
            let value = field.value.flattened()
            if let prior = field.priorValue?.flattened() {
                return "\(label) \(prior) -> \(value)"
            }
            return "\(label) \(value)"
        }
        return "\(head): \(parts.joined(separator: ", "))"
    }
}

extension ConfirmationPreviewText {
    public func flattened() -> String {
        switch self {
        case .raw(let value):
            return value
        case .localized(let resource, let args):
            return Self.format(resource: resource, args: args)
        case .quantity(let count, let singular, let plural, let args):
            let resource = count == 1 ? singular : plural
            return Self.format(resource: resource, args: args)
        }
    }

    private static func format(resource: LocalizedStringResource,
                               args: [ConfirmationPreviewText]) -> String {
        let template = String(localized: resource)
        guard !args.isEmpty else { return template }
        let rendered = args.map { $0.flattened() }
        return String(format: template, arguments: rendered.map { $0 as CVarArg })
    }
}
