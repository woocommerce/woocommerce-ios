import SwiftUI

struct AnalyticsHubCustomizeView: View {
    // TODO: Initialize with real data
    @ObservedObject var viewModel = AnalyticsHubCustomizeViewModel(allCards: [
        "Revenue",
        "Orders",
        "Products",
        "Sessions"
    ], selectedCards: [
        "Revenue",
        "Orders"
    ])

    /// Dismisses the view.
    ///
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        MultiSelectionReorderableList(contents: $viewModel.allCards, contentKeyPath: \.self, selectedItems: $viewModel.selectedCards)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        dismiss() // TODO: Show discard changes prompt when there are changes
                    }, label: {
                        Image(uiImage: .closeButton)
                            .secondaryBodyStyle()
                    })
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss() // TODO: Save changes
                    } label: {
                        Text(Localization.saveButton)
                    } // TODO: Disable when there are no changes to save
                }
            })
            .navigationTitle(Localization.title)
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(uiColor: .listBackground))
            .wooNavigationBarStyle()
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
    }
}

#Preview {
    NavigationView {
        AnalyticsHubCustomizeView()
    }
}
