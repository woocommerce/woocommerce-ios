import SwiftUI

struct CustomerNoteSection: View {

    /// Parent view model to access all data
    @ObservedObject var viewModel: NewOrderViewModel

    /// View model to drive the view content
    private var notesDataViewModel: NewOrderViewModel.CustomerNoteDataViewModel {
        viewModel.customerNoteDataViewModel
    }

    @State private var showEditNotesView: Bool = false

    var body: some View {
        CustomerNoteSectionContent(viewModel: notesDataViewModel, showEditNotesView: $showEditNotesView)
            .sheet(
                isPresented: $showEditNotesView,
                onDismiss: {
                    viewModel.noteViewModel.userDidCancelFlow()
                    viewModel.updateCustomerNote()
                },
                content: {
                    EditCustomerNote(
                        dismiss: {
                            showEditNotesView.toggle()
                            viewModel.updateCustomerNote()
                        },
                        viewModel: viewModel.noteViewModel
                    )
                }
            )
    }
}

private struct CustomerNoteSectionContent: View {
    /// View model to drive the view content
    var viewModel: NewOrderViewModel.CustomerNoteDataViewModel

    @Binding var showEditNotesView: Bool

    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack(alignment: .top) {
                Text(Localization.notes)
                    .accessibilityAddTraits(.isHeader)
                    .headlineStyle()
                Spacer()
                if viewModel.customerNote.isNotEmpty {
                    createEditNotesButton()
                }
            }.padding([.leading, .top, .trailing])

            if viewModel.customerNote.isEmpty {
                createOrderNotesView()
            } else {
                createNoteDataView()
            }
        }
        .padding(.horizontal, insets: safeAreaInsets)
        .background(Color(.listForeground))
        .addingTopAndBottomDividers()
    }

    private func createEditNotesButton() -> some View {
        Button(Localization.editButton) {
            showEditNotesView.toggle()
        }
        .buttonStyle(LinkButtonStyle())
        .fixedSize(horizontal: true, vertical: true)
        .padding(.top, -Layout.linkButtonTopPadding) // remove padding to align button title to the top
        .padding(.trailing, -Layout.linkButtonTrailingPadding) // remove padding to align button title to the side
        .accessibilityLabel(Text(Localization.editButtonAccessibilityLabel))
    }

    private func createOrderNotesView() -> some View {
        Group {
            Spacer(minLength: Layout.verticalHeadlineSpacing)
            Button(Localization.addNotes) {
                showEditNotesView.toggle()
            }
            .buttonStyle(PlusButtonStyle())
            .padding([.leading, .bottom, .trailing])
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
        static let linkButtonTopPadding: CGFloat = 12.0
        static let linkButtonTrailingPadding: CGFloat = 22.0
    }

    enum Localization {
        static let notes = NSLocalizedString("Customer Note", comment: "Title text of the section that shows the Order customer note when creating a new order")
        static let addNotes = NSLocalizedString("Add Note",
                                                          comment: "Title text of the button that adds customer note data when creating a new order")
        static let editButton = NSLocalizedString("Edit", comment: "Button to edit the customer note on the New Order screen")
        static let editButtonAccessibilityLabel = NSLocalizedString(
            "Edit customer note",
            comment: "Accessibility label for the button to edit customer note on the New Order screen"
        )
    }
}

struct CustomerNoteSection_Previews: PreviewProvider {
    static var previews: some View {
        let emptyViewModel = NewOrderViewModel.CustomerNoteDataViewModel(customerNote: "")
        let notesViewModel = NewOrderViewModel.CustomerNoteDataViewModel(customerNote: "some notes")

        ScrollView {
            CustomerNoteSectionContent(viewModel: emptyViewModel, showEditNotesView: .constant(false))
            CustomerNoteSectionContent(viewModel: notesViewModel, showEditNotesView: .constant(false))
        }
    }
}
