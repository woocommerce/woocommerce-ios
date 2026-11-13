#if DEBUG || ALPHA
import SwiftUI
import StoreDesignSystem

struct BadgeComponentView: View {
    private enum Tone: String, CaseIterable, Identifiable {
        case error = "Error"
        case caution = "Caution"
        case warning = "Warning"
        case success = "Success"
        case info = "Info"
        case neutral = "Neutral"
        case neutralOutlined = "Outlined"

        var id: Self { self }

        var value: StoreBadgeTone {
            switch self {
            case .error: .error
            case .caution: .caution
            case .warning: .warning
            case .success: .success
            case .info: .info
            case .neutral: .neutral
            case .neutralOutlined: .neutralOutlined
            }
        }
    }

    @State private var tone: Tone = .neutral
    @State private var showsIcon = true
    @State private var label = "Label"

    var body: some View {
        ComponentDemoScaffold(title: "Badge") {
            Picker("Tone", selection: $tone) {
                ForEach(Tone.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            Toggle("Icon", isOn: $showsIcon)
            TextField("Label", text: $label)
        } preview: {
            StoreBadge(label,
                       icon: showsIcon ? StoreIcon.Star.regular : nil,
                       tone: tone.value)
        }
    }
}

#Preview {
    NavigationStack {
        BadgeComponentView()
    }
}
#endif
