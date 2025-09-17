import SwiftUI

struct PointOfSaleSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selection: SidebarNavigation? = .store

    let settingsController: PointOfSaleSettingsControllerProtocol

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
                                                   ServiceLocator.analytics.track(.pointOfSaleSettingsCloseButtonTapped)
                                                   dismiss()
                                               },
                                               buttonIcon: "xmark"))
            .foregroundColor(.posSurface)
            .accessibilityAddTraits(.isHeader)

            VStack(spacing: POSSpacing.small) {
                PointOfSaleSettingsCard(
                    item: .store,
                    isSelected: selection == .store,
                    onTap: {
                        ServiceLocator.analytics.track(.pointOfSaleSettingsStoreDetailsTapped)
                        selection = .store
                    }
                )

                PointOfSaleSettingsCard(
                    item: .hardware,
                    isSelected: selection == .hardware,
                    onTap: {
                        ServiceLocator.analytics.track(.pointOfSaleSettingsHardwareTapped)
                        selection = .hardware
                    }
                )

                // TODO: WOOMOB-1287 - integrate with local catalog feature eligibility
                if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.pointOfSaleLocalCatalogi1) {
                    PointOfSaleSettingsCard(
                        item: .localCatalog,
                        isSelected: selection == .localCatalog,
                        onTap: {
                            selection = .localCatalog
                        }
                    )
                }

                Spacer()

                PointOfSaleSettingsCard(
                    item: .help,
                    isSelected: selection == .help,
                    onTap: {
                        ServiceLocator.analytics.track(.pointOfSaleSettingsHelpTapped)
                        selection = .help
                    }
                )
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
            PointOfSaleSettingsHardwareDetailView(settingsController: settingsController)
        case .localCatalog:
            POSSettingsLocalCatalogDetailView()
        case .help:
            PointOfSaleSettingsHelpDetailView()
        default:
            EmptyView()
        }
    }
}

extension PointOfSaleSettingsView {
    enum Constants {
        static let sidebarWidthFraction: CGFloat = 0.35
    }
}

struct PointOfSaleSettingsCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme

    let item: PointOfSaleSettingsView.SidebarNavigation
    let isSelected: Bool
    let onTap: () -> Void

    private var selectionBackgroundColor: Color {
        guard isSelected else { return Color.clear }
        return colorScheme == .dark ? Color.posPrimary : Color.posSecondary
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: POSSpacing.medium) {
                Image(systemName: item.icon)
                    .font(.posBodyLargeRegular())
                    .foregroundStyle(Color.posOnSurface)
                    .accessibilityHidden(true)
                    .renderedIf(!dynamicTypeSize.isAccessibilitySize)

                VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                    Text(item.title)
                        .font(.posBodyLargeRegular())
                        .foregroundStyle(Color.posOnSurface)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                    Text(item.subtitle)
                        .font(.posBodyMediumRegular())
                        .foregroundStyle(Color.posOnSurface)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                }
                Spacer()
            }
            .padding(.vertical, POSPadding.small)
            .padding(.horizontal, POSPadding.medium)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
        .background(
            RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value, style: .continuous)
                .fill(selectionBackgroundColor)
        )
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

        var icon: String {
            switch self {
            case .store: return "bag"
            case .hardware: return "wrench.and.screwdriver"
            case .localCatalog: return "internaldrive"
            case .help: return "questionmark.circle"
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
            "pointOfSaleSettingsView.sidebarNavigationHelpTitle",
            value: "Help",
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
    PointOfSaleSettingsView(settingsController: PointOfSaleSettingsPreviewController())
}
#endif
