import SwiftUI

struct ConfirmationCard: View {

    let proposalID: UUID
    let preview: ConfirmationPreview
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
        if !preview.fields.isEmpty {
            VStack(alignment: .leading, spacing: AssistantSpacing.xSmall) {
                ForEach(Array(preview.fields.enumerated()), id: \.offset) { _, field in
                    DiffFieldRow(field: field, isBulk: preview.isBulk)
                }
            }
        } else {
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

    let field: ConfirmationPreviewField
    let isBulk: Bool

    var body: some View {
        composedLine
            .tint(Color.assistantBubbleAssistantText)
            .fixedSize(horizontal: false, vertical: true)
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
