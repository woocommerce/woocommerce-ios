import SwiftUI

struct ConfirmationCard: View {

    let proposalID: UUID
    let preview: String
    let status: ConfirmationStatus
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        BannerShell(title: cardTitle,
                    tone: tone,
                    eyebrow: eyebrowText,
                    eyebrowSymbol: eyebrowSymbol) {
            VStack(alignment: .leading, spacing: AssistantSpacing.small) {
                diffBody

                if status == .pending {
                    actionButtons
                        .padding(.top, AssistantSpacing.xSmall)
                }
            }
        }
    }

    @ViewBuilder
    private var diffBody: some View {
        VStack(alignment: .leading, spacing: AssistantSpacing.small) {
            if let parsed = ParsedPreview(text: preview) {
                VStack(alignment: .leading, spacing: AssistantSpacing.xSmall) {
                    ForEach(Array(parsed.fields.enumerated()), id: \.offset) { _, field in
                        DiffFieldRow(field: field)
                    }
                }
            } else {
                Text(preview)
                    .font(.assistantBody)
                    .foregroundStyle(Color.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var cardTitle: String {
        if let parsed = ParsedPreview(text: preview),
           let summary = parsed.summary,
           !summary.isEmpty {
            return summary
        }
        return Localization.fallbackTitle
    }

    private var eyebrowText: String {
        switch status {
        case .pending: return Localization.pending
        case .confirmed: return Localization.confirmed
        case .cancelled: return Localization.cancelled
        }
    }

    private var eyebrowSymbol: String {
        switch status {
        case .pending: return "clock.fill"
        case .confirmed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }

    private var actionButtons: some View {
        HStack(spacing: AssistantSpacing.small) {
            Button(action: onCancel) {
                Text(Localization.cancel)
                    .font(.assistantBodyEmphasized)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundStyle(Color.primary)
                    .overlay(
                        RoundedRectangle(cornerRadius: AssistantRadius.medium)
                            .stroke(Color.assistantSurfaceBorder, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Button(action: onConfirm) {
                Text(Localization.confirm)
                    .font(.assistantBodyEmphasized)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundStyle(Color.assistantOnAccent)
                    .background(Color(.accent))
                    .clipShape(RoundedRectangle(cornerRadius: AssistantRadius.medium))
            }
            .buttonStyle(.plain)
        }
    }

    private var tone: BannerTone {
        switch status {
        case .pending: return .warning
        case .confirmed: return .info
        case .cancelled: return .neutral
        }
    }

    private enum Localization {
        static let fallbackTitle = NSLocalizedString(
            "assistantChat.confirmation.title.fallback",
            value: "Proposed change",
            comment: "Generic confirmation card title used when no action summary can be inferred from the preview"
        )
        static let pending = NSLocalizedString(
            "assistantChat.confirmation.pending",
            value: "Pending change",
            comment: "Eyebrow label on a pending confirmation card in the AI Assistant chat"
        )
        static let confirmed = NSLocalizedString(
            "assistantChat.confirmation.confirmedEyebrow",
            value: "Confirmed",
            comment: "Eyebrow label on a confirmed confirmation card in the AI Assistant chat"
        )
        static let cancelled = NSLocalizedString(
            "assistantChat.confirmation.cancelled",
            value: "Cancelled",
            comment: "Eyebrow label on a cancelled confirmation card in the AI Assistant chat"
        )
        static let confirm = NSLocalizedString(
            "assistantChat.confirmation.action.confirm",
            value: "Confirm",
            comment: "Confirm button on a pending confirmation card in the AI Assistant chat"
        )
        static let cancel = NSLocalizedString(
            "assistantChat.confirmation.action.cancel",
            value: "Cancel",
            comment: "Cancel button on a pending confirmation card in the AI Assistant chat"
        )
    }
}

private struct DiffFieldRow: View {

    let field: ParsedPreview.Field

    var body: some View {
        composedLine
            .fixedSize(horizontal: false, vertical: true)
    }

    private var composedLine: Text {
        let labelPart = Text("\(field.label): ")
            .font(.assistantBody)
            .foregroundColor(Color.assistantMuted)

        if field.before.isEmpty {
            return labelPart + Text(field.after)
                .font(.assistantBodyEmphasized)
                .foregroundColor(Color.assistantBubbleAssistantText)
        }

        let beforePart = Text(field.before)
            .font(.assistantBody)
            .strikethrough(true, color: Color.assistantMuted)
            .foregroundColor(Color.assistantMuted)

        let afterPart = Text(field.after)
            .font(.assistantBodyEmphasized)
            .foregroundColor(Color.assistantBubbleAssistantText)

        return labelPart + beforePart + Text(" ") + afterPart
    }
}

struct ParsedPreview {

    struct Field {
        let label: String
        let before: String
        let after: String
    }

    let summary: String?
    let fields: [Field]

    init?(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let actionForm = Self.parseActionForm(trimmed) {
            self.summary = actionForm.summary
            self.fields = actionForm.fields
            return
        }

        var summaryLine: String?
        var rawFields: [String] = []

        let topComponents = trimmed.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        if topComponents.count == 2, Self.containsArrow(String(topComponents[1])) {
            summaryLine = topComponents[0].trimmingCharacters(in: .whitespacesAndNewlines)
            rawFields = Self.splitFieldList(String(topComponents[1]))
        } else {
            rawFields = Self.splitFieldList(trimmed)
        }

        // Any unparsed clause aborts so the merchant sees the raw preview verbatim.
        var parsedFields: [Field] = []
        for raw in rawFields {
            guard let field = Self.parseField(raw) else { return nil }
            parsedFields.append(field)
        }
        guard !parsedFields.isEmpty else { return nil }

        self.summary = summaryLine
        self.fields = parsedFields
    }

    private static func splitFieldList(_ text: String) -> [String] {
        text
            .components(separatedBy: CharacterSet(charactersIn: ";,"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func parseField(_ raw: String) -> Field? {
        let halves = splitOnArrow(raw)
        guard let halves else { return nil }

        let afterStripped = stripSideEffectSuffix(halves.after.trimmingCharacters(in: .whitespacesAndNewlines))
        let beforeRaw = halves.before.trimmingCharacters(in: .whitespacesAndNewlines)
        let after = String.assistantHumanizedValue(afterStripped)

        let beforeComponents = beforeRaw.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: false)
        let label: String
        let before: String
        if beforeComponents.count == 2 {
            label = String.assistantHumanizedToolToken(String(beforeComponents[0]))
            before = String.assistantHumanizedValue(beforeComponents[1].trimmingCharacters(in: .whitespacesAndNewlines))
        } else {
            label = String.assistantHumanizedToolToken(beforeRaw)
            before = ""
        }

        guard !after.isEmpty else { return nil }
        let cleanLabel = label.isEmpty ? Localization.fallbackLabel : label
        return Field(label: cleanLabel, before: before, after: after)
    }

    private static func splitOnArrow(_ text: String) -> (before: String, after: String)? {
        if let range = text.range(of: "→") {
            return (String(text[..<range.lowerBound]), String(text[range.upperBound...]))
        }
        if let range = text.range(of: "->") {
            return (String(text[..<range.lowerBound]), String(text[range.upperBound...]))
        }
        return nil
    }

    private static func containsArrow(_ text: String) -> Bool {
        text.contains("→") || text.contains("->")
    }

    private static func parseActionForm(_ text: String) -> (summary: String, fields: [Field])? {
        let stripped = stripSideEffectSuffix(text)
        guard let toRange = stripped.range(of: " to ", options: [.caseInsensitive, .backwards]) else {
            return nil
        }
        guard stripped.localizedCaseInsensitiveContains("set ") else { return nil }
        let head = stripped[..<toRange.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
        let after = String.assistantHumanizedValue(stripped[toRange.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines))
        guard !after.isEmpty, !head.isEmpty else { return nil }
        let summary = head
        let field = Field(label: Localization.statusLabel, before: "", after: after)
        return (summary, [field])
    }

    private static func stripSideEffectSuffix(_ text: String) -> String {
        if let parenStart = text.range(of: " (") {
            return String(text[..<parenStart.lowerBound])
        }
        return text
    }

    private enum Localization {
        static let statusLabel = NSLocalizedString(
            "assistantChat.confirmation.diff.label.status",
            value: "Status",
            comment: "Field label used in confirmation diff rows when the preview only conveys a status change"
        )
        static let fallbackLabel = NSLocalizedString(
            "assistantChat.confirmation.diff.label.fallback",
            value: "Value",
            comment: "Generic field label used in confirmation diff rows when no clearer label can be inferred"
        )
    }
}

#if DEBUG
#Preview("Pending (in chat)") {
    AssistantChatView.preview(.pendingConfirmation)
}

#Preview("Pending standalone") {
    ConfirmationCard(proposalID: UUID(),
                     preview: "Update order #3479: status processing → completed",
                     status: .pending,
                     onConfirm: {},
                     onCancel: {})
        .padding()
}

#Preview("Confirmed") {
    ConfirmationCard(proposalID: UUID(),
                     preview: "Update order #3479: status processing → completed",
                     status: .confirmed,
                     onConfirm: {},
                     onCancel: {})
        .padding()
}

#Preview("Cancelled") {
    ConfirmationCard(proposalID: UUID(),
                     preview: "Update order #3479: status processing → completed",
                     status: .cancelled,
                     onConfirm: {},
                     onCancel: {})
        .padding()
}

#Preview("Multi-field") {
    ConfirmationCard(proposalID: UUID(),
                     preview: "Update order #3479: status processing → completed; total $45.00 → $60.00",
                     status: .pending,
                     onConfirm: {},
                     onCancel: {})
        .padding()
}
#endif
