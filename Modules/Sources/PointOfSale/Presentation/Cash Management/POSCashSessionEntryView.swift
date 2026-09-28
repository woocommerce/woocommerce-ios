import SwiftUI

/// Full-screen flow for recording a cash movement or closing the current session.
struct POSCashSessionEntryView: View {
    enum Action: String, Identifiable {
        case payIn
        case payOut
        case close

        var id: Self { self }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.posCurrencyProvider) private var currencyProvider
    @FocusState private var isAmountFocused: Bool
    @FocusState private var isNoteFocused: Bool
    @State private var amount = ""
    @State private var hasEditedAmount = false
    @State private var note = ""
    @State private var step: Step = .amount
    @State private var submitError: String?
    @State private var movementRequestKey: String?
    @State private var movementRequestID = UUID()

    let action: Action
    let controller: POSCashSessionController
    let onClosed: (Int64) -> Void

    private enum Step { case amount, note }
    private var money: POSCashSessionMoney { .init(settings: currencyProvider.currencySettings, session: controller.currentSession) }
    private var parsedAmount: Decimal? { money.parse(amount) }
    private var canContinue: Bool {
        Self.isValidAmount(parsedAmount, action: action, hasEditedAmount: hasEditedAmount,
                           expectedCash: controller.currentSession?.expectedCash)
    }
    private var payOutExceedsAvailableCash: Bool {
        Self.exceedsAvailableCash(parsedAmount, action: action, expectedCash: controller.currentSession?.expectedCash)
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
                    if action == .close, controller.requiresCloseRecount {
                        POSNoticeView(title: Localization.sessionChangedTitle,
                                      icon: Image(systemName: "exclamationmark.triangle"), style: .alertLowest) {
                            VStack(alignment: .leading, spacing: POSSpacing.small) {
                                Text(controller.closeRefreshError ?? Localization.sessionChangedMessage)
                                if controller.closeRefreshError != nil {
                                    Button(Localization.retryRefresh) {
                                        Task { await controller.refreshSessionAfterCloseConflict() }
                                    }
                                    .buttonStyle(POSOutlinedButtonStyle(size: .normal))
                                }
                            }
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
        .task(id: step) {
            await focusPayInOutField()
        }
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
                         action: {
                             isNoteFocused = false
                             submitError = nil
                             step = .amount
                         },
                         buttonIcon: "chevron.backward")
        }
    }

    private var amountSection: some View {
        VStack(alignment: .center, spacing: POSSpacing.xSmall) {
            POSCashAmountTextField(amount: $amount,
                                   isFocused: $isAmountFocused,
                                   currencySettings: money.currencySettings,
                                   preset: 0,
                                   fillsWidth: action != .close,
                                   onEdit: {
                                       hasEditedAmount = true
                                       submitError = nil
                                   },
                                   onSubmit: { isAmountFocused = false })

            if payOutExceedsAvailableCash, let expectedCash = controller.currentSession?.expectedCash {
                Text(String.localizedStringWithFormat(Localization.payOutExceedsAvailableCash, money.format(max(expectedCash, 0))))
                    .font(.posBodySmallRegular())
                    .foregroundColor(.posError)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if action == .close, let expected = controller.currentSession?.expectedCash {
                Text(String.localizedStringWithFormat(Localization.expectedAmount, money.format(expected)))
                    .font(.posBodySmallRegular())
                    .foregroundColor(.posOnSurfaceVariantLowest)

                if hasEditedAmount, let parsedAmount, parsedAmount != expected {
                    Text(String.localizedStringWithFormat(Localization.discrepancy, money.formatSigned(parsedAmount - expected)))
                        .font(.posBodySmallRegular())
                        .foregroundColor(.posAlert)
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
                .focused($isNoteFocused)
                .font(.posBodyLargeRegular())
                .foregroundColor(.posOnSurface)
                .textInputAutocapitalization(.sentences)
                .padding(.vertical, POSPadding.small)
                .onChange(of: note) { _, _ in submitError = nil }
        }
    }

    private var submitButton: some View {
        VStack(alignment: .leading, spacing: POSSpacing.small) {
            if let submitError {
                Text(submitError)
                    .font(.posBodySmallRegular())
                    .foregroundColor(.posError)
                    .accessibilityIdentifier("pos-cash-session-submit-error")
            }

            Button(step == .amount ? Localization.continueButton : submitTitle) {
                if step == .amount {
                    if action == .close, !controller.acknowledgeFreshCloseCount() {
                        submitError = controller.closeRefreshError ?? Localization.refreshRequired
                        return
                    }
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var amountTitle: String {
        switch action {
        case .payIn: horizontalSizeClass == .compact ? Localization.compactPayInAmount : Localization.payInAmount
        case .payOut: horizontalSizeClass == .compact ? Localization.compactPayOutAmount : Localization.payOutAmount
        case .close: horizontalSizeClass == .compact ? Localization.compactCloseAmount : Localization.closeAmount
        }
    }

    private var noteTitle: String {
        if action == .close { return Localization.closeNote }
        return horizontalSizeClass == .compact ? Localization.compactMovementNote : Localization.movementNote
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
        if action == .payOut,
           !Self.isValidAmount(parsedAmount, action: action, hasEditedAmount: hasEditedAmount,
                               expectedCash: controller.currentSession?.expectedCash) {
            isNoteFocused = false
            step = .amount
            return
        }
        submitError = nil
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let optionalNote = trimmedNote.isEmpty ? nil : trimmedNote
        switch action {
        case .payIn:
            if await controller.record(kind: .payIn, amount: parsedAmount, note: optionalNote,
                                       requestID: requestID(for: parsedAmount, note: optionalNote)) {
                dismiss()
            } else {
                showSaveError()
            }
        case .payOut:
            if await controller.record(kind: .payOut, amount: parsedAmount, note: optionalNote,
                                       requestID: requestID(for: parsedAmount, note: optionalNote)) {
                dismiss()
            } else {
                showSaveError()
            }
        case .close:
            if let closedSession = await controller.close(countedCash: parsedAmount, note: optionalNote) {
                onClosed(closedSession.id)
                dismiss()
            } else {
                if controller.requiresCloseRecount {
                    amount = ""
                    hasEditedAmount = false
                    step = .amount
                }
                showSaveError()
            }
        }
    }

    private func showSaveError() {
        submitError = controller.errorMessage ?? Localization.updateFailed
        controller.errorMessage = nil
    }

    private func requestID(for amount: Decimal, note: String?) -> UUID {
        let key = "\(NSDecimalNumber(decimal: amount).stringValue):\(note ?? "")"
        if movementRequestKey != key {
            movementRequestKey = key
            movementRequestID = UUID()
        }
        return movementRequestID
    }

    @MainActor
    private func focusPayInOutField() async {
        guard action != .close else { return }
        // Let the full-screen presentation or the next step finish before opening the keyboard.
        do {
            try await Task.sleep(nanoseconds: 600_000_000)
        } catch {
            return
        }
        switch step {
        case .amount:
            isAmountFocused = true
        case .note:
            isNoteFocused = true
        }
    }

    static func isValidAmount(_ amount: Decimal?, action: Action, hasEditedAmount: Bool, expectedCash: Decimal?) -> Bool {
        guard let amount else { return false }
        switch action {
        case .payIn:
            return amount > 0
        case .payOut:
            guard let expectedCash else { return false }
            return amount > 0 && amount <= expectedCash
        case .close:
            return hasEditedAmount && amount >= 0
        }
    }

    static func exceedsAvailableCash(_ amount: Decimal?, action: Action, expectedCash: Decimal?) -> Bool {
        guard action == .payOut, let amount, let expectedCash else { return false }
        return amount > expectedCash
    }
}

#if DEBUG
extension POSCashSessionEntryView {
    /// Starts on the optional note step so the full flow can be inspected in previews.
    init(action: Action, controller: POSCashSessionController, onClosed: @escaping (Int64) -> Void,
         previewNoteStep: Bool, previewAmount: String = "23.50", previewSubmitError: String? = nil) {
        self.action = action
        self.controller = controller
        self.onClosed = onClosed
        _amount = State(initialValue: previewAmount)
        _hasEditedAmount = State(initialValue: true)
        _step = State(initialValue: previewNoteStep ? .note : .amount)
        _submitError = State(initialValue: previewSubmitError)
    }
}
#endif

private extension POSCashSessionEntryView {
    enum Localization {
        static let noteLabel = NSLocalizedString("pos.cashSession.entry.noteLabel", value: "Note", comment: "Label above the cash session note field")
        static let optional = NSLocalizedString("pos.cashSession.entry.optional", value: "Optional", comment: "Cash movement note is optional")
        static let payInAmount = NSLocalizedString("pos.cashSession.entry.payInAmount", value: "How much is the Pay in?", comment: "Pay in amount prompt")
        static let payOutAmount = NSLocalizedString("pos.cashSession.entry.payOutAmount", value: "How much is the Pay out?", comment: "Pay out amount prompt")
        static let compactPayInAmount = NSLocalizedString("pos.cashSession.entry.compactPayInAmount", value: "Pay in amount",
                                                         comment: "Pay in amount prompt on iPhone")
        static let compactPayOutAmount = NSLocalizedString("pos.cashSession.entry.compactPayOutAmount", value: "Pay out amount",
                                                          comment: "Pay out amount prompt on iPhone")
        static let closeAmount = NSLocalizedString("pos.cashSession.entry.closeAmount", value: "Current amount in drawer", comment: "Counted cash prompt")
        static let compactCloseAmount = NSLocalizedString("pos.cashSession.entry.compactCloseAmount", value: "Cash in drawer",
                                                         comment: "Counted cash prompt on iPhone")
        static let expectedAmount = NSLocalizedString("pos.cashSession.entry.expectedAmount", value: "Expected amount is %1$@",
                                                      comment: "Expected cash while counting")
        static let discrepancy = NSLocalizedString("pos.cashSession.entry.discrepancyAmount", value: "Discrepancy: %1$@",
                                                   comment: "Counted cash difference from expected")
        static let movementNote = NSLocalizedString("pos.cashSession.entry.movementNote", value: "Enter a description", comment: "Pay in or pay out description")
        static let compactMovementNote = NSLocalizedString("pos.cashSession.entry.compactMovementNote", value: "Description",
                                                          comment: "Pay in or pay out description on iPhone")
        static let closeNote = NSLocalizedString("pos.cashSession.entry.closeNote", value: "Enter a note", comment: "Session closing note")
        static let notePlaceholder = NSLocalizedString("pos.cashSession.entry.notePlaceholder", value: "Add a note", comment: "Cash session note placeholder")
        static let continueButton = NSLocalizedString("pos.cashSession.entry.continue", value: "Continue", comment: "Continue cash session flow")
        static let recordPayIn = NSLocalizedString("pos.cashSession.entry.recordPayIn", value: "Record Pay in", comment: "Record pay in button")
        static let recordPayOut = NSLocalizedString("pos.cashSession.entry.recordPayOut", value: "Record Pay out", comment: "Record pay out button")
        static let closeButton = NSLocalizedString("pos.cashSession.entry.closeButton", value: "Close session", comment: "Close cash session button")
        static let updateFailed = NSLocalizedString("pos.cashSession.entry.updateFailed", value: "Could not update the cash session. Try again.",
                                                    comment: "Fallback message when a cash session update fails")
        static let payOutExceedsAvailableCash = NSLocalizedString("pos.cashSession.entry.payOutExceedsAvailableCash",
                                                                   value: "Pay out cannot exceed the cash in the drawer (%1$@).",
                                                                   comment: "Validation message when a pay out exceeds expected cash in the drawer")
        static let sessionChangedTitle = NSLocalizedString("pos.cashSession.entry.sessionChangedTitle", value: "Cash session changed",
                                                           comment: "Title when a cashier must review a changed cash session")
        static let sessionChangedMessage = NSLocalizedString("pos.cashSession.entry.sessionChangedMessage",
                                                             value: "Review the latest expected amount and count the cash again.",
                                                             comment: "Instruction after a cash session close revision conflict")
        static let refreshRequired = NSLocalizedString("pos.cashSession.entry.refreshRequired",
                                                       value: "Refresh the session before counting the cash again.",
                                                       comment: "Shown when a stale cash session could not be refreshed")
        static let retryRefresh = NSLocalizedString("pos.cashSession.entry.retryRefresh", value: "Refresh session",
                                                    comment: "Retry loading the latest cash session after a close conflict")
    }
}
