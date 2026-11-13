#if DEBUG || ALPHA
import SwiftUI
import StoreDesignSystem

struct TabsComponentView: View {
    private enum TabCount: Int, CaseIterable, Identifiable {
        case two = 2
        case three = 3
        case four = 4
        case five = 5

        var id: Self { self }
        var title: String { "\(rawValue)" }
    }

    @State private var tabCount: TabCount = .three
    @State private var showsIcons = true
    @State private var usesLongLabels = false
    @State private var isEnabled = true
    @State private var selection = 0

    var body: some View {
        ComponentDemoScaffold(title: "Tabs") {
            Picker("Tabs", selection: $tabCount) {
                ForEach(TabCount.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            Toggle("Icons", isOn: $showsIcons)
            Toggle("Long labels", isOn: $usesLongLabels)
            Toggle("Enabled", isOn: $isEnabled)
        } preview: {
            VStack(spacing: StoreSpacing.s0) {
                StoreTabRow(selection: $selection, tabs: tabs)
                    .disabled(!isEnabled)
                Text("Selected: \(tabs.first { $0.value == selection }?.title ?? "none")")
                    .storeTextStyle(.bodyMedium)
                    .foregroundStyle(Color.storeOnSurfaceVariant)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .onChange(of: tabCount) { _, _ in
                selection = 0
            }
        }
    }

    private var tabs: [StoreTab<Int>] {
        Array(Constants.samples.prefix(tabCount.rawValue).enumerated()).map { index, sample in
            StoreTab(index,
                     title: usesLongLabels ? sample.longTitle : sample.title,
                     icon: showsIcons ? sample.icon : nil)
        }
    }
}

private extension TabsComponentView {
    enum Constants {
        static let samples: [(title: String, longTitle: String, icon: StoreIconImage)] = [
            ("Products", "All products in stock", StoreIcon.Box.regular),
            ("Orders", "Orders awaiting fulfillment", StoreIcon.List.regular),
            ("Customers", "Customers with open carts", StoreIcon.CircleInfo.regular),
            ("Settings", "Store settings and plugins", StoreIcon.Gear.regular),
            ("Store", "Storefront and channels", StoreIcon.Store.regular)
        ]
    }
}

#Preview {
    NavigationStack {
        TabsComponentView()
    }
}
#endif
