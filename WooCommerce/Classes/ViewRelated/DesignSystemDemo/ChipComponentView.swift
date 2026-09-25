#if DEBUG || ALPHA
import SwiftUI
import StoreDesignSystem

struct ChipComponentView: View {
    private static let filters = ["All", "Processing", "On hold", "Completed", "Refunded"]

    @State private var showsLeadingIcon = true
    @State private var showsTrailingIcon = false
    @State private var isEnabled = true
    @State private var selectedFilters: Set<String> = ["Processing"]

    var body: some View {
        ComponentDemoScaffold(title: "Chip") {
            Toggle("Leading icon", isOn: $showsLeadingIcon)
            Toggle("Trailing icon", isOn: $showsTrailingIcon)
            Toggle("Enabled", isOn: $isEnabled)
        } preview: {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: StoreSpacing.s3) {
                    ForEach(Self.filters, id: \.self) { filter in
                        StoreFilterChip(filter,
                                        icon: showsLeadingIcon ? StoreIcon.BarsFilter.regular : nil,
                                        isSelected: selectedFilters.contains(filter),
                                        trailingIcon: showsTrailingIcon ? StoreIcon.AngleDown.regular : nil) {
                            toggle(filter)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .disabled(!isEnabled)
        }
    }

    private func toggle(_ filter: String) {
        if selectedFilters.contains(filter) {
            selectedFilters.remove(filter)
        } else {
            selectedFilters.insert(filter)
        }
    }
}

#Preview {
    NavigationStack {
        ChipComponentView()
    }
}

#Preview("Dark") {
    NavigationStack {
        ChipComponentView()
    }
    .preferredColorScheme(.dark)
}
#endif
