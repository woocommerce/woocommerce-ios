import SwiftUI

struct BookingListView: View {
    // periphery:ignore
    @ObservedObject private var viewModel: BookingListViewModel

    init(viewModel: BookingListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Text("Hello, World!")
    }
}
