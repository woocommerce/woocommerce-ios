#if DEBUG || ALPHA
import SwiftUI
import StoreDesignSystem

/// In-app demo for the StoreDesignSystem design tokens. Pure SwiftUI: it lives inside the
/// Debug Panel's `NavigationStack` (the Debug Panel is presented as a full-screen SwiftUI
/// modal, so there's no UIKit navigation controller to fight with). Drill-in: master list
/// (Tokens / Components) -> Tokens list (Colors / Typography / Icons) -> token detail.
struct DesignSystemDemoView: View {
    var body: some View {
        List {
            NavigationLink("Tokens") { TokenCategoriesView() }
            NavigationLink("Components") { ComponentsView() }
        }
        .navigationTitle("Design System")
    }
}

private struct TokenCategoriesView: View {
    var body: some View {
        List {
            NavigationLink("Colors") { ColorTokensView() }
            NavigationLink("Typography") { TypographyTokensView() }
            NavigationLink("Icons") { IconTokensView() }
        }
        .navigationTitle("Tokens")
    }
}

private struct ComponentsView: View {
    var body: some View {
        List {
            NavigationLink("Badge") { BadgeComponentView() }
            NavigationLink("Button") { ButtonComponentView() }
            NavigationLink("Checkbox") { CheckboxComponentView() }
            NavigationLink("NoticeBanner") { NoticeBannerComponentView() }
            NavigationLink("RadioButton") { RadioButtonComponentView() }
            NavigationLink("Segmented Control") { SegmentedControlComponentView() }
            NavigationLink("Tooltip") { TooltipComponentView() }
        }
        .navigationTitle("Components")
    }
}
#endif
