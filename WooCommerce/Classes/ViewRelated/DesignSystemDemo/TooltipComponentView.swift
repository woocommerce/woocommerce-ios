#if DEBUG || ALPHA
import SwiftUI
import StoreDesignSystem

struct TooltipComponentView: View {
    private enum Mode: String, CaseIterable, Identifiable {
        case manual = "Manual"
        case automatic = "Automatic"

        var id: Self { self }
    }

    private enum Placement: String, CaseIterable, Identifiable {
        case above = "Above"
        case below = "Below"
        case leading = "Leading"
        case trailing = "Trailing"

        var id: Self { self }

        var value: StoreTooltipPlacement {
            switch self {
            case .above: .above
            case .below: .below
            case .leading: .leading
            case .trailing: .trailing
            }
        }
    }

    @State private var mode: Mode = .manual
    @State private var placement: Placement = .below
    @State private var showsMessage = true
    @State private var manualPresented = false
    @State private var automaticPresented: Int?
    @State private var navbarPresented = false
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var message: String? {
        showsMessage ? "Supporting line text lorem ipsum dolor sit amet, consectetur" : nil
    }

    // Keep the preview within a short (landscape) screen; give it room to spread when tall.
    private var previewHeight: CGFloat {
        if verticalSizeClass == .compact {
            return 220
        }
        return mode == .automatic ? 560 : 360
    }

    var body: some View {
        ComponentDemoScaffold(title: "Tooltip", previewHeight: previewHeight) {
            Picker("Mode", selection: $mode) {
                ForEach(Mode.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: mode) { _, _ in
                manualPresented = false
                automaticPresented = nil
            }
            if mode != .automatic {
                Picker("Preferred placement", selection: $placement) {
                    ForEach(Placement.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .onChange(of: placement) { _, _ in manualPresented = false }
            }
            Toggle("Supporting text", isOn: $showsMessage)
        } preview: {
            switch mode {
            case .manual: manualPreview
            case .automatic: automaticPreview
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    navbarPresented.toggle()
                } label: {
                    Image(systemName: "info.circle")
                }
                // No preferred placement: the presenter auto-picks a side that keeps the bubble
                // on screen — important for a nav-bar button sitting in a screen corner.
                .storeTooltip(isPresented: $navbarPresented,
                              title: "Title",
                              message: message)
            }
        }
    }

    private var manualPreview: some View {
        anchor
            .onTapGesture { manualPresented = true }
            .storeTooltip(isPresented: $manualPresented,
                          preferredPlacement: placement.value,
                          title: "Title",
                          message: message)
    }

    private var automaticPreview: some View {
        VStack(spacing: 0) {
            ForEach(0..<3) { row in
                HStack(spacing: 0) {
                    ForEach(0..<3) { column in
                        let index = row * 3 + column
                        anchor
                            .onTapGesture { automaticPresented = index }
                            .storeTooltip(isPresented: binding(for: index),
                                          title: "Title",
                                          message: message)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
    }

    private var anchor: some View {
        Image(systemName: "info.circle.fill")
            .font(.largeTitle)
            .foregroundStyle(.tint)
    }

    private func binding(for index: Int) -> Binding<Bool> {
        Binding(get: { automaticPresented == index },
                set: { automaticPresented = $0 ? index : nil })
    }
}

#Preview {
    NavigationStack {
        TooltipComponentView()
    }
}
#endif
