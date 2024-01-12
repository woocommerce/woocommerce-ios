import SwiftUI

/// View for searching and selecting target locations for a Blaze campaign.
struct BlazeTargetLocationPickerView: View {

    @ObservedObject private var viewModel: BlazeTargetLocationPickerViewModel
    private let onDismiss: () -> Void

    init(viewModel: BlazeTargetLocationPickerViewModel,
         onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    var body: some View {
        Text("Hello, World!")
    }
}

#Preview {
    BlazeTargetLocationPickerView(viewModel: .init(siteID: 123) { _ in }) {}
}
