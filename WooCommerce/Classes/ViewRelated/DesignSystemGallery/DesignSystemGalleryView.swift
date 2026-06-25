#if DEBUG
import SwiftUI
import UIKit
import StoreDesignSystem

/// Debug-only gallery for the StoreDesignSystem design tokens. Navigation is driven by
/// UIKit (plain `pushViewController` of hosted SwiftUI views) rather than SwiftUI
/// NavigationStack/NavigationLink: the Debug Panel lives inside a UIKit navigation
/// controller, where nested SwiftUI navigation corrupts the stack. This drills in:
/// master list (Tokens / Components) -> Tokens list (Colors / Typography / Icons) ->
/// token detail (configuration at the top).
enum DesignSystemGallery {
    static func push(onto navigationController: UINavigationController?) {
        let master = MasterView(
            onTokens: { [weak navigationController] in pushTokens(onto: navigationController) },
            onComponents: { [weak navigationController] in push(ComponentsView(), title: "Components", onto: navigationController) }
        )
        push(master, title: "Design System", onto: navigationController)
    }

    private static func pushTokens(onto navigationController: UINavigationController?) {
        let tokens = TokensListView(
            onColors: { [weak navigationController] in push(ColorTokensView(), title: "Colors", onto: navigationController) },
            onTypography: { [weak navigationController] in push(TypographyTokensView(), title: "Typography", onto: navigationController) },
            onIcons: { [weak navigationController] in push(IconTokensView(), title: "Icons", onto: navigationController) }
        )
        push(tokens, title: "Tokens", onto: navigationController)
    }

    private static func push<V: View>(_ view: V, title: String, onto navigationController: UINavigationController?) {
        let hostingController = UIHostingController(rootView: view)
        hostingController.title = title
        navigationController?.pushViewController(hostingController, animated: true)
    }
}

// MARK: - Navigation rows

private struct DesignSystemRow: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(Color.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

private struct MasterView: View {
    let onTokens: () -> Void
    let onComponents: () -> Void
    var body: some View {
        List {
            DesignSystemRow(title: "Tokens", action: onTokens)
            DesignSystemRow(title: "Components", action: onComponents)
        }
    }
}

private struct TokensListView: View {
    let onColors: () -> Void
    let onTypography: () -> Void
    let onIcons: () -> Void
    var body: some View {
        List {
            DesignSystemRow(title: "Colors", action: onColors)
            DesignSystemRow(title: "Typography", action: onTypography)
            DesignSystemRow(title: "Icons", action: onIcons)
        }
    }
}

private struct ComponentsView: View {
    var body: some View {
        List {
            Text("Coming soon")
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Shared

private func storeColor(named name: String) -> Color {
    StoreColorCatalog.all.first { $0.name == name }?.color ?? .primary
}

private struct TokenColorPicker: View {
    @Binding var selection: String
    var body: some View {
        Picker("Color", selection: $selection) {
            ForEach(StoreColorCatalog.all) { Text($0.name).tag($0.name) }
        }
        .pickerStyle(.menu)
    }
}

// MARK: - Colors

private struct ColorTokensView: View {
    var body: some View {
        List(StoreColorCatalog.all) { token in
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(token.color)
                    .frame(width: 44, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.3))
                    )
                Text(token.name)
                    .font(.system(.footnote, design: .monospaced))
            }
        }
    }
}

// MARK: - Typography

private struct TypographyTokensView: View {
    @State private var colorName = "storeTextPrimary"
    @State private var emphasis: Emphasis = .regular

    private enum Emphasis: String, CaseIterable, Identifiable {
        case regular, emphasized, strong
        var id: String { rawValue }
    }

    private func styled(_ base: StoreTextStyle) -> StoreTextStyle {
        switch emphasis {
        case .regular: return base
        case .emphasized: return base.emphasized
        case .strong: return base.strong
        }
    }

    var body: some View {
        List {
            Section("Configuration") {
                Picker("Emphasis", selection: $emphasis) {
                    ForEach(Emphasis.allCases) { Text($0.rawValue.capitalized).tag($0) }
                }
                .pickerStyle(.menu)
                TokenColorPicker(selection: $colorName)
            }
            Section("Styles") {
                ForEach(StoreTextStyleCatalog.all) { token in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(token.name)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("The quick brown fox")
                            .storeTextStyle(styled(token.style))
                            .foregroundStyle(storeColor(named: colorName))
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

// MARK: - Icons

private struct IconTokensView: View {
    @State private var style: IconStyle = .regular
    @State private var sizeName = "large"
    @State private var colorName = "storeTextPrimary"

    private enum IconStyle: String, CaseIterable, Identifiable {
        case light, regular, solid
        var id: String { rawValue }
    }

    private var size: CGFloat {
        StoreIconSizeCatalog.all.first { $0.name == sizeName }?.value ?? StoreIconSize.large
    }

    // Icons available in the selected style (styles are not universal across icons).
    private var icons: [StoreIconToken] {
        StoreIconCatalog.all.filter { token in
            token.variants.contains { $0.style == style.rawValue }
        }
    }

    var body: some View {
        List {
            Section("Configuration") {
                Picker("Style", selection: $style) {
                    ForEach(IconStyle.allCases) { Text($0.rawValue.capitalized).tag($0) }
                }
                .pickerStyle(.menu)
                Picker("Size", selection: $sizeName) {
                    ForEach(StoreIconSizeCatalog.all) { Text("\($0.name) (\(Int($0.value)))").tag($0.name) }
                }
                .pickerStyle(.menu)
                TokenColorPicker(selection: $colorName)
            }
            Section("Icons") {
                ForEach(icons) { token in
                    if let variant = token.variants.first(where: { $0.style == style.rawValue }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(token.name)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            variant.image
                                .image(size: size)
                                .foregroundStyle(storeColor(named: colorName))
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}
#endif
