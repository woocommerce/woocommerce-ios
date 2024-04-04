import SwiftUI
import struct Yosemite.Site

/// View for the dashboard screen
///
struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    @State private var currentSite: Site?

    init(siteID: Int64) {
        self._viewModel = StateObject(wrappedValue: DashboardViewModel(siteID: siteID))
    }

    var body: some View {
        ScrollView {
            Text(currentSite?.name ?? Localization.title)
                .secondaryBodyStyle()
                .padding(.horizontal, Layout.horizontalPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
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
        .onReceive(ServiceLocator.stores.site) { currentSite in
            self.currentSite = currentSite
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
    enum Layout {
        static let horizontalPadding: CGFloat = 16
    }
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
