import SwiftUI

enum MultilineCommitResult {
    case success
    case failure(message: String)
}

struct MultilineEditableTextDetailView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var text: String
    @State private var editedText: String
    @State private var showDiscardChangesDialog = false
    @FocusState private var isFocused: Bool
    @State private var notice: Notice?
    @State private var isSaving = false

    let title: String?
    let onCommit: (String) async -> MultilineCommitResult

    init(text: Binding<String>, title: String? = nil, onCommit: @escaping (String) async -> MultilineCommitResult) {
        self._text = text
        self._editedText = State(initialValue: text.wrappedValue)
        self.title = title
        self.onCommit = onCommit
    }

    var body: some View {
        VStack {
            TextEditor(text: $editedText)
                .focused($isFocused)
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.vertical, Layout.verticalPadding)
        }
        .navigationTitle(title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar { toolbar }
        .wooNavigationBarStyle()
        .onAppear { isFocused = true }
        .notice($notice)
    }

    private var toolbar: some ToolbarContent {
        Group {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: handleBackButtonTap) {
                    Image(systemName: "chevron.backward")
                        .font(.body.weight(.semibold))
                }
                .confirmationDialog(
                    Localization.discardChangesAlertTitle,
                    isPresented: $showDiscardChangesDialog,
                    titleVisibility: .visible
                ) {
                    Button(Localization.discardChangesActionTitle, role: .destructive) {
                        dismiss()
                    }
                    Button(Localization.cancelActionTitle, role: .cancel) {}
                }
            }

            if editedText != text {
                ToolbarItem(placement: .primaryAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button(Localization.doneButtonTitle) {
                            Task {
                                await handleDoneTapped()
                            }
                        }
                        .fontWeight(.medium)
                        .disabled(isSaving)
                    }
                }
            }
        }
    }

    private func handleDoneTapped() async {
        guard !isSaving else { return }

        isSaving = true
        let newText = editedText
        switch await onCommit(newText) {
        case .success:
            text = newText
            isSaving = false
            dismiss()
        case .failure(let message):
            isSaving = false

            notice = Notice(
                message: message,
                feedbackType: .error,
            )
        }
    }

    private func handleBackButtonTap() {
        if editedText != text {
            showDiscardChangesDialog = true
        } else {
            dismiss()
        }
    }
}

fileprivate extension MultilineEditableTextDetailView {
    enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 12
    }
}

extension MultilineEditableTextDetailView {
    enum Localization {
        static let discardChangesAlertTitle = NSLocalizedString(
            "MultilineEditableTextDetailView.discardChanges.alert.title",
            value: "Are you sure you want to discard these changes?",
            comment: "Title for the confirmation dialog when the user attempts to discard changes in the multiline text editor."
        )
        static let discardChangesActionTitle = NSLocalizedString(
            "MultilineEditableTextDetailView.discardChanges.alert.discardAction",
            value: "Discard changes",
            comment: "Destructive action button title to discard changes in the multiline text editor."
        )
        static let cancelActionTitle = NSLocalizedString(
            "MultilineEditableTextDetailView.discardChanges.alert.cancelAction",
            value: "Cancel",
            comment: "Cancel button title for the discard changes confirmation dialog in the multiline text editor."
        )
        static let doneButtonTitle = NSLocalizedString(
            "MultilineEditableTextDetailView.doneButton.title",
            value: "Done",
            comment: "Navigation bar button title used to save changes and close the multiline text editor."
        )
    }
}
