import SwiftUI

struct PointOfSaleSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selection: Sidebar? = .store

    enum Sidebar: String, CaseIterable, Identifiable {
        case store
        case hardware
        case help

        var id: Self { self }

        var title: String {
            switch self {
            case .store: return "Store"
            case .hardware: return "Hardware"
            case .help: return "Help"
            }
        }

        var subtitle: String {
            switch self {
            case .store: return "Store configuration and settings"
            case .hardware: return "Manage hardware connections"
            case .help: return "Get help and support"
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

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                // Left (nav)
                List(selection: $selection) {
                    // Store, Hardware
                    Section {
                        ForEach([Sidebar.store, Sidebar.hardware], id: \.self) { item in
                            HStack {
                                Image(systemName: item.icon)
                                VStack {
                                    Text(item.title)
                                    Text(item.subtitle)
                                }
                            }
                            .tag(item)
                        }
                    }
                    // Help
                    Section {
                        HStack {
                            Image(systemName: Sidebar.help.icon)
                            VStack {
                                Text(Sidebar.help.title)
                                Text(Sidebar.help.subtitle)
                            }
                        }
                        .tag(Sidebar.help)
                    }
                }
                // Right (detail)
                Group {
                    switch selection {
                    case .store:
                        SettingsDetailView()
                    case .hardware:
                        SettingsDetailView()
                    case .help:
                        SettingsDetailView()
                    default:
                        //
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
            }
        }
    }
}

struct SettingsDetailView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Some title")
                    .font(.title2)
                Text("Content goes here.")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("nav title")
        }
    }
}

#Preview {
    PointOfSaleSettingsView()
}
