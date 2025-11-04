import SwiftUI

struct PointOfSaleSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.posAnalytics) private var analytics
    @State private var selection: SidebarNavigation? = .store

    let settingsController: POSSettingsControllerProtocol

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: POSSpacing.none) {
                listView
                .frame(width: geometry.size.width * Constants.sidebarWidthFraction)

                detailView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

extension PointOfSaleSettingsView {
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
                POSSettingsCardView(title: PointOfSaleSettingsView.SidebarNavigation.store.title,
                                    subtitle: PointOfSaleSettingsView.SidebarNavigation.store.subtitle,
                                    isSelected: selection == .store,
                                    action: {
                    analytics.track(.pointOfSaleSettingsStoreDetailsTapped)
                    selection = .store
                })
                POSSettingsCardView(title: PointOfSaleSettingsView.SidebarNavigation.hardware.title,
                                    subtitle: PointOfSaleSettingsView.SidebarNavigation.hardware.subtitle,
                                    isSelected: selection == .hardware,
                                    action: {
                    analytics.track(.pointOfSaleSettingsHardwareTapped)
                    selection = .hardware
                })
                if settingsController.isLocalCatalogEligible {
                    POSSettingsCardView(title: PointOfSaleSettingsView.SidebarNavigation.localCatalog.title,
                                        subtitle: PointOfSaleSettingsView.SidebarNavigation.localCatalog.subtitle,
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
        .background(Color.posSurface)
    }

    @ViewBuilder
    private var detailView: some View {
        switch selection {
        case .store:
            PointOfSaleSettingsStoreDetailView(viewModel: settingsController.storeViewModel)
        case .hardware:
            POSSettingsHardwareDetailView(settingsController: settingsController)
        case .localCatalog:
            if let viewModel = settingsController.localCatalogViewModel {
                POSSettingsLocalCatalogDetailView(viewModel: viewModel)
            } else {
                EmptyView()
            }
        case .help:
            PointOfSaleSettingsHelpDetailView()
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
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(SidebarNavigation.help.title)
    }
}

extension PointOfSaleSettingsView {
    enum Constants {
        static let sidebarWidthFraction: CGFloat = 0.35
    }
}

extension PointOfSaleSettingsView {
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
            "pointOfSaleSettingsView.sidebarNavigationLocalCatalogTitle",
            value: "Catalog",
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
    }
}

#if DEBUG
#Preview {
    PointOfSaleSettingsView(settingsController: POSSettingsPreviewController())
}
#endif
