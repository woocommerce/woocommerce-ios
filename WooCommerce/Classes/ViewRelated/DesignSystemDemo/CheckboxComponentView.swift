#if DEBUG || ALPHA
import SwiftUI
import StoreDesignSystem

struct CheckboxComponentView: View {
    private enum Tone: String, CaseIterable, Identifiable {
        case `default` = "Default"
        case error = "Error"

        var id: Self { self }

        var variant: StoreCheckboxVariant {
            switch self {
            case .default: .default
            case .error: .error
            }
        }
    }

    @State private var isOn = true
    @State private var isIndeterminate = false
    @State private var tone: Tone = .default
    @State private var isEnabled = true

    var body: some View {
        ComponentDemoScaffold(title: "Checkbox") {
            Toggle("Checked", isOn: $isOn)
            Toggle("Indeterminate", isOn: $isIndeterminate)
            Picker("Tone", selection: $tone) {
                ForEach(Tone.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            Toggle("Enabled", isOn: $isEnabled)
        } preview: {
            StoreCheckbox(isOn: $isOn,
                          isIndeterminate: isIndeterminate,
                          variant: tone.variant)
                .disabled(!isEnabled)
                .accessibilityLabel("Checkbox")
        }
    }
}

#Preview {
    NavigationStack {
        CheckboxComponentView()
    }
}
#endif
