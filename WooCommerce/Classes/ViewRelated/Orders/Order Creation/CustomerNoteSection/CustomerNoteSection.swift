import SwiftUI

struct CustomerNoteSection: View {

    /// Parent view model to access all data
    @ObservedObject var viewModel: EditableOrderViewModel

    /// View model to drive the view content
    private var notesDataViewModel: EditableOrderViewModel.CustomerNoteDataViewModel {
        viewModel.customerNoteDataViewModel
    }

    @State private var showEditNotesView: Bool = false

    var body: some View {
        CustomerNoteSectionContent(viewModel: notesDataViewModel, showEditNotesView: $showEditNotesView)
            .sheet(
                isPresented: $showEditNotesView,
                onDismiss: {
                    // reset note content when modal is dismissed with swipe down gesture
                    viewModel.noteViewModel.userDidCancelFlow()
                },
                content: {
                    EditCustomerNote(
                        onSave: {
                            viewModel.updateCustomerNote()
                        },
                        dismiss: {
                            showEditNotesView.toggle()
                        },
                        viewModel: viewModel.noteViewModel
                    )
                }
            )
    }
}

private struct CustomerNoteSectionContent: View {
    /// View model to drive the view content
    var viewModel: EditableOrderViewModel.CustomerNoteDataViewModel

    @Binding var showEditNotesView: Bool

    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack(alignment: .top) {
                Text(Localization.notes)
                    .accessibilityAddTraits(.isHeader)
                    .headlineStyle()
                Spacer()
                createEditNotesButton()
            }.padding([.leading, .top, .trailing])
            .renderedIf(viewModel.customerNote.isNotEmpty)

            if viewModel.customerNote.isEmpty {
                createOrderNotesView()
            } else {
                createNoteDataView()
            }
        }
        .padding(.horizontal, insets: safeAreaInsets)
        .background(Color(.listForeground(modal: true)))
    }

    private func createEditNotesButton() -> some View {
        PencilEditButton() {
            showEditNotesView.toggle()
        }
        .accessibilityLabel(Text(Localization.editButtonAccessibilityLabel))
    }

    private func createOrderNotesView() -> some View {
        Group {
            Button(Localization.addNotes) {
                showEditNotesView.toggle()
            }
            .buttonStyle(PlusButtonStyle())
            .frame(minHeight: Layout.buttonHeight)
            .padding([.leading, .trailing])
            .accessibilityIdentifier("add-customer-note-button")
        }
    }

    private func createNoteDataView() -> some View {
        Text(viewModel.customerNote)
            .padding([.leading, .bottom, .trailing])
    }
}

// MARK: Constants
private extension CustomerNoteSectionContent {
    enum Layout {
        static let verticalHeadlineSpacing: CGFloat = 22.0
        static let verticalEmailSpacing: CGFloat = 4.0
        static let verticalAddressSpacing: CGFloat = 6.0
        static let buttonHeight: CGFloat = 56.0
    }

    enum Localization {
        static let notes = NSLocalizedString("Customer Note", comment: "Title text of the section that shows the Order customer note when creating a new order")
        static let addNotes = NSLocalizedString("Add Note",
                                                          comment: "Title text of the button that adds customer note data when creating a new order")
        static let editButtonAccessibilityLabel = NSLocalizedString(
            "Edit customer note",
            comment: "Accessibility label for the button to edit customer note on the New Order screen"
        )
    }
}

struct CustomerNoteSection_Previews: PreviewProvider {
    static var previews: some View {
        let emptyViewModel = EditableOrderViewModel.CustomerNoteDataViewModel(customerNote: "")
        let notesViewModel = EditableOrderViewModel.CustomerNoteDataViewModel(customerNote: "some notes")

        ScrollView {
            CustomerNoteSectionContent(viewModel: emptyViewModel, showEditNotesView: .constant(false))
            CustomerNoteSectionContent(viewModel: notesViewModel, showEditNotesView: .constant(false))
        }
    }
}
