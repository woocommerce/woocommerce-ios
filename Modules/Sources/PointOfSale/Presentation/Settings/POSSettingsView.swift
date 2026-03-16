import SwiftUI

struct POSSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.posAnalytics) private var analytics
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selection: SidebarNavigation? = .store

    let settingsController: POSSettingsControllerProtocol

    var body: some View {
        if horizontalSizeClass == .compact {
            compactLayout
        } else {
            regularLayout
        }
    }

    private var regularLayout: some View {
        GeometryReader { geometry in
            HStack(spacing: POSSpacing.none) {
                listView
                .frame(width: geometry.size.width * Constants.sidebarWidthFraction)

                detailView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var compactLayout: some View {
        NavigationStack {
            VStack(spacing: POSSpacing.none) {
                List {
                    Section {
                        NavigationLink {
                            POSSettingsStoreDetailView(viewModel: settingsController.storeViewModel)
                        } label: {
                            settingsRow(title: SidebarNavigation.store.title,
                                        subtitle: SidebarNavigation.store.subtitle)
                        }

                        NavigationLink {
                            POSSettingsHardwareDetailView(settingsController: settingsController)
                        } label: {
                            settingsRow(title: SidebarNavigation.hardware.title,
                                        subtitle: SidebarNavigation.hardware.subtitle)
                        }

                        if settingsController.isLocalCatalogEligible,
                           let viewModel = settingsController.localCatalogViewModel {
                            NavigationLink {
                                POSSettingsLocalCatalogDetailView(viewModel: viewModel)
                            } label: {
                                settingsRow(title: SidebarNavigation.localCatalog.title,
                                            subtitle: SidebarNavigation.localCatalog.subtitle)
                            }
                        }

                        NavigationLink {
                            POSSettingsHelpDetailView()
                        } label: {
                            settingsRow(title: SidebarNavigation.help.title,
                                        subtitle: SidebarNavigation.help.subtitle)
                        }
                    }
                }
                .listStyle(.insetGrouped)

                exitButton
                    .padding(.horizontal, POSPadding.medium)
                    .padding(.bottom, POSPadding.medium)
            }
            .navigationTitle(Localization.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func settingsRow(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            Text(title)
                .font(.posBodyMediumBold)
            Text(subtitle)
                .font(.posBodySmallRegular())
                .foregroundStyle(Color.posOnSurfaceVariantLowest)
        }
    }

    @State private var showExitPOSModal: Bool = false

    private var exitButton: some View {
        Button(role: .destructive) {
            analytics.track(.pointOfSaleExitMenuItemTapped)
            showExitPOSModal = true
        } label: {
            Text(Localization.exitPointOfSale)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(POSOutlinedButtonStyle(size: .normal))
        .posModal(isPresented: $showExitPOSModal) {
            PointOfSaleExitPosAlertView(isPresented: $showExitPOSModal)
        }
    }
}

extension POSSettingsView {
    @ViewBuilder
    private var listView: some View {
        VStack(alignment: .leading, spacing: POSSpacing.none) {
            POSPageHeaderView(
                title: Localization.navigationTitle,
                backButtonConfiguration: .init(state: .enabled,
                                               action: {
                                                   analytics.track(.pointOfSaleSettingsCloseButtonTapped)
                                                   dismiss()
                                               },
                                               buttonIcon: "chevron.left"))
            .foregroundColor(.posSurface)
            .accessibilityAddTraits(.isHeader)

            VStack(spacing: POSSpacing.small) {
                POSSettingsCard(title: POSSettingsView.SidebarNavigation.store.title,
                                    subtitle: POSSettingsView.SidebarNavigation.store.subtitle,
                                    isSelected: selection == .store,
                                    action: {
                    analytics.track(.pointOfSaleSettingsStoreDetailsTapped)
                    selection = .store
                })
                POSSettingsCard(title: POSSettingsView.SidebarNavigation.hardware.title,
                                    subtitle: POSSettingsView.SidebarNavigation.hardware.subtitle,
                                    isSelected: selection == .hardware,
                                    action: {
                    analytics.track(.pointOfSaleSettingsHardwareTapped)
                    selection = .hardware
                })
                if settingsController.isLocalCatalogEligible {
                    POSSettingsCard(title: POSSettingsView.SidebarNavigation.localCatalog.title,
                                        subtitle: POSSettingsView.SidebarNavigation.localCatalog.subtitle,
                                        isSelected: selection == .localCatalog,
                                        action: {
                        selection = .localCatalog
                    })
                }
                Spacer()

                helpView
            }
            .padding(.horizontal, POSPadding.medium)
        }
        .background(Color.posSurfaceBright)
    }

    @ViewBuilder
    private var detailView: some View {
        switch selection {
        case .store:
            POSSettingsStoreDetailView(viewModel: settingsController.storeViewModel)
        case .hardware:
            POSSettingsHardwareDetailView(settingsController: settingsController)
        case .localCatalog:
            if let viewModel = settingsController.localCatalogViewModel {
                POSSettingsLocalCatalogDetailView(viewModel: viewModel)
            } else {
                EmptyView()
            }
        case .help:
            POSSettingsHelpDetailView()
        default:
            EmptyView()
        }
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

extension POSSettingsView {
    enum Constants {
        static let sidebarWidthFraction: CGFloat = 0.35
    }
}

extension POSSettingsView {
    enum SidebarNavigation: String, CaseIterable, Identifiable {
        case store
        case hardware
        case localCatalog
        case help

        var id: Self { self }

        var title: String {
            switch self {
            case .store: return Localization.sidebarNavigationStoreTitle
            case .hardware: return Localization.sidebarNavigationHardwareTitle
            case .localCatalog: return Localization.sidebarNavigationLocalCatalogTitle
            case .help: return Localization.sidebarNavigationHelpTitle
            }
        }

        var subtitle: String {
            switch self {
            case .store: return Localization.sidebarNavigationStoreSubtitle
            case .hardware: return Localization.sidebarNavigationHardwareSubtitle
            case .localCatalog: return Localization.sidebarNavigationLocalCatalogSubtitle
            case .help: return Localization.sidebarNavigationHelpSubtitle
            }
        }

        var icon: String? {
            switch self {
            case .store, .hardware, .localCatalog:
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

        static let sidebarNavigationHelpSubtitle = NSLocalizedString(
            "pointOfSaleSettingsView.sidebarNavigationHelpSubtitle",
            value: "Get help and support",
            comment: "Description of the Help section in Point of Sale settings."
        )

        static let exitPointOfSale = NSLocalizedString(
            "pointOfSaleSettingsView.exitPointOfSale",
            value: "Exit Point of Sale",
            comment: "Title for the Exit Point of Sale button in settings on phone POS"
        )
    }
}

#if DEBUG
#Preview {
    POSSettingsView(settingsController: POSSettingsPreviewController())
}
#endif
