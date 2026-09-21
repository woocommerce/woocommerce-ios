#if DEBUG || ALPHA
import SwiftUI
import StoreDesignSystem

struct DividerComponentView: View {
    private enum Variant: String, CaseIterable, Identifiable {
        case full = "Full"
        case inset = "Inset"

        var id: Self { self }

        var value: StoreDividerVariant {
            switch self {
            case .full: .full
            case .inset: .inset
            }
        }
    }

    @State private var variant: Variant = .full

    private let rowCount = 4

    var body: some View {
        ComponentDemoScaffold(title: "Divider", previewHeight: 280) {
            Picker("Variant", selection: $variant) {
                ForEach(Variant.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
        } preview: {
            VStack(spacing: 0) {
                ForEach(1...rowCount, id: \.self) { index in
                    row("Cell \(index)")
                    if index < rowCount {
                        StoreDivider(variant: variant.value)
                    }
                }
            }
        }
    }

    private func row(_ title: String) -> some View {
        Text(title)
            .storeTextStyle(.bodyMedium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(StorePadding.p7)
    }
}

#Preview {
    NavigationStack {
        DividerComponentView()
    }
}
#endif
