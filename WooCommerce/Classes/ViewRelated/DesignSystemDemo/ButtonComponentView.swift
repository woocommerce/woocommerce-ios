#if DEBUG || ALPHA
import SwiftUI
import StoreDesignSystem

/// Interactive playground for `StoreButton` in the Design System demo: choose a style, size,
/// and toggles in the list; the configured button renders — and stays tappable — pinned below.
struct ButtonComponentView: View {
    // Demo-local enums mirror the `StoreButtonVariant` / `StoreButtonSize` presets so the pickers
    // bind to type-safe values instead of array indices. Add a case when a new preset is added.
    private enum Style: String, CaseIterable, Identifiable {
        case filled = "Filled"
        case tonal = "Tonal"
        case outlined = "Outlined"

        var id: Self { self }

        var variant: StoreButtonVariant {
            switch self {
            case .filled: .filled
            case .tonal: .tonal
            case .outlined: .outlined
            }
        }
    }

    private enum Size: String, CaseIterable, Identifiable {
        case small = "Small"
        case medium = "Medium"

        var id: Self { self }

        var value: StoreButtonSize {
            switch self {
            case .small: .small
            case .medium: .medium
            }
        }
    }

    @State private var style: Style = .filled
    @State private var size: Size = .small
    @State private var showsIcon = true
    @State private var isEnabled = true

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section("Configuration") {
                    Picker("Style", selection: $style) {
                        ForEach(Style.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    Picker("Size", selection: $size) {
                        ForEach(Size.allCases) { option in
                            Text(option.rawValue).tag(option)
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
                    variant: style.variant,
                    size: size.value) {}
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
