import SwiftUI

/// View for store performance on Dashboard screen
///
struct StorePerformanceView: View {
    @ObservedObject private var viewModel: StorePerformanceViewModel

    init(viewModel: StorePerformanceViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Text("Hello, World!")
    }
}

#Preview {
    StorePerformanceView(viewModel: StorePerformanceViewModel())
}
