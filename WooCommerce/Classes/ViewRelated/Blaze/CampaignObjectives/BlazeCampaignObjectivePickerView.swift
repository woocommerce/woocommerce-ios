import SwiftUI

/// View for picking campaign objective for Blaze campaign creation
///
struct BlazeCampaignObjectivePickerView: View {
    @ObservedObject private var viewModel: BlazeCampaignObjectivePickerViewModel

    private let onDismiss: () -> Void

    init(viewModel: BlazeCampaignObjectivePickerViewModel,
         onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    BlazeCampaignObjectivePickerView(viewModel: .init(siteID: 123, onSelection: { _ in }), onDismiss: {})
}
