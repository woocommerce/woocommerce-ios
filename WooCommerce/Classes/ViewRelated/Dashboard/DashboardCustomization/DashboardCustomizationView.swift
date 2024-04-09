import SwiftUI

/// View for customizing layout for the Dashboard screen.
/// 
struct DashboardCustomizationView: View {
    @ObservedObject private var viewModel: DashboardCustomizationViewModel

    init(viewModel: DashboardCustomizationViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    DashboardCustomizationView(viewModel: DashboardCustomizationViewModel())
}
