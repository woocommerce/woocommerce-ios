#if DEBUG || ALPHA
import SwiftUI
import StoreDesignSystem

/// Interactive playground for `StoreButton` in the Design System demo: choose a style, size,
/// and toggles in the list; the configured button renders — and stays tappable — pinned below.
struct ButtonComponentView: View {
    // Hand-maintained because the preset types aren't `CaseIterable`. Keep in sync with the
    // `static let`s on `StoreButtonVariant` / `StoreButtonSize`.
    private let variants: [(name: String, variant: StoreButtonVariant)] = [
        ("Filled", .filled),
        ("Tonal", .tonal),
        ("Outlined", .outlined)
    ]
    private let sizes: [(name: String, size: StoreButtonSize)] = [
        ("Small", .small),
        ("Medium", .medium)
    ]

    @State private var variantIndex = 0
    @State private var sizeIndex = 0
    @State private var showsIcon = true
    @State private var isEnabled = true

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section("Configuration") {
                    Picker("Style", selection: $variantIndex) {
                        ForEach(variants.indices, id: \.self) { index in
                            Text(variants[index].name).tag(index)
                        }
                    }
                    Picker("Size", selection: $sizeIndex) {
                        ForEach(sizes.indices, id: \.self) { index in
                            Text(sizes[index].name).tag(index)
                        }
                    }
                    Toggle("Icon", isOn: $showsIcon)
                    Toggle("Enabled", isOn: $isEnabled)
                }
                .listRowBackground(Color.storeSurface)
            }
            .scrollContentBackground(.hidden)
            .background(Color.storeSectionBackground)

            preview
        }
        .navigationTitle("Button")
    }

    // A fixed-height panel below the list. Kept outside the `List` so the button gets normal
    // gesture handling — inside a list row the scroll-disambiguation touch delay swallows the
    // press animation.
    private var preview: some View {
        StoreButton("Label",
                    icon: showsIcon ? StoreIcon.Plus.regular : nil,
                    variant: variants[variantIndex].variant,
                    size: sizes[sizeIndex].size) {}
            .disabled(!isEnabled)
            .frame(maxWidth: .infinity)
            .frame(height: Constants.previewHeight)
            .background(.storeSurface)
            .overlay(alignment: .top) {
                Divider()
            }
    }
}

private extension ButtonComponentView {
    enum Constants {
        static let previewHeight: CGFloat = 180
    }
}

#Preview {
    NavigationStack {
        ButtonComponentView()
    }
}
#endif
