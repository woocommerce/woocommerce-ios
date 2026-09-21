#if DEBUG || ALPHA
import SwiftUI
import StoreDesignSystem

struct ButtonComponentView: View {
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
        ComponentDemoScaffold(title: "Button") {
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
        } preview: {
            StoreButton("Label",
                        icon: showsIcon ? StoreIcon.Star.regular : nil,
                        variant: style.variant,
                        size: size.value) {}
                .disabled(!isEnabled)
        }
    }
}

#Preview {
    NavigationStack {
        ButtonComponentView()
    }
}
#endif
