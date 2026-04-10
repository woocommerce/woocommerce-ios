import SwiftUI

struct BookingNotesRowView: View {
    @ObservedObject var content: BookingDetailsViewModel.NotesContent
    let onTap: (() -> Void)?
    let onCommit: (String) async -> MultilineCommitResult

    var body: some View {
        MultilineEditableTextRow(
            value: $content.value,
            placeholder: BookingDetailsView.Localization.bookingNotesRowText,
            detailTitle: BookingDetailsView.Localization.bookingNoteNavbarText,
            onTap: onTap,
            onCommit: onCommit
        )
    }
}
