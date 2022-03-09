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
        Text("Empty")
    }
}
