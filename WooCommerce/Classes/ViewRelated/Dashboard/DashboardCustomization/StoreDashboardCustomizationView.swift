import StoreDesignSystem
import SwiftUI
import struct Yosemite.DashboardCard

/// Design-system customization screen used by the feature-flagged dashboard.
struct StoreDashboardCustomizationView: View {
    @ObservedObject private var viewModel: DashboardCustomizationViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: DashboardCustomizationViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(viewModel.allCards, id: \.type) { card in
                        StoreDashboardCustomizationRow(
                            title: card.type.name,
                            isSelected: selectionBinding(for: card),
                            canToggle: viewModel.canToggleCard(card)
                        )
                        .listRowBackground(Color.storeSurface)
                    }
                    .onMove(perform: moveCards)
                }

                if viewModel.inactiveCards.isNotEmpty {
                    Section {
                        ForEach(viewModel.inactiveCards, id: \.type) { card in
                            StoreDashboardCustomizationUnavailableRow(
                                title: card.type.name,
                                badgeTitle: Localization.unavailable
                            )
                            .listRowBackground(Color.storeSurface)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.storeSurface)
            .environment(\.editMode, .constant(.active))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveChanges) {
                        Text(Localization.saveButton)
                            .storeTextStyle(.labelLarge.emphasized)
                    }
                    .tint(.storePrimary)
                    .disabled(!viewModel.hasChanges)
                }
            }
            .navigationTitle(Localization.title)
            .navigationBarTitleDisplayMode(.inline)
            .closeButtonWithDiscardChangesPrompt(
                hasChanges: viewModel.hasChanges,
                closeButtonLabel: {
                    StoreIcon.Xmark.regular.image(size: .largeIncreased)
                        .foregroundStyle(.storeOnSurface)
                }
            )
        }
        .interactiveDismissDisabled()
    }

    private func selectionBinding(for card: DashboardCard) -> Binding<Bool> {
        Binding(
            get: { viewModel.isCardSelected(card) },
            set: { viewModel.setCard(card, selected: $0) }
        )
    }

    private func moveCards(fromOffsets source: IndexSet, toOffset destination: Int) {
        viewModel.allCards.move(fromOffsets: source, toOffset: destination)
    }

    private func saveChanges() {
        viewModel.saveChanges()
        dismiss()
    }
}

private extension StoreDashboardCustomizationView {
    enum Localization {
        static let title = NSLocalizedString(
            "storeDashboardCustomization.title",
            value: "Customize",
            comment: "Title for the design-system screen to customize the dashboard."
        )
        static let saveButton = NSLocalizedString(
            "storeDashboardCustomization.saveButton",
            value: "Save",
            comment: "Button to save changes on the design-system Customize Dashboard screen."
        )
        static let unavailable = NSLocalizedString(
            "storeDashboardCustomization.unavailable",
            value: "Unavailable",
            comment: "Badge on unavailable cards in the design-system Customize Dashboard screen."
        )
    }
}

#Preview {
    StoreDashboardCustomizationView(
        viewModel: DashboardCustomizationViewModel(allCards: DashboardCustomizationViewModel.sampleCards)
    )
}
