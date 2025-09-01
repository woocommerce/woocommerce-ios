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
    }

    @ViewBuilder
    private var detailView: some View {
        switch selection {
        case .store:
            PointOfSaleSettingsStoreDetailView(viewModel: settingsController.storeViewModel)
        case .hardware:
            PointOfSaleSettingsHardwareDetailView(settingsController: settingsController)
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
    let item: PointOfSaleSettingsView.SidebarNavigation
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: item.icon)
                    .font(.posBodyLargeRegular())
                    .foregroundStyle(isSelected ? .white : .primary)
                VStack(alignment: .leading) {
                    Text(item.title)
                        .font(.posBodyLargeRegular())
                        .foregroundStyle(isSelected ? .white : .primary)
                    Text(item.subtitle)
                        .font(.posBodyMediumRegular())
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                }
                Spacer()
            }
            .padding(.vertical, POSPadding.small)
            .padding(.horizontal, POSPadding.medium)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: POSCornerRadiusStyle.large.value, style: .continuous)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
    }
}

extension PointOfSaleSettingsView {
    enum SidebarNavigation: String, CaseIterable, Identifiable {
        case store
        case hardware
        case help

        var id: Self { self }

        var title: String {
            switch self {
            case .store: return Localization.sidebarNavigationStoreTitle
            case .hardware: return Localization.sidebarNavigationHardwareTitle
            case .help: return Localization.sidebarNavigationHelpTitle
            }
        }

        var subtitle: String {
            switch self {
            case .store: return Localization.sidebarNavigationStoreSubtitle
            case .hardware: return Localization.sidebarNavigationHardwareSubtitle
            case .help: return Localization.sidebarNavigationHelpSubtitle
            }
        }

        var icon: String {
            switch self {
            case .store: return "bag"
            case .hardware: return "wrench.and.screwdriver"
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
