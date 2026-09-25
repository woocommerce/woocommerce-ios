import SwiftUI

/// Demo flow for recording a cash movement or closing the current session.
struct POSCashSessionEntryView: View {
    enum Action: String, Identifiable {
        case payIn
        case payOut
        case close

        var id: Self { self }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.posCurrencyProvider) private var currencyProvider
    @FocusState private var isAmountFocused: Bool
    @State private var amount = ""
    @State private var hasEditedAmount = false
    @State private var note = ""
    @State private var step: Step = .amount
    @State private var submitError: String?

    let action: Action
    let controller: POSCashSessionController
    let onClosed: (Int64) -> Void

    private enum Step { case amount, note }
    private var money: POSCashSessionMoney { .init(settings: currencyProvider.currencySettings) }
    private var parsedAmount: Decimal? { money.parse(amount) }
    private var canContinue: Bool {
        guard action != .close || hasEditedAmount else { return false }
        guard let parsedAmount else { return false }
        return action == .close ? parsedAmount >= 0 : parsedAmount > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: POSSpacing.large) {
            HStack(spacing: POSSpacing.medium) {
                if step == .note {
                    Button { step = .amount } label: {
                        Image(systemName: "arrow.left")
                    }
                    .accessibilityLabel(Localization.back)
                }
                VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                    Text(step == .amount ? amountTitle : noteTitle)
                        .font(.posHeadingBold)
                        .foregroundStyle(Color.posOnSurface)
                    if step == .note {
                        Text(Localization.optional)
                            .font(.posBodyMediumRegular())
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button { dismiss() } label: { Image(systemName: "xmark") }
                    .accessibilityLabel(Localization.cancel)
            }

            if let submitError {
                POSNoticeView(title: Localization.errorTitle,
                              icon: Image(systemName: "exclamationmark.triangle"),
                              style: .alertLowest,
                              onDismiss: { self.submitError = nil }) {
                    Text(submitError)
                }
            }

            Spacer(minLength: POSSpacing.medium)

            if step == .amount {
                HStack {
                    Spacer()
                    POSCashAmountTextField(amount: $amount,
                                           isFocused: $isAmountFocused,
                                           currencySettings: currencyProvider.currencySettings,
                                           preset: 0,
                                           onEdit: { hasEditedAmount = true },
                                           onSubmit: { isAmountFocused = false })
                    Spacer()
                }
                if action == .close, let expected = controller.currentSession?.expectedCash {
                    Text(String.localizedStringWithFormat(Localization.expectedAmount, money.format(expected)))
                        .font(.posBodyMediumRegular())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                    if hasEditedAmount, let parsedAmount, parsedAmount != expected {
                        Text(String.localizedStringWithFormat(Localization.discrepancy, money.formatSigned(parsedAmount - expected)))
                            .font(.posBodyMediumBold)
                            .foregroundStyle(Color.posError)
                            .frame(maxWidth: .infinity)
                    }
                }
            } else {
                TextField(Localization.notePlaceholder, text: $note, axis: .vertical)
                    .lineLimit(3...5)
                    .font(.posHeadingRegular)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.posOnSurface)
            }

            Spacer(minLength: POSSpacing.medium)

            Button(step == .amount ? Localization.continueButton : submitTitle) {
                if step == .amount {
                    isAmountFocused = false
                    step = .note
                } else {
                    Task { await submit() }
                }
            }
            .buttonStyle(POSFilledButtonStyle(size: .normal, isLoading: controller.isSaving))
            .disabled(step == .amount ? !canContinue : controller.isSaving)
            .frame(maxWidth: .infinity)
        }
        .padding(POSPadding.large)
        .background(Color.posSurface)
    }

    private var amountTitle: String {
        switch action {
        case .payIn: Localization.payInAmount
        case .payOut: Localization.payOutAmount
        case .close: Localization.closeAmount
        }
    }

    private var noteTitle: String {
        action == .close ? Localization.closeNote : Localization.movementNote
    }

    private var submitTitle: String {
        switch action {
        case .payIn: Localization.recordPayIn
        case .payOut: Localization.recordPayOut
        case .close: Localization.closeButton
        }
    }

    private func submit() async {
        guard let parsedAmount else { return }
        submitError = nil
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let optionalNote = trimmedNote.isEmpty ? nil : trimmedNote
        switch action {
        case .payIn:
            if await controller.record(kind: .payIn, amount: parsedAmount, note: optionalNote) {
                dismiss()
            } else {
                showSaveError()
            }
        case .payOut:
            if await controller.record(kind: .payOut, amount: parsedAmount, note: optionalNote) {
                dismiss()
            } else {
                showSaveError()
            }
        case .close:
            if let closedSession = await controller.close(countedCash: parsedAmount, note: optionalNote) {
                onClosed(closedSession.id)
                dismiss()
            } else {
                showSaveError()
            }
        }
    }

    private func showSaveError() {
        submitError = controller.errorMessage ?? Localization.errorTitle
        controller.errorMessage = nil
    }
}

#if DEBUG
extension POSCashSessionEntryView {
    /// Starts on the optional note step so the full flow can be inspected in previews.
    init(action: Action, controller: POSCashSessionController, onClosed: @escaping (Int64) -> Void,
         previewNoteStep: Bool) {
        self.action = action
        self.controller = controller
        self.onClosed = onClosed
        _amount = State(initialValue: "23.50")
        _hasEditedAmount = State(initialValue: true)
        _step = State(initialValue: previewNoteStep ? .note : .amount)
    }
}
#endif

private extension POSCashSessionEntryView {
    enum Localization {
        static let back = NSLocalizedString("pos.cashSession.entry.back", value: "Back", comment: "Back to cash amount entry")
        static let cancel = NSLocalizedString("pos.cashSession.entry.cancel", value: "Cancel", comment: "Cancel cash session entry")
        static let optional = NSLocalizedString("pos.cashSession.entry.optional", value: "Optional", comment: "Cash movement note is optional")
        static let payInAmount = NSLocalizedString("pos.cashSession.entry.payInAmount", value: "How much is the Pay in?", comment: "Pay in amount prompt")
        static let payOutAmount = NSLocalizedString("pos.cashSession.entry.payOutAmount", value: "How much is the Pay out?", comment: "Pay out amount prompt")
        static let closeAmount = NSLocalizedString("pos.cashSession.entry.closeAmount", value: "Current amount in drawer", comment: "Counted cash prompt")
        static let expectedAmount = NSLocalizedString("pos.cashSession.entry.expectedAmount", value: "Expected amount is %1$@",
                                                      comment: "Expected cash while counting")
        static let discrepancy = NSLocalizedString("pos.cashSession.entry.discrepancyAmount", value: "Discrepancy: %1$@",
                                                   comment: "Counted cash difference from expected")
        static let movementNote = NSLocalizedString("pos.cashSession.entry.movementNote", value: "Enter a description", comment: "Pay in or pay out description")
        static let closeNote = NSLocalizedString("pos.cashSession.entry.closeNote", value: "Enter a note", comment: "Session closing note")
        static let notePlaceholder = NSLocalizedString("pos.cashSession.entry.notePlaceholder", value: "Add a note", comment: "Cash session note placeholder")
        static let continueButton = NSLocalizedString("pos.cashSession.entry.continue", value: "Continue", comment: "Continue cash session flow")
        static let recordPayIn = NSLocalizedString("pos.cashSession.entry.recordPayIn", value: "Record Pay in", comment: "Record pay in button")
        static let recordPayOut = NSLocalizedString("pos.cashSession.entry.recordPayOut", value: "Record Pay out", comment: "Record pay out button")
        static let closeButton = NSLocalizedString("pos.cashSession.entry.closeButton", value: "Close session", comment: "Close cash session button")
        static let errorTitle = NSLocalizedString("pos.cashSession.entry.errorTitle", value: "Could not update session",
                                                  comment: "Cash session update error title")
    }
}
