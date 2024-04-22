import SwiftUI

struct AnalyticsHubCustomizeView: View {
    @ObservedObject var viewModel: AnalyticsHubCustomizeViewModel

    @State private var selectedPromoURL: URL?

    /// Dismisses the view.
    ///
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        MultiSelectionReorderableList(contents: $viewModel.allCards,
                                      contentKeyPath: \.name,
                                      selectedItems: $viewModel.selectedCards,
                                      inactiveItems: viewModel.inactiveCards,
                                      inactiveItemTapGesture: { card in
            openWebview(for: viewModel.promoURL(for: card))
        },
                                      inactiveAccessoryView: { card in
            exploreButton(with: viewModel.promoURL(for: card))
        })
        .toolbar(content: {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    viewModel.saveChanges()
                    dismiss()
                } label: {
                    Text(Localization.saveButton)
                }
                .disabled(!viewModel.hasChanges)
            }
        })
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(uiColor: .listBackground))
        .wooNavigationBarStyle()
        .closeButtonWithDiscardChangesPrompt(hasChanges: viewModel.hasChanges)
        .sheet(item: $selectedPromoURL) { url in
            WebViewSheet(viewModel: .init(url: url, navigationTitle: "", authenticated: false), done: {
                selectedPromoURL = nil
            })
        }
    }
}

private extension AnalyticsHubCustomizeView {
    /// Creates a button with a link to the provided promo URL, to explore inactive extensions.
    ///
    @ViewBuilder func exploreButton(with promoURL: URL?) -> some View {
        if let promoURL {
            Button {
                openWebview(for: promoURL)
            } label: {
                Text(Localization.explore)
                    .foregroundColor(Color(.primary))
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.roundedRectangle)
            .controlSize(.mini)
        } else {
            EmptyView()
        }
    }

    /// Opens the provided URL in a webview.
    ///
    func openWebview(for promoURL: URL?) {
        selectedPromoURL = promoURL
    }
}

// MARK: - Constants
private extension AnalyticsHubCustomizeView {
    enum Localization {
        static let title = NSLocalizedString("analyticsHub.customizeAnalytics.title",
                                             value: "Customize Analytics",
                                             comment: "Title for the screen to customize the analytics cards in the Analytics Hub")
        static let saveButton = NSLocalizedString("analyticsHub.customizeAnalytics.saveButton",
                                                  value: "Save",
                                                  comment: "Button to save changes on the Customize Analytics screen")
        static let explore = NSLocalizedString("analyticsHub.customizeAnalytics.exploreButton",
                                               value: "Explore",
                                               comment: "Button title to explore an extension that isn't installed")
    }
}

#Preview {
    NavigationView {
        AnalyticsHubCustomizeView(viewModel: AnalyticsHubCustomizeViewModel(allCards: AnalyticsHubCustomizeViewModel.sampleCards))
    }
}

#Preview("Inactive cards") {
    NavigationView {
        AnalyticsHubCustomizeView(viewModel: AnalyticsHubCustomizeViewModel(allCards: [], inactiveCards: AnalyticsHubCustomizeViewModel.sampleCards))
    }
}
