import SwiftUI

struct PointOfSaleSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selection: SidebarNavigation? = .store

    var body: some View {
        NavigationStack {
            HStack(spacing: POSSpacing.none) {
                VStack {
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
                        HStack {
                            Image(systemName: SidebarNavigation.help.icon)
                                .font(.posBodyLargeRegular())
                            VStack(alignment: .leading) {
                                Text(SidebarNavigation.help.title)
                                    .font(.posBodyLargeRegular())
                                Text(SidebarNavigation.help.subtitle)
                                    .font(.posBodyMediumRegular())
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, POSPadding.small)
                        .padding(.horizontal, POSPadding.medium)
                        .onTapGesture { selection = .help }
                    }
                }
                Group {
                    switch selection {
                    case .store:
                        PointOfSaleSettingsStoreDetailView()
                    case .hardware:
                        PointOfSaleSettingsHardwareDetailView()
                    case .help:
                        PointOfSaleSettingsHelpDetailView()
                    default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle(Localization.navigationTitle)
                .font(.posHeadingRegular)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
            }
        }
    }
}

struct PointOfSaleSettingsStoreDetailView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Text("Store Settings")
                    .font(.title2)
                Text("Store-related configuration")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

struct PointOfSaleSettingsHardwareDetailView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Text("Hardware Settings")
                    .font(.title2)
                Text("Hardware-related configuration")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

struct PointOfSaleSettingsHelpDetailView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Text("Help Settings")
                    .font(.title2)
                Text("Help-related configuration")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
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

#Preview {
    PointOfSaleSettingsView()
}
