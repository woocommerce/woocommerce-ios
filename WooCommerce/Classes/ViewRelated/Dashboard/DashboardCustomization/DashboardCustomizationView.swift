import SwiftUI

/// View for customizing layout for the Dashboard screen.
///
struct DashboardCustomizationView: View {
    @ObservedObject private var viewModel: DashboardCustomizationViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: DashboardCustomizationViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            MultiSelectionReorderableList(contents: $viewModel.allCards,
                                          contentKeyPath: \.type.name,
                                          selectedItems: $viewModel.selectedCards,
                                          inactiveItems: viewModel.inactiveCards,
                                          inactiveAccessoryView: { card in
                BadgeView(text: Localization.unavailable,
                          customizations: BadgeView.Customizations(textColor: .white,
                                                                   backgroundColor: .gray)
                          )
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
            .closeButtonWithDiscardChangesPrompt(hasChanges: viewModel.hasChanges)
        }
    }
}

// MARK: - Constants
private extension DashboardCustomizationView {
    enum Localization {
        static let title = NSLocalizedString(
            "dashboardCustomization.title",
            value: "Customize",
            comment: "Title for the screen to customize the dashboard screen"
        )
        static let saveButton = NSLocalizedString(
            "dashboardCustomization.saveButton",
            value: "Save",
            comment: "Button to save changes on the Customize Dashboard screen"
        )
        static let unavailable = NSLocalizedString(
            "dashboardCustomization.unavailable",
            value: "Unavailable",
            comment: "Text on unavailable dashboard card on the Customize Dashboard screen"
        )
    }
}

#Preview {
    DashboardCustomizationView(viewModel: DashboardCustomizationViewModel(allCards: DashboardCustomizationViewModel.sampleCards))
}
