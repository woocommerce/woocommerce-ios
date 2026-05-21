import SwiftUI

struct ConfirmationCard: View {

    let proposalID: UUID
    let preview: ConfirmationPreview
    let status: ConfirmationStatus
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.padding) {
            VStack(alignment: .leading, spacing: AssistantSpacing.xSmall) {
                eyebrowLabel

                Text(cardTitle)
                    .font(.assistantBodyEmphasized)
                    .foregroundStyle(Color.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Layout.padding)

            VStack(alignment: .leading, spacing: AssistantSpacing.small) {
                if !preview.bulkEntries.isEmpty {
                    bulkEntriesList
                }
                diffBody
                if status == .pending {
                    actionButtons
                        .padding(.top, AssistantSpacing.xSmall)
                }
            }
            .padding(.horizontal, Layout.padding)
        }
        .padding(.vertical, Layout.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: AssistantRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AssistantRadius.card)
                .stroke(Color.assistantSurfaceBorder, lineWidth: Layout.borderWidth)
        )
        .shadow(color: Color.black.opacity(Layout.shadowOpacity),
                radius: Layout.shadowRadius,
                x: 0,
                y: Layout.shadowYOffset)
    }

    private var backgroundColor: Color {
        Color(.listForeground(modal: false))
    }

    private var eyebrowLabel: some View {
        HStack(spacing: AssistantSpacing.xSmall) {
            Image(systemName: eyebrowSymbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(eyebrowColor)
                .contentTransition(.symbolEffect(.replace))
                .accessibilityHidden(true)
            Text(eyebrowText)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .tracking(0.6)
                .foregroundStyle(eyebrowColor)
                .contentTransition(.opacity)
        }
        .animation(.easeInOut(duration: 0.3), value: status)
    }

    private var bulkEntriesList: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: AssistantSpacing.xSmall) {
                ForEach(Array(preview.bulkEntries.enumerated()), id: \.offset) { _, entry in
                    bulkEntryRow(entry, indent: 0)
                    ForEach(Array(entry.subEntries.enumerated()), id: \.offset) { _, sub in
                        bulkEntryRow(sub, indent: Layout.subEntryIndent)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: Layout.bulkListMaxHeight)
    }

    @ViewBuilder
    private func bulkEntryRow(_ entry: ConfirmationBulkEntry, indent: CGFloat) -> some View {
        // verbatim avoids locale-grouping the entity id (#1 234 vs #1234).
        Text(verbatim: entry.displayName.map { "#\(entry.id)  \($0)" } ?? "#\(entry.id)")
            .font(.assistantBody)
            .foregroundStyle(indent > 0 ? Color.assistantMuted : Color.primary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.leading, indent)
    }

    @ViewBuilder
    private var diffBody: some View {
        if !preview.fields.isEmpty {
            VStack(alignment: .leading, spacing: AssistantSpacing.xSmall) {
                ForEach(Array(preview.fields.enumerated()), id: \.offset) { _, field in
                    DiffFieldRow(field: field,
                                 isBulk: preview.isBulk,
                                 bulkEntries: preview.bulkEntries)
                }
            }
        } else if preview.showsSummaryInBody {
            Text(preview.summary.flattened())
                .font(.assistantBody)
                .foregroundStyle(Color.primary)
                .tint(Color.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var cardTitle: String {
        let rendered = preview.summary.flattened()
        return rendered.isEmpty ? Localization.fallbackTitle : rendered
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

    private var eyebrowColor: Color {
        switch status {
        case .pending: return Color.assistantWarning
        case .confirmed: return Color.assistantSuccess
        case .cancelled: return Color.assistantMuted
        }
    }

    private enum Layout {
        static let padding: CGFloat = 16
        static let borderWidth: CGFloat = 1
        static let shadowOpacity: Double = 0.06
        static let shadowRadius: CGFloat = 4
        static let shadowYOffset: CGFloat = 1
        /// Cap so a large fanout list stays scrollable instead of pushing the action buttons offscreen.
        static let bulkListMaxHeight: CGFloat = 320
        static let subEntryIndent: CGFloat = 16
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

    let field: ConfirmationPreviewField
    let isBulk: Bool
    let bulkEntries: [ConfirmationBulkEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: AssistantSpacing.xSmall) {
            composedLine
                .tint(Color.assistantBubbleAssistantText)
                .fixedSize(horizontal: false, vertical: true)
            if let breakdown = orderedPerEntryRows() {
                ForEach(Array(breakdown.enumerated()), id: \.offset) { _, row in
                    Text(row)
                        .font(.assistantBody)
                        .foregroundStyle(Color.assistantMuted)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.leading, Layout.breakdownIndent)
                }
            }
        }
    }

    private var composedLine: Text {
        let labelPart = Text("\(field.label.flattened()): ")
            .font(.assistantBody)
            .foregroundColor(Color.assistantMuted)

        let valueText = field.value.flattened()
        guard let priorValue = field.priorValue, !isBulk else {
            return labelPart + Text(valueText)
                .font(.assistantBodyEmphasized)
                .foregroundColor(Color.assistantBubbleAssistantText)
        }

        let beforePart = Text(priorValue.flattened())
            .font(.assistantBody)
            .strikethrough(true, color: Color.assistantMuted)
            .foregroundColor(Color.assistantMuted)

        let afterPart = Text(valueText)
            .font(.assistantBodyEmphasized)
            .foregroundColor(Color.assistantBubbleAssistantText)

        return labelPart + beforePart + Text(" ") + afterPart
    }

    /// Preserve the merchant's bulkEntries order so the breakdown matches the entry list shown above.
    /// Falls back to ascending id order for ids missing from bulkEntries.
    private func orderedPerEntryRows() -> [String]? {
        guard let perEntry = field.perEntryValues, !perEntry.isEmpty else { return nil }
        var displayNames: [Int: String] = [:]
        for entry in bulkEntries {
            if let name = entry.displayName { displayNames[entry.id] = name }
        }
        let preferredIDs = bulkEntries.map(\.id).filter { perEntry[$0] != nil }
        let leftoverIDs = perEntry.keys.filter { !preferredIDs.contains($0) }.sorted()
        let orderedIDs = preferredIDs + leftoverIDs
        return orderedIDs.compactMap { id in
            guard let value = perEntry[id] else { return nil }
            let prefix = displayNames[id] ?? "#\(id)"
            return "\(prefix) -> \(value.flattened())"
        }
    }

    private enum Layout {
        static let breakdownIndent: CGFloat = 12
    }
}

#if DEBUG
#Preview("Pending (in chat)") {
    AssistantChatView.preview(.pendingConfirmation)
}

#Preview("Pending standalone") {
    ConfirmationCard(proposalID: UUID(),
                     preview: ConfirmationCardSamples.singleFieldStatus,
                     status: .pending,
                     onConfirm: {},
                     onCancel: {})
        .padding()
}

#Preview("Confirmed") {
    ConfirmationCard(proposalID: UUID(),
                     preview: ConfirmationCardSamples.singleFieldStatus,
                     status: .confirmed,
                     onConfirm: {},
                     onCancel: {})
        .padding()
}

#Preview("Cancelled") {
    ConfirmationCard(proposalID: UUID(),
                     preview: ConfirmationCardSamples.singleFieldStatus,
                     status: .cancelled,
                     onConfirm: {},
                     onCancel: {})
        .padding()
}

#Preview("Multi-field") {
    ConfirmationCard(proposalID: UUID(),
                     preview: ConfirmationCardSamples.multiField,
                     status: .pending,
                     onConfirm: {},
                     onCancel: {})
        .padding()
}

private enum ConfirmationCardSamples {
    static let singleFieldStatus = ConfirmationPreview(
        summary: .raw("Update order #3479"),
        fields: [
            ConfirmationPreviewField(name: "status",
                                     label: .raw("Status"),
                                     value: .raw("completed"),
                                     priorValue: .raw("processing"))
        ]
    )

    static let multiField = ConfirmationPreview(
        summary: .raw("Update order #3479"),
        fields: [
            ConfirmationPreviewField(name: "status",
                                     label: .raw("Status"),
                                     value: .raw("completed"),
                                     priorValue: .raw("processing")),
            ConfirmationPreviewField(name: "total",
                                     label: .raw("Total"),
                                     value: .raw("$60.00"),
                                     priorValue: .raw("$45.00"))
        ]
    )
}
#endif
