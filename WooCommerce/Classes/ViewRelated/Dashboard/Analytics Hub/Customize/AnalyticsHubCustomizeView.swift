import SwiftUI

struct AnalyticsHubCustomizeView: View {
    @ObservedObject var viewModel: AnalyticsHubCustomizeViewModel

    /// Dismisses the view.
    ///
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        MultiSelectionReorderableList(contents: $viewModel.allCards, contentKeyPath: \.name, selectedItems: $viewModel.selectedCards)
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
        AnalyticsHubCustomizeView(viewModel: AnalyticsHubCustomizeViewModel(allCards: AnalyticsHubCustomizeViewModel.sampleCards))
    }
}
