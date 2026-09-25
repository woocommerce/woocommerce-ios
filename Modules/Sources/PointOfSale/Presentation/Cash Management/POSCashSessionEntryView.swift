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
    private var money: POSCashSessionMoney { .init(settings: currencyProvider.currencySettings, session: controller.currentSession) }
    private var parsedAmount: Decimal? { money.parse(amount) }
    private var canContinue: Bool {
        guard action != .close || hasEditedAmount else { return false }
        guard let parsedAmount else { return false }
        return action == .close ? parsedAmount >= 0 : parsedAmount > 0
    }

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            POSPageHeaderView(
                title: step == .amount ? amountTitle : noteTitle,
                subtitle: step == .note ? Localization.optional : nil,
                backButtonConfiguration: headerButtonConfiguration
            )

            ScrollView {
                VStack(alignment: .leading, spacing: POSSpacing.xLarge) {
                    if let submitError {
                        POSNoticeView(title: Localization.errorTitle,
                                      icon: Image(systemName: "exclamationmark.triangle"),
                                      style: .alertLowest,
                                      onDismiss: { self.submitError = nil }) {
                            Text(submitError)
                        }
                    }

                    if step == .amount {
                        amountSection
                    } else {
                        noteSection
                    }
                }
                .padding(.top, POSSpacing.xLarge)
                .padding(.horizontal, POSHeaderLayoutConstants.sectionHorizontalPadding)
            }
            .scrollDismissesKeyboard(.interactively)

            submitButton
                .padding(.horizontal, POSHeaderLayoutConstants.sectionHorizontalPadding)
                .padding(.vertical, POSPadding.medium)
        }
        .ignoresSafeArea(.posContainerRegionToIgnore, edges: .bottom)
        .background(Color.posSurfaceBright.ignoresSafeArea())
    }

    private var headerButtonConfiguration: POSPageHeaderBackButtonConfiguration {
        switch step {
        case .amount:
            return .init(state: controller.isSaving ? .disabled : .enabled,
                         action: {
                             isAmountFocused = false
                             dismiss()
                         },
                         buttonIcon: "xmark")
        case .note:
            return .init(state: controller.isSaving ? .disabled : .enabled,
                         action: { step = .amount },
                         buttonIcon: "chevron.backward")
        }
    }

    private var amountSection: some View {
        VStack(alignment: .center, spacing: POSSpacing.xSmall) {
            POSCashAmountTextField(amount: $amount,
                                   isFocused: $isAmountFocused,
                                   currencySettings: money.currencySettings,
                                   preset: 0,
                                   onEdit: { hasEditedAmount = true },
                                   onSubmit: { isAmountFocused = false })

            if action == .close, let expected = controller.currentSession?.expectedCash {
                Text(String.localizedStringWithFormat(Localization.expectedAmount, money.format(expected)))
                    .font(.posBodySmallRegular())
                    .foregroundColor(.posOnSurfaceVariantLowest)

                if hasEditedAmount, let parsedAmount, parsedAmount != expected {
                    Text(String.localizedStringWithFormat(Localization.discrepancy, money.formatSigned(parsedAmount - expected)))
                        .font(.posBodySmallRegular())
                        .foregroundColor(.posOnSurfaceVariantLowest)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut, value: parsedAmount)
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: POSSpacing.small) {
            Text(Localization.noteLabel)
                .font(.posBodyMediumRegular())
                .foregroundColor(.posOnSurfaceVariantLowest)

            TextField(Localization.notePlaceholder, text: $note, axis: .vertical)
                .lineLimit(3...5)
                .font(.posBodyLargeRegular())
                .foregroundColor(.posOnSurface)
                .textInputAutocapitalization(.sentences)
                .padding(.vertical, POSPadding.small)
        }
    }

    private var submitButton: some View {
        Button(step == .amount ? Localization.continueButton : submitTitle) {
            if step == .amount {
                isAmountFocused = false
                step = .note
            } else {
                Task { await submit() }
            }
        }
        .buttonStyle(POSFilledButtonStyle(size: .normal, isLoading: controller.isSaving))
        .disabled(step == .amount ? !canContinue : controller.isSaving || (action == .close && controller.hasPendingCashMovements))
        .frame(maxWidth: .infinity)
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
        static let noteLabel = NSLocalizedString("pos.cashSession.entry.noteLabel", value: "Note", comment: "Label above the cash session note field")
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
