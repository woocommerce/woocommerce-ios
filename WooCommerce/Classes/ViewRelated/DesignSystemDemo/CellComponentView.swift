#if DEBUG || ALPHA
import SwiftUI
import StoreDesignSystem

struct CellComponentView: View {
    private enum Leading: String, CaseIterable, Identifiable {
        case none = "None"
        case icon = "Icon"
        case iconContainer = "Icon Container"

        var id: Self { self }
    }

    private enum Trailing: String, CaseIterable, Identifiable {
        case none = "None"
        case value = "Value"
        case badge = "Badge"
        case toggle = "Toggle"

        var id: Self { self }
    }

    @State private var leading: Leading = .iconContainer
    @State private var trailing: Trailing = .none
    @State private var showsDescription = true
    @State private var showsDisclosureIndicator = true
    @State private var isTappable = true
    @State private var isEnabled = true
    @State private var isToggleOn = true

    var body: some View {
        ComponentDemoScaffold(title: "Cell", previewHeight: 300) {
            Picker("Leading", selection: $leading) {
                ForEach(Leading.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            Picker("Trailing", selection: $trailing) {
                ForEach(Trailing.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            Toggle("Description", isOn: $showsDescription)
            Toggle("Disclosure indicator", isOn: $showsDisclosureIndicator)
            Toggle("Tappable", isOn: $isTappable)
            Toggle("Enabled", isOn: $isEnabled)
        } preview: {
            VStack(spacing: 0) {
                cell("Store details", description: "Manage address, currency, and contact information.")
                StoreDivider(variant: .inset)
                cell("Payments", description: "Card readers, cash, and checkout options.")
            }
            .disabled(!isEnabled)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.storeSectionBackground)
        }
    }

    private func cell(_ title: String, description: String) -> some View {
        StoreCell(title,
                  description: showsDescription ? description : nil,
                  showsDisclosureIndicator: showsDisclosureIndicator,
                  action: isTappable ? {} : nil) {
            leadingContent
        } trailing: {
            trailingContent
        }
    }

    @ViewBuilder private var leadingContent: some View {
        switch leading {
        case .none:
            EmptyView()
        case .icon:
            StoreIcon.Gear.regular.image(size: .largeIncreased)
        case .iconContainer:
            StoreIconContainer(StoreIcon.Gear.regular)
        }
    }

    @ViewBuilder private var trailingContent: some View {
        switch trailing {
        case .none:
            EmptyView()
        case .value:
            Text("USD").storeTextStyle(.bodyMedium)
        case .badge:
            StoreBadge("New", tone: .info)
        case .toggle:
            Toggle("Notifications", isOn: $isToggleOn).labelsHidden()
        }
    }
}

#Preview {
    NavigationStack {
        CellComponentView()
    }
}

#Preview("RTL") {
    NavigationStack {
        CellComponentView()
    }
    .environment(\.layoutDirection, .rightToLeft)
}
#endif
