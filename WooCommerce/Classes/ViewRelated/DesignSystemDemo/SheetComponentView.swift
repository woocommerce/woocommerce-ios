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
    @State private var showsCloseControl = false
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
            Toggle("Close control", isOn: $showsCloseControl)
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

    /// The design's "Date type" example: a header, radio rows and a footnote.
    @ViewBuilder private var sheetContent: some View {
        if showsCloseControl {
            StoreTopAppBar("Date type", navigation: .close { isPresented = false })
        } else {
            header
        }
        if isContentLong {
            longOptions
        } else {
            options
        }
        footnote
    }

    /// Fit-content sheets scroll long content themselves; with system detents the content scrolls itself.
    @ViewBuilder private var longOptions: some View {
        let stack = VStack(spacing: StoreSpacing.s0) {
            ForEach(0..<6) { _ in
                options
            }
        }
        if sizing == .fitContent {
            stack
        } else {
            ScrollView {
                stack
            }
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
