import SwiftUI

struct PointOfSaleSettingsStackView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selection: Sidebar? = .hardware

    enum Sidebar: String, CaseIterable, Identifiable {
        case hardware
        case store
        case help

        var id: Self { self }

        var title: String {
            switch self {
            case .hardware: return "Hardware"
            case .store: return "Store"
            case .help: return "Help"
            }
        }

        var subtitle: String {
            switch self {
            case .hardware: return "Manage hardware connections"
            case .store: return "Store configuration and settings"
            case .help: return "Get help and support"
            }
        }

        var icon: String {
            switch self {
            case .hardware: return "wrench.and.screwdriver"
            case .store: return "bag"
            case .help: return "questionmark.circle"
            }
        }
    }

    // Destinations
    enum HardwareDest: String, CaseIterable, Identifiable {
        case scanners
        case cardReaders
        var id: Self { self }
        var title: String {
            switch self {
            case .scanners: return "Barcode scanners"
            case .cardReaders: return "Card Readers"
            }
        }
        var subtitle: String {
            switch self {
            case .scanners: return "Configure barcode scanner settings"
            case .cardReaders: return "Manage card reader connections"
            }
        }
        var icon: String {
            switch self {
            case .scanners: return "qrcode.viewfinder"
            case .cardReaders: return "creditcard"
            }
        }
    }

    var body: some View {
        GeometryReader { geo in
            let sidebarWidth = max(280, min(geo.size.width * 0.34, 420))
            HStack(spacing: 0) {
                // Sidebar (left)
                VStack(spacing: 0) {
                    // Optional title
                    Text("Settings")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.top, 8)

                    // Top list: Hardware & Store
                    List {
                        Section {
                            ForEach([Sidebar.hardware, Sidebar.store], id: \.self) { item in
                                Button {
                                    selection = item
                                } label: {
                                    HStack(alignment: .firstTextBaseline) {
                                        Image(systemName: item.icon)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.title)
                                            Text(item.subtitle)
                                                .font(.footnote)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color.secondary.opacity(selection == item ? 0.12 : 0))
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                                .listRowBackground(Color.clear)
                            }
                        }
                        .listSectionSeparator(.hidden)
                    }
                    .listStyle(.sidebar)
                    .scrollContentBackground(.hidden)
                    .background(Color(.systemBackground))

                    Spacer(minLength: 0)

                    // Bottom pinned Help row
                    Button {
                        selection = .help
                    } label: {
                        HStack(alignment: .firstTextBaseline) {
                            Image(systemName: Sidebar.help.icon)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(Sidebar.help.title)
                                Text(Sidebar.help.subtitle)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.secondary.opacity(selection == .help ? 0.12 : 0))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
                .frame(width: sidebarWidth)

                // Detail (right)
                Group {
                    switch selection {
                    case .hardware:
                        HardwareDetail()
                    case .store:
                        StoreDetail()
                    case .help:
                        SupportDetail()
                    case .none:
                        Text("Select an option")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}


struct PointOfSaleSettingsSplitView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var selection: Sidebar? = .hardware

    enum Sidebar: String, CaseIterable, Identifiable {
        case hardware
        case store
        case help

        var id: Self { self }

        var title: String {
            switch self {
            case .hardware: return "Hardware"
            case .store: return "Store"
            case .help: return "Help"
            }
        }

        var subtitle: String {
            switch self {
            case .hardware: return "Manage hardware connections"
            case .store: return "Store configuration and settings"
            case .help: return "Get help and support"
            }
        }

        var icon: String {
            switch self {
            case .hardware: return "wrench.and.screwdriver"
            case .store: return "bag"
            case .help: return "questionmark.circle"
            }
        }
    }

    // Destinations
    enum HardwareDest: String, CaseIterable, Identifiable {
        case scanners
        case cardReaders
        var id: Self { self }
        var title: String {
            switch self {
            case .scanners: return "Barcode scanners"
            case .cardReaders: return "Card Readers"
            }
        }
        var subtitle: String {
            switch self {
            case .scanners: return "Configure barcode scanner settings"
            case .cardReaders: return "Manage card reader connections"
            }
        }
        var icon: String {
            switch self {
            case .scanners: return "qrcode.viewfinder"
            case .cardReaders: return "creditcard"
            }
        }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: $selection) {
                Section {
                    ForEach([Sidebar.hardware, Sidebar.store], id: \.self) { item in
                        HStack(alignment: .firstTextBaseline) {
                            Image(systemName: item.icon)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                Text(item.subtitle).font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                        .tag(item)
                    }
                }
                .listSectionSeparator(.visible)
                Section {
                    HStack(alignment: .firstTextBaseline) {
                        Image(systemName: Sidebar.help.icon)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(Sidebar.help.title)
                            Text(Sidebar.help.subtitle).font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                    .tag(Sidebar.help)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemBackground))
            .navigationTitle("Settings")
        } detail: {
            switch selection {
            case .hardware:
                HardwareDetail()
            case .store:
                StoreDetail()
            case .help:
                SupportDetail()
            case .none:
                Text("Select an option")
            }
        }
    }
}

private struct HardwareDetail: View {
    @Environment(\.dismiss) private var dismiss
    @State private var path: [PointOfSaleSettingsSplitView.HardwareDest] = []

    var body: some View {
        NavigationStack(path: $path) {
            List(PointOfSaleSettingsSplitView.HardwareDest.allCases) { dest in
                NavigationLink(value: dest) {
                    HStack(alignment: .firstTextBaseline) {
                        Image(systemName: dest.icon)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(dest.title)
                            Text(dest.subtitle).font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemBackground))
            .navigationTitle("Hardware")
            .navigationDestination(for: PointOfSaleSettingsSplitView.HardwareDest.self) { dest in
                VStack(spacing: 16) {
                    Image(systemName: dest.icon).font(.largeTitle)
                    Text("\(dest.title) Settings")
                    Text("This is just a placeholder view.")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .navigationTitle(dest.title)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }
}

private struct StoreDetail: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Store Settings")
                    .font(.title2)
                Text("Add store-related configuration here.")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Store")
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }
}

private struct SupportDetail: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Help")
                    .font(.title2)
                Text("Get help and support content goes here.")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Help")
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }
}

#Preview("Split View") {
    PointOfSaleSettingsSplitView()
}

#Preview("Stack View") {
    PointOfSaleSettingsStackView()
}
