#if DEBUG || ALPHA
import SwiftUI
import StoreDesignSystem

struct SegmentedControlComponentView: View {
    private enum SegmentCount: Int, CaseIterable, Identifiable {
        case two = 2
        case three = 3
        case four = 4
        case five = 5

        var id: Self { self }
        var title: String { "\(rawValue)" }
    }

    @State private var segmentCount: SegmentCount = .three
    @State private var selection = 0
    @State private var isEnabled = true

    var body: some View {
        ComponentDemoScaffold(title: "Segmented Control") {
            Picker("Segments", selection: $segmentCount) {
                ForEach(SegmentCount.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            Toggle("Enabled", isOn: $isEnabled)
        } preview: {
            StoreSegmentedControl(selection: $selection,
                                  options: Array(0..<segmentCount.rawValue)) { index in
                "Label \(index + 1)"
            }
            .disabled(!isEnabled)
            .padding(.horizontal)
            .onChange(of: segmentCount) { _, _ in
                selection = 0
            }
        }
    }
}

#Preview {
    NavigationStack {
        SegmentedControlComponentView()
    }
}
#endif
