import SwiftUI

/// View for searching and selecting target locations for a Blaze campaign.
struct BlazeTargetLocationPickerView: View {

    @ObservedObject private var viewModel: BlazeTargetLocationPickerViewModel

    init(viewModel: BlazeTargetLocationPickerViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Text("Hello, World!")
    }
}

#Preview {
    BlazeTargetLocationPickerView(viewModel: .init(siteID: 123))
}
