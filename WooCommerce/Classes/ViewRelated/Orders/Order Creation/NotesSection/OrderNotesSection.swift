import SwiftUI

struct OrderNotesSection: View {
    /// Parent view model to access all data
    @ObservedObject var viewModel: NewOrderViewModel

    @State private var showEditNotesView: Bool = false

    @State private var notes: String = ""

    var body: some View {
        OrderNotesSectionContent(notes: $notes, showEditNotesView: $showEditNotesView)
            .sheet(
                isPresented: $showEditNotesView,
                onDismiss: {
                    viewModel.noteViewModel.userDidCancelFlow()
                    notes = viewModel.onOrderNoteUpdate()
                },
                content: {
                    EditCustomerNote(
                        dismiss: {
                            showEditNotesView.toggle()
                            notes = viewModel.onOrderNoteUpdate()
                        },
                        viewModel: viewModel.noteViewModel
                    )
                }
            )
    }
}

private struct OrderNotesSectionContent: View {
    /// View model to drive the view content
    @Binding var notes: String

    @Binding var showEditNotesView: Bool

    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack(alignment: .top) {
                Text(Localization.notes)
                    .headlineStyle()
                Spacer()
                if notes.isNotEmpty {
                    createEditNotesButton
                }
            }.padding([.leading, .top, .trailing])

            if notes.isEmpty {
                createOrderNotesView
            } else {
                createNoteDataView
            }
        }
        .padding(.horizontal, insets: safeAreaInsets)
        .background(Color(.listForeground))
        .addingTopAndBottomDividers()
    }

    private var createEditNotesButton: some View {
        Button(Localization.editButton) {
            showEditNotesView.toggle()
        }
        .buttonStyle(LinkButtonStyle())
        .fixedSize(horizontal: true, vertical: true)
        .padding(.top, -Layout.linkButtonTopPadding) // remove padding to align button title to the top
        .padding(.trailing, -Layout.linkButtonTrailingPadding) // remove padding to align button title to the side
        .accessibilityLabel(Text(Localization.editButtonAccessibilityLabel))
    }

    private var createOrderNotesView: some View {
        Group {
            Spacer(minLength: Layout.verticalHeadlineSpacing)
            Button(Localization.addNotes) {
                showEditNotesView.toggle()
            }
            .buttonStyle(PlusButtonStyle())
            .padding([.leading, .bottom, .trailing])
        }
    }

    private var createNoteDataView: some View {
        Text(notes)
            .padding([.leading, .bottom, .trailing])
    }
}

// MARK: Constants
private extension OrderNotesSectionContent {
    enum Layout {
        static let verticalHeadlineSpacing: CGFloat = 22.0
        static let verticalEmailSpacing: CGFloat = 4.0
        static let verticalAddressSpacing: CGFloat = 6.0
        static let linkButtonTopPadding: CGFloat = 12.0
        static let linkButtonTrailingPadding: CGFloat = 22.0
    }

    enum Localization {
        static let notes = NSLocalizedString("Order Notes", comment: "Title text of the section that shows the Order notes when creating a new order")
        static let addNotes = NSLocalizedString("Add Note",
                                                          comment: "Title text of the button that adds notes data when creating a new order")
        static let editButton = NSLocalizedString("Edit", comment: "Button to edit a note on the New Order screen")
        static let editButtonAccessibilityLabel = NSLocalizedString(
            "Edit order notes",
            comment: "Accessibility label for the button to edit customer details on the New Order screen"
        )
    }
}

struct CustomerNotesSection_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            OrderNotesSectionContent(notes: .constant(""), showEditNotesView: .constant(false))
            OrderNotesSectionContent(notes: .constant("Some notes"), showEditNotesView: .constant(false))
        }
    }
}
