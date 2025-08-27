import SwiftUI

struct PointOfSaleSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selection: SidebarNavigation? = .store

    let settingsController: PointOfSaleSettingsControllerProtocol

    var body: some View {
        POSPageHeaderView(
            title: Localization.navigationTitle,
            trailingContent: {
                Button(action: { dismiss() }) {
                    Text(Image(systemName: "xmark"))
                        .font(.posButtonSymbolLarge)
                }
                .foregroundColor(.posOnSurface)
            })
        GeometryReader { geometry in
            HStack(spacing: POSSpacing.none) {
                VStack(alignment: .leading, spacing: POSSpacing.none) {
                    List(selection: $selection) {
                        Section {
                            ForEach([SidebarNavigation.store, SidebarNavigation.hardware], id: \.self) { item in
                                HStack {
                                    Image(systemName: item.icon)
                                        .font(.posBodyLargeRegular())
                                    VStack(alignment: .leading) {
                                        Text(item.title)
                                            .font(.posBodyLargeRegular())
                                        Text(item.subtitle)
                                            .font(.posBodyMediumRegular())
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .tag(item)
                            }
                        }
                    }
                    .safeAreaInset(edge: .bottom) {
                        Button {
                            selection = .help
                        } label: {
                            HStack {
                                Image(systemName: SidebarNavigation.help.icon)
                                    .font(.posBodyLargeRegular())
                                    .foregroundStyle(selection == .help ? .white : .primary)
                                VStack(alignment: .leading) {
                                    Text(SidebarNavigation.help.title)
                                        .font(.posBodyLargeRegular())
                                        .foregroundStyle(selection == .help ? .white : .primary)
                                    Text(SidebarNavigation.help.subtitle)
                                        .font(.posBodyMediumRegular())
                                        .foregroundStyle(selection == .help ? .secondary : .secondary)
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
                                .fill(selection == .help ? Color.accentColor : Color.clear)
                        )
                    }
                }
                .frame(width: geometry.size.width * Constants.sidebarWidthFraction)

                detailView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .task {
                await settingsController.retrievePOSReceiptSettings()
            }
        }
    }
}

extension PointOfSaleSettingsView {
    @ViewBuilder
    private var detailView: some View {
        switch selection {
        case .store:
            PointOfSaleSettingsStoreDetailView(settingsController: settingsController)
        case .hardware:
            PointOfSaleSettingsHardwareDetailView()
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

private extension PointOfSaleSettingsView {
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
