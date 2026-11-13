#if DEBUG || ALPHA
import SwiftUI
import StoreDesignSystem

struct SearchFieldComponentView: View {
    private static let orders = ["Alice Johnson", "Bob Martin", "Carla Reyes", "Dmitri Volkov", "Erin Walsh", "Farid Haddad"]

    @State private var query = ""
    @State private var showsTrailingAction = true
    @State private var isTrailingActionEnabled = true
    @State private var isEnabled = true
    @FocusState private var isFocused: Bool

    var body: some View {
        ComponentDemoScaffold(title: "Search Field", previewHeight: 320) {
            Toggle("Trailing action", isOn: $showsTrailingAction)
            Toggle("Trailing action enabled", isOn: $isTrailingActionEnabled)
            Toggle("Enabled", isOn: $isEnabled)
        } preview: {
            VStack(spacing: StoreSpacing.s0) {
                StoreSearchField(text: $query, placeholder: "Search orders", trailingAction: trailingAction)
                    .focused($isFocused)
                    .autocorrectionDisabled()
                    .onSubmit { isFocused = false }
                    .disabled(!isEnabled)
                StoreDivider()
                results
            }
        }
    }

    private var trailingAction: StoreSearchFieldAction? {
        guard showsTrailingAction else {
            return nil
        }
        return StoreSearchFieldAction("Cancel", isEnabled: isTrailingActionEnabled) {
            query = ""
            isFocused = false
        }
    }

    /// The host owns the results: the design system stops at the field.
    private var results: some View {
        ScrollView {
            LazyVStack(spacing: StoreSpacing.s0) {
                ForEach(filteredOrders, id: \.self) { order in
                    StoreCell(order)
                }
            }
        }
        .scrollDismissesKeyboard(.immediately)
    }

    private var filteredOrders: [String] {
        guard query.isEmpty == false else {
            return Self.orders
        }
        return Self.orders.filter { $0.localizedCaseInsensitiveContains(query) }
    }
}

#Preview {
    NavigationStack {
        SearchFieldComponentView()
    }
}

#Preview("Dark") {
    NavigationStack {
        SearchFieldComponentView()
    }
    .preferredColorScheme(.dark)
}
#endif
