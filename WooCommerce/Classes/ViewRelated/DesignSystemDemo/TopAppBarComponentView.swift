#if DEBUG || ALPHA
import SwiftUI
import StoreDesignSystem

struct TopAppBarComponentView: View {
    private enum Size: String, CaseIterable, Identifiable {
        case small = "Small"
        case medium = "Medium"

        var id: Self { self }

        var value: StoreTopAppBarSize {
            switch self {
            case .small: .small
            case .medium: .medium
            }
        }
    }

    private enum Alignment: String, CaseIterable, Identifiable {
        case leading = "Leading"
        case center = "Center"

        var id: Self { self }

        var value: StoreTopAppBarTitleAlignment {
            switch self {
            case .leading: .leading
            case .center: .center
            }
        }
    }

    private enum Navigation: String, CaseIterable, Identifiable {
        case none = "None"
        case back = "Back"
        case close = "Close"

        var id: Self { self }

        var value: StoreTopAppBarNavigation? {
            switch self {
            case .none: nil
            case .back: .back {}
            case .close: .close {}
            }
        }
    }

    @State private var size: Size = .small
    @State private var alignment: Alignment = .leading
    @State private var navigation: Navigation = .back
    @State private var actionCount = 1
    @State private var showsSupportingText = false
    @State private var dividerFollowsScroll = true
    @State private var isEnabled = true
    @State private var isContentScrolled = false

    var body: some View {
        ComponentDemoScaffold(title: "Top App Bar", previewHeight: 320) {
            Picker("Size", selection: $size) {
                ForEach(Size.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            Picker("Alignment", selection: $alignment) {
                ForEach(Alignment.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            Picker("Navigation", selection: $navigation) {
                ForEach(Navigation.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            Stepper("Actions: \(actionCount)", value: $actionCount, in: 0...3)
            Toggle("Supporting text", isOn: $showsSupportingText)
            Toggle("Divider on scroll", isOn: $dividerFollowsScroll)
            Toggle("Enabled", isOn: $isEnabled)
        } preview: {
            VStack(spacing: 0) {
                StoreTopAppBar("Orders",
                               supportingText: showsSupportingText ? "Supporting text" : nil,
                               size: size.value,
                               alignment: alignment.value,
                               navigation: navigation.value,
                               actions: Array(actions.prefix(actionCount)),
                               showsDivider: dividerFollowsScroll && isContentScrolled)
                    .disabled(!isEnabled)
                scrollingContent
            }
        }
    }

    private var actions: [StoreTopAppBarAction] {
        [
            StoreTopAppBarAction(StoreIcon.MagnifyingGlass.regular, accessibilityLabel: "Search") {},
            StoreTopAppBarAction(StoreIcon.Gear.regular, accessibilityLabel: "Settings") {},
            StoreTopAppBarAction(StoreIcon.Ellipsis.regular, accessibilityLabel: "More") {}
        ]
    }

    /// Stands in for a screen's content: scrolling it under the bar is what shows the divider.
    private var scrollingContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(0..<12) { index in
                    StoreCell("Order #\(1000 + index)", description: "Processing")
                    StoreDivider(variant: .inset)
                }
            }
        }
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y > 0
        } action: { _, isScrolled in
            isContentScrolled = isScrolled
        }
        .background(Color.storeSectionBackground)
    }
}

#Preview {
    NavigationStack {
        TopAppBarComponentView()
    }
}

#Preview("RTL") {
    NavigationStack {
        TopAppBarComponentView()
    }
    .environment(\.layoutDirection, .rightToLeft)
}
#endif
