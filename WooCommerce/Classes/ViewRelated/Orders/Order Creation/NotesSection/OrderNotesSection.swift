import SwiftUI

struct OrderNotesSection: View {
    /// Parent view model to access all data
    @ObservedObject var viewModel: NewOrderViewModel

    @State private var showEditNotesView: Bool = false

    var body: some View {
        OrderNotesSectionContent(viewModel: viewModel.orderNotesDataViewModel, showEditNotesView: $showEditNotesView)
    }
}

private struct OrderNotesSectionContent: View {
    /// View model to drive the view content
    var viewModel: NewOrderViewModel.OrderNotesDataViewModel

    @Binding var showEditNotesView: Bool

    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
                    HStack(alignment: .top) {
                        Text(Localization.notes)
                            .headlineStyle()
                    }.padding([.leading, .top, .trailing])

                    if viewModel.notes.isEmpty {
                        createOrderNotesView
                    } else {
                        createNoteDataView
                    }
                }
                .padding(.horizontal, insets: safeAreaInsets)
                .background(Color(.listForeground))
                .addingTopAndBottomDividers()
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
        Text(viewModel.notes)
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
        static let notes = NSLocalizedString("Customer note", comment: "Title text of the section that shows the Order notes when creating a new order")
        static let addNotes = NSLocalizedString("Add note",
                                                          comment: "Title text of the button that adds notes data when creating a new order")
        static let editButton = NSLocalizedString("Edit", comment: "Button to edit a note on the New Order screen")
        static let editButtonAccessibilityLabel = NSLocalizedString(
            "Edit customer notes",
            comment: "Accessibility label for the button to edit customer details on the New Order screen"
        )
    }
}

struct CustomerNotesSection_Previews: PreviewProvider {
    static var previews: some View {
        let emptyViewModel = NewOrderViewModel.OrderNotesDataViewModel(notes: "")
        let notesViewModel = NewOrderViewModel.OrderNotesDataViewModel(notes: "Some notes")

        ScrollView {
            OrderNotesSectionContent(viewModel: emptyViewModel, showEditNotesView: .constant(false))
            OrderNotesSectionContent(viewModel: notesViewModel, showEditNotesView: .constant(false))
        }
    }
}
