import SwiftUI
import WooFoundation
import struct Yosemite.POSBooking

struct POSBookingNoteView: View {
    let booking: POSBooking

    @State private var noteText: String
    @State private var buttonState: POSButtonState = .idle
    @State private var errorMessage: String?

    @Environment(POSBookingsModel.self) private var bookingsModel
    @Environment(\.posAnalytics) private var analytics

    @Binding private(set) var isShowingNoteView: Bool

    private var originalNote: String
    @State private var isEditingExistingNote: Bool

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
        POSSingleFieldInputView(
            title: isEditingExistingNote ? Localization.editTitle : Localization.addTitle,
            placeholder: Localization.placeholder,
            buttonTitle: hasChanges ? Localization.saveButton : Localization.addButton,
            text: $noteText,
            buttonState: $buttonState,
            errorMessage: $errorMessage,
            isButtonEnabled: hasChanges,
            onSubmit: { saveNote() },
            onClose: {
                isShowingNoteView = false
            },
            autocapitalization: .sentences
        )
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
                }
            } catch {
                analytics.track(event: WooAnalyticsEvent.PointOfSale.bookingNoteAddFailed(error: error))
                errorMessage = Localization.saveError
                buttonState = .idle
            }
        }
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
