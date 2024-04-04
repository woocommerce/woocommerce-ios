import SwiftUI

/// View for the dashboard screen
///
struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel

    init(siteID: Int64) {
        self._viewModel = StateObject(wrappedValue: DashboardViewModel(siteID: siteID))
    }

    var body: some View {
        Text("Hello, World!")
            .navigationTitle(Localization.title)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if let url = viewModel.siteURLToShare {
                        ShareLink(item: url) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
    }
}

// MARK: Private helpers
//
private extension DashboardView {
    // TODO
}

// MARK: Subtypes
private extension DashboardView {
    enum Localization {
        static let title = NSLocalizedString(
            "dashboardView.title",
            value: "My store",
            comment: "Title of the bottom tab item that presents the user's store dashboard, and default title for the store dashboard"
        )
    }
}

#Preview {
    DashboardView(siteID: 123)
}
