import SwiftUI
import Combine
import WooFoundation
import struct Yosemite.POSBooking

struct POSBookingNoteView: View {
    let booking: POSBooking

    @State private var noteText: String
    @State private var buttonState: POSButtonState = .idle
    @State private var errorMessage: String?
    @FocusState private var isTextFieldFocused: Bool

    @Environment(POSBookingsModel.self) private var bookingsModel
    @Environment(\.posAnalytics) private var analytics

    @Binding private(set) var isShowingNoteView: Bool

    @State private var buttonFrame: CGRect = .zero
    @State private var keyboardFrame: CGRect = .zero
    @State private var shouldMinimizePadding: Bool = false

    private var originalNote: String
    private var isEditingExistingNote: Bool

    init(booking: POSBooking, isShowingNoteView: Binding<Bool>) {
        self.booking = booking
        self._isShowingNoteView = isShowingNoteView
        let existingNote = booking.bookingNote ?? ""
        self._noteText = State(initialValue: existingNote)
        self.originalNote = existingNote
        self.isEditingExistingNote = booking.bookingNote != nil
    }

    private var hasChanges: Bool {
        noteText.trimmingCharacters(in: .whitespacesAndNewlines) != originalNote
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: conditionalPadding(POSSpacing.medium)) {
                POSPageHeaderView(
                    title: isEditingExistingNote ? Localization.editTitle : Localization.addTitle,
                    backButtonConfiguration: .init(
                        state: buttonState != .idle ? .disabled : .enabled,
                        action: {
                            withAnimation {
                                isShowingNoteView = false
                                isTextFieldFocused = false
                            }
                        }
                    )
                )

                VStack(alignment: .center, spacing: conditionalPadding(POSSpacing.medium)) {
                    Spacer()

                    VStack(alignment: .center, spacing: POSSpacing.xSmall) {
                        TextField("",
                                  text: $noteText,
                                  prompt: Text(Localization.placeholder).foregroundColor(.posOnDisabledContainer))
                        .foregroundStyle(Color.posOnSurface)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                        .textInputAutocapitalization(.sentences)
                        .multilineTextAlignment(.center)
                        .font(POSFontStyle.posHeadingRegular)
                        .focused()
                        .focused($isTextFieldFocused)

                        if let errorMessage {
                            Text(errorMessage)
                                .font(POSFontStyle.posBodySmallRegular())
                                .foregroundColor(.posError)
                        }
                    }

                    Spacer()

                    Button(action: {
                        saveNote()
                    }, label: {
                        Text(hasChanges ? Localization.saveButton : Localization.addButton)
                    })
                    .measureFrame {
                        buttonFrame = $0
                    }
                    .buttonStyle(POSFilledButtonStyle(size: .normal, state: buttonState))
                    .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                    .frame(maxWidth: .infinity)
                    .disabled(buttonState != .idle || !hasChanges)
                }
                .padding([.horizontal])
                .padding(.bottom, keyboardFrame.height)
            }
            .animation(.easeInOut, value: errorMessage)
            .onChange(of: noteText) {
                errorMessage = nil
            }
            .onReceive(Publishers.keyboardFrame) {
                keyboardFrame = $0
                shouldMinimizePadding = $0.intersects(buttonFrame)
            }
            .animation(.default, value: shouldMinimizePadding)
        }
        .background(Color.posSurfaceBright)
    }

    private func saveNote() {
        Task { @MainActor in
            buttonState = .loading
            do {
                errorMessage = nil
                let trimmedNote = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
                try await bookingsModel.bookingsController.updateBookingNote(
                    bookingID: booking.id,
                    note: trimmedNote
                )
                analytics.track(event: WooAnalyticsEvent.PointOfSale.bookingNoteAdded())

                withAnimation {
                    buttonState = .success
                } completion: {
                    isShowingNoteView = false
                    isTextFieldFocused = false
                }
            } catch {
                analytics.track(event: WooAnalyticsEvent.PointOfSale.bookingNoteAddFailed(error: error))
                errorMessage = Localization.saveError
                buttonState = .idle
            }
        }
    }
}

// MARK: - Helpers

private extension POSBookingNoteView {
    enum Constants {
        static let minimumPadding: CGFloat = POSSpacing.xSmall
    }

    func conditionalPadding(_ padding: CGFloat) -> CGFloat {
        if shouldMinimizePadding {
            return Constants.minimumPadding
        }
        return padding
    }
}

// MARK: - Localization

private extension POSBookingNoteView {
    enum Localization {
        static let addTitle = NSLocalizedString(
            "pos.bookingNoteView.addTitle",
            value: "Add note",
            comment: "Title shown at the top of the booking note editor screen when adding a new note."
        )

        static let editTitle = NSLocalizedString(
            "pos.bookingNoteView.editTitle",
            value: "Edit note",
            comment: "Title shown at the top of the booking note editor screen when editing an existing note."
        )

        static let placeholder = NSLocalizedString(
            "pos.bookingNoteView.placeholder",
            value: "Type note",
            comment: "Placeholder text shown in the booking note text field when empty."
        )

        static let addButton = NSLocalizedString(
            "pos.bookingNoteView.addButton",
            value: "Add",
            comment: "Button label shown when no changes have been made to the booking note yet."
        )

        static let saveButton = NSLocalizedString(
            "pos.bookingNoteView.saveButton",
            value: "Save",
            comment: "Button to save the booking note."
        )

        static let saveError = NSLocalizedString(
            "pos.bookingNoteView.saveError",
            value: "Failed to save note. Try again.",
            comment: "Error message shown when saving a booking note fails."
        )
    }
}

// MARK: - Previews

#if DEBUG
#Preview("New Note") {
    POSBookingNoteView(
        booking: POSPreviewHelpers.makePreviewUnpaidBooking(),
        isShowingNoteView: .constant(true)
    )
}

#Preview("Edit Existing Note") {
    POSBookingNoteView(
        booking: POSPreviewHelpers.makePreviewPaidBooking(),
        isShowingNoteView: .constant(true)
    )
}
#endif
