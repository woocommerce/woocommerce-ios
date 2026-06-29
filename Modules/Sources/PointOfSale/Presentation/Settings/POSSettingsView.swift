import SwiftUI

struct POSSettingsView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selection: SidebarNavigation?

    let settingsController: POSSettingsControllerProtocol

    var body: some View {
        POSNavigationSplitView(selection: $selection) { selection in
            POSSettingsListView(selection: selection, settingsController: settingsController)
        } detail: { selection, navigationPath in
            detailView(for: selection, navigationPath: navigationPath)
                .environment(\.posHeaderBackButtonConfiguration,
                             horizontalSizeClass == .compact ?
                                .init(state: .enabled, action: { self.selection = nil }) : nil)
        } detailPlaceholderView: {
            POSSettingsStoreDetailView(viewModel: settingsController.storeViewModel)
        } setDefaultValue: {
            if selection == nil {
                selection = .store
            }
        }
    }
}

extension POSSettingsView {
    private struct POSSettingsListView: View {
        @Environment(\.dismiss) private var dismiss
        @Environment(\.posAnalytics) private var analytics
        @Binding var selection: SidebarNavigation?

        let settingsController: POSSettingsControllerProtocol

        var body: some View {
            VStack(alignment: .leading, spacing: POSSpacing.none) {
                POSPageHeaderView(
                    title: Localization.navigationTitle,
                    backButtonConfiguration: .init(state: .enabled,
                                                   action: {
                                                       analytics.track(.pointOfSaleSettingsCloseButtonTapped)
                                                       dismiss()
                                                   }))
                .posHeaderBackButtonIcon(systemName: "xmark")
                .foregroundColor(.posSurface)
                .accessibilityAddTraits(.isHeader)

                VStack(spacing: POSSpacing.small) {
                    POSSettingsCard(title: SidebarNavigation.store.title,
                                    subtitle: SidebarNavigation.store.subtitle,
                                    isSelected: selection == .store,
                                    action: {
                        analytics.track(.pointOfSaleSettingsStoreDetailsTapped)
                        selection = .store
                    })
                    POSSettingsCard(title: SidebarNavigation.hardware.title,
                                    subtitle: SidebarNavigation.hardware.subtitle,
                                    isSelected: selection == .hardware,
                                    action: {
                        analytics.track(.pointOfSaleSettingsHardwareTapped)
                        selection = .hardware
                    })
                    if settingsController.isLocalCatalogEligible {
                        POSSettingsCard(title: SidebarNavigation.localCatalog.title,
                                        subtitle: SidebarNavigation.localCatalog.subtitle,
                                        isSelected: selection == .localCatalog,
                                        action: {
                            selection = .localCatalog
                        })
                    }
                    if isStaffSectionVisible {
                        POSSettingsCard(title: SidebarNavigation.staff.title,
                                        subtitle: SidebarNavigation.staff.subtitle,
                                        isSelected: selection == .staff,
                                        action: {
                            selection = .staff
                        })
                    }
                    Spacer()

                    helpView
                }
                .padding(.horizontal, POSPadding.medium)
            }
            .background(Color.posSurfaceBright)
            .accessibilityIdentifier("pos-settings-view")
        }

        private var isStaffSectionVisible: Bool {
            settingsController.staffSettingsService != nil
        }

        @ViewBuilder
        private var helpView: some View {
            Button {
                analytics.track(.pointOfSaleSettingsHelpTapped)
                selection = .help
            } label: {
                HStack(spacing: POSSpacing.small) {
                    if let icon = SidebarNavigation.help.icon {
                        Image(systemName: icon)
                            .font(.posBodyMediumBold)
                            .foregroundStyle(Color.posOnSurface)
                    }
                    Text(SidebarNavigation.help.title)
                        .font(.posBodyMediumBold)
                        .foregroundStyle(Color.posOnSurface)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(SidebarNavigation.help.title)
        }
    }

    @ViewBuilder
    private func detailView(for selection: SidebarNavigation, navigationPath: Binding<NavigationPath>) -> some View {
        switch selection {
        case .store:
            POSSettingsStoreDetailView(viewModel: settingsController.storeViewModel)
        case .hardware:
            POSSettingsHardwareDetailView(settingsController: settingsController, navigationPath: navigationPath)
        case .localCatalog:
            if let viewModel = settingsController.localCatalogViewModel {
                POSSettingsLocalCatalogDetailView(viewModel: viewModel)
            } else {
                EmptyView()
            }
        case .staff:
            if let staffSettingsService = settingsController.staffSettingsService {
                POSStaffSettingsView(service: staffSettingsService)
            } else {
                EmptyView()
            }
        case .help:
            POSSettingsHelpDetailView()
        }
    }
}

extension POSSettingsView {
    enum SidebarNavigation: String, CaseIterable, Identifiable {
        case store
        case hardware
        case localCatalog
        case staff
        case help

        var id: Self { self }

        var title: String {
            switch self {
            case .store: return Localization.sidebarNavigationStoreTitle
            case .hardware: return Localization.sidebarNavigationHardwareTitle
            case .localCatalog: return Localization.sidebarNavigationLocalCatalogTitle
            case .staff: return Localization.sidebarNavigationStaffTitle
            case .help: return Localization.sidebarNavigationHelpTitle
            }
        }

        var subtitle: String {
            switch self {
            case .store: return Localization.sidebarNavigationStoreSubtitle
            case .hardware: return Localization.sidebarNavigationHardwareSubtitle
            case .localCatalog: return Localization.sidebarNavigationLocalCatalogSubtitle
            case .staff: return Localization.sidebarNavigationStaffSubtitle
            case .help: return Localization.sidebarNavigationHelpSubtitle
            }
        }

        var icon: String? {
            switch self {
            case .store, .hardware, .localCatalog, .staff:
                return nil
            case .help:
                return "questionmark.circle"
            }
        }
    }

    enum Localization {
        static let navigationTitle = NSLocalizedString(
            "pointOfSaleSettingsView.navigationTitle",
            value: "Settings",
            comment: "Title of the Point of Sale settings view."
        )

        static let sidebarNavigationStoreTitle = NSLocalizedString(
            "pointOfSaleSettingsView.sidebarNavigationStoreTitle",
            value: "Store",
            comment: "Title of the Store section within Point of Sale settings."
        )

        static let sidebarNavigationHardwareTitle = NSLocalizedString(
            "pointOfSaleSettingsView.sidebarNavigationHardwareTitle",
            value: "Hardware",
            comment: "Title of the Hardware section within Point of Sale settings."
        )

        static let sidebarNavigationHelpTitle = NSLocalizedString(
            "pointOfSaleSettingsView.sidebarNavigationHelpTitle.1",
            value: "Get help and support",
            comment: "Title of the Help section within Point of Sale settings."
        )

        static let sidebarNavigationStoreSubtitle = NSLocalizedString(
            "pointOfSaleSettingsView.sidebarNavigationStoreSubtitle",
            value: "Store configuration and settings",
            comment: "Description of the settings to be found within the Store section."
        )

        static let sidebarNavigationHardwareSubtitle = NSLocalizedString(
            "pointOfSaleSettingsView.sidebarNavigationHardwareSubtitle",
            value: "Manage hardware connections",
            comment: "Description of the settings to be found within the Hardware section."
        )

        static let sidebarNavigationLocalCatalogTitle = NSLocalizedString(
            "pointOfSaleSettingsView.sidebarNavigationLocalCatalogTitle.2",
            value: "Product catalog",
            comment: "Title of the Local catalog section within Point of Sale settings."
        )

        static let sidebarNavigationLocalCatalogSubtitle = NSLocalizedString(
            "pointOfSaleSettingsView.sidebarNavigationLocalCatalogSubtitle",
            value: "Manage catalog settings",
            comment: "Description of the settings to be found within the Local catalog section."
        )

        static let sidebarNavigationStaffTitle = NSLocalizedString(
            "pointOfSaleSettingsView.sidebarNavigationStaffTitle",
            value: "Staff",
            comment: "Title of the Staff section within Point of Sale settings."
        )

        static let sidebarNavigationStaffSubtitle = NSLocalizedString(
            "pointOfSaleSettingsView.sidebarNavigationStaffSubtitle.m1",
            value: "View staff and PIN access",
            comment: "Description of the settings to be found within the Staff section."
        )

        static let sidebarNavigationHelpSubtitle = NSLocalizedString(
            "pointOfSaleSettingsView.sidebarNavigationHelpSubtitle",
            value: "Get help and support",
            comment: "Description of the Help section in Point of Sale settings."
        )
    }
}

#if DEBUG
#Preview {
    POSSettingsView(settingsController: POSSettingsPreviewController())
}
#endif
