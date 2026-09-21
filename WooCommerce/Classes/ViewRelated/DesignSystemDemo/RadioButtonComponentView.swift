#if DEBUG || ALPHA
import SwiftUI
import StoreDesignSystem

struct RadioButtonComponentView: View {
    private enum Option: String, CaseIterable, Identifiable {
        case standard = "Standard shipping"
        case express = "Express shipping"
        case pickup = "Local pickup"

        var id: Self { self }

        var subtitle: String {
            switch self {
            case .standard: "3–5 business days"
            case .express: "1–2 business days"
            case .pickup: "Ready today"
            }
        }
    }

    @State private var selection: Option = .standard
    @State private var isEnabled = true
    @State private var showDescription = true

    var body: some View {
        ComponentDemoScaffold(title: "RadioButton", previewHeight: 240) {
            Toggle("Enabled", isOn: $isEnabled)
            Toggle("Show description", isOn: $showDescription)
        } preview: {
            StoreRadioGroup(selection: $selection,
                            options: Option.allCases) { option in
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.rawValue)
                    if showDescription {
                        Text(option.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .disabled(!isEnabled)
            .padding(.horizontal)
        }
    }
}

#Preview {
    NavigationStack {
        RadioButtonComponentView()
    }
}
#endif
