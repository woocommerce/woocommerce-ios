import SwiftUI

struct AnalyticsHubManageView: View {
    // TODO: Add view model to contain view data

    // TODO: Replace with dynamic data (all available cards)
    @State private var allCards: [String] = [
        "Revenue",
        "Orders",
        "Products",
        "Sessions"
    ]

    // TODO: Replace with dynamic data (all selected/enabled cards)
    @State private var selectedCards: Set<String> = [
        "Revenue",
        "Orders"
    ]

    /// Dismisses the view.
    ///
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        MultiSelectionReorderableList(contents: $allCards, contentKeyPath: \.self, selectedItems: $selectedCards)
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
private extension AnalyticsHubManageView {
    enum Localization {
        static let title = NSLocalizedString("analyticsHub.manageAnalyticsCards.title",
                                             value: "Manage Analytics Cards",
                                             comment: "Title for the screen to manage the analytics cards in the Analytics Hub")
        static let saveButton = NSLocalizedString("analyticsHub.manageAnalytics.saveButton",
                                                  value: "Save",
                                                  comment: "Button to save changes on the Manage Analytics screen")
    }
}

#Preview {
    NavigationView {
        AnalyticsHubManageView()
    }
}
