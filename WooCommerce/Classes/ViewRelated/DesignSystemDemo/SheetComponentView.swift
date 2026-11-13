#if DEBUG || ALPHA
import SwiftUI
import StoreDesignSystem

struct SheetComponentView: View {
    private enum Sizing: String, CaseIterable, Identifiable {
        case fitContent = "Fit content"
        case mediumAndLarge = "Medium + large"

        var id: Self { self }

        var value: StoreSheetSizing {
            switch self {
            case .fitContent: .fitContent
            case .mediumAndLarge: .detents([.medium, .large])
            }
        }
    }

    private enum DateType: String, CaseIterable, Identifiable {
        case placed = "Placed orders"
        case paid = "Paid orders"
        case completed = "Completed orders"

        var id: Self { self }

        var description: String {
            switch self {
            case .placed: "Count orders by date placed or created."
            case .paid: "Count orders by payment date."
            case .completed: "Count orders when they were marked complete."
            }
        }
    }

    @State private var sizing: Sizing = .fitContent
    @State private var isContentLong = false
    @State private var isPresented = false
    @State private var dateType: DateType = .placed

    var body: some View {
        ComponentDemoScaffold(title: "Sheet") {
            Picker("Sizing", selection: $sizing) {
                ForEach(Sizing.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            Toggle("Long content", isOn: $isContentLong)
        } preview: {
            StoreButton("Show sheet") {
                isPresented = true
            }
            .storeSheet(isPresented: $isPresented, sizing: sizing.value) {
                sheetContent
            }
        }
    }

    /// `.fitContent` measures and scrolls the content itself; system detents leave scrolling to the caller.
    @ViewBuilder private var sheetContent: some View {
        if sizing == .fitContent {
            sheetBody
        } else {
            ScrollView {
                sheetBody
            }
        }
    }

    private var sheetBody: some View {
        VStack(spacing: StoreSpacing.s0) {
            header
            ForEach(0..<(isContentLong ? 6 : 1), id: \.self) { _ in
                options
            }
            footnote
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: StoreSpacing.s3) {
            Text("Date type")
                .storeTextStyle(.titleLarge.strong)
                .foregroundStyle(Color.storeOnSurface)
            Text("Choose which orders to include in your performance metrics for the selected time range.")
                .storeTextStyle(.bodyLarge)
                .foregroundStyle(Color.storeOnSurfaceVariant)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, StorePadding.p7)
        .padding(.vertical, StorePadding.p5)
    }

    private var options: some View {
        StoreRadioGroup(selection: $dateType, options: DateType.allCases, rowSpacing: StoreSpacing.s0) { option in
            VStack(alignment: .leading, spacing: StoreSpacing.s1) {
                Text(option.rawValue)
                    .storeTextStyle(.bodyLarge.emphasized)
                    .foregroundStyle(Color.storeOnSurface)
                Text(option.description)
                    .storeTextStyle(.bodyMedium)
                    .foregroundStyle(Color.storeOnSurfaceVariant)
            }
            .padding(.vertical, StorePadding.p5)
        }
        .padding(.horizontal, StorePadding.p7)
    }

    private var footnote: some View {
        Text("This is a store-wide setting, which also controls the “Date type” option in WooCommerce analytics settings.")
            .storeTextStyle(.bodySmall)
            .foregroundStyle(Color.storeOnSurfaceVariantLowest)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, StorePadding.p7)
            .padding(.vertical, StorePadding.p5)
    }
}

#Preview {
    NavigationStack {
        SheetComponentView()
    }
}

#Preview("Dark") {
    NavigationStack {
        SheetComponentView()
    }
    .preferredColorScheme(.dark)
}
#endif
