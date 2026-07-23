#if DEBUG || ALPHA
import SwiftUI
import StoreDesignSystem

struct IconContainerComponentView: View {
    private enum Tone: String, CaseIterable, Identifiable {
        case purple = "Purple"
        case sandstone = "Sandstone"
        case blue = "Blue"
        case green = "Green"
        case orange = "Orange"
        case pink = "Pink"
        case darkPurple = "Dark Purple"

        var id: Self { self }

        var value: StoreIconContainerTone {
            switch self {
            case .purple: .purple
            case .sandstone: .sandstone
            case .blue: .blue
            case .green: .green
            case .orange: .orange
            case .pink: .pink
            case .darkPurple: .darkPurple
            }
        }
    }

    @State private var tone: Tone = .purple

    var body: some View {
        ComponentDemoScaffold(title: "Icon Container") {
            Picker("Tone", selection: $tone) {
                ForEach(Tone.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
        } preview: {
            StoreIconContainer(StoreIcon.Star.regular, tone: tone.value)
        }
    }
}

#Preview {
    NavigationStack {
        IconContainerComponentView()
    }
}

#Preview("RTL") {
    NavigationStack {
        IconContainerComponentView()
    }
    .environment(\.layoutDirection, .rightToLeft)
}
#endif
