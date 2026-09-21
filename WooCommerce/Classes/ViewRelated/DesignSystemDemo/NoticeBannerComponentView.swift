#if DEBUG || ALPHA
import SwiftUI
import StoreDesignSystem

struct NoticeBannerComponentView: View {
    private enum Tone: String, CaseIterable, Identifiable {
        case error = "Error"
        case caution = "Caution"
        case warning = "Warning"
        case success = "Success"
        case info = "Info"
        case neutral = "Neutral"
        case neutralOutlined = "Neutral Outlined"

        var id: Self { self }

        var value: StoreNoticeBannerTone {
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

    @State private var tone: Tone = .error
    @State private var title = "Orders synced"
    @State private var description = "New order data is available."
    @State private var showsIcon = true
    @State private var showsDescription = true

    var body: some View {
        ComponentDemoScaffold(title: "NoticeBanner") {
            Picker("Tone", selection: $tone) {
                ForEach(Tone.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            Toggle("Icon", isOn: $showsIcon)
            Toggle("Description", isOn: $showsDescription)
            TextField("Title", text: $title)
            TextField("Description", text: $description)
        } preview: {
            StoreNoticeBanner(title,
                              description: showsDescription ? description : nil,
                              tone: tone.value,
                              icon: showsIcon ? StoreIcon.CircleInfo.regular : nil)
                .padding()
        }
    }
}

#Preview {
    NavigationStack {
        NoticeBannerComponentView()
    }
}
#endif
