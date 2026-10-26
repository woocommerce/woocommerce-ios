import StoreDesignSystem
import SwiftUI

/// Store Design System implementation of the More tab root content.
struct StoreHubMenuList: View {
    @ObservedObject private var viewModel: HubMenuViewModel

    private let onSwitchStore: () -> Void
    private let onMenuItemTap: (HubMenuItem) -> Void

    init(viewModel: HubMenuViewModel,
         onSwitchStore: @escaping () -> Void,
         onMenuItemTap: @escaping (HubMenuItem) -> Void) {
        self.viewModel = viewModel
        self.onSwitchStore = onSwitchStore
        self.onMenuItemTap = onMenuItemTap
    }

    var body: some View {
        ScrollView {
            VStack(spacing: StoreSpacing.s7) {
                StoreHubMenuHeader(
                    storeTitle: viewModel.storeTitle,
                    planName: viewModel.planName,
                    storeURL: viewModel.storeURL,
                    avatarURL: viewModel.avatarURL,
                    switchStoreEnabled: viewModel.switchStoreEnabled,
                    onSwitchStore: onSwitchStore
                )

                StoreHubMenuSection(
                    title: HubMenuViewModel.Localization.settings,
                    items: viewModel.settingsElements,
                    onMenuItemTap: onMenuItemTap
                )

                StoreHubMenuSection(
                    title: HubMenu.Localization.general,
                    items: viewModel.generalElements,
                    onMenuItemTap: onMenuItemTap
                )
            }
            .padding(.horizontal, StorePadding.p7)
            .padding(.vertical, StorePadding.p7)
        }
        .background(Color.storeSurface)
    }
}
