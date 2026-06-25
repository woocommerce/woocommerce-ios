#if DEBUG
import SwiftUI
import StoreDesignSystem

/// Debug-only gallery for the StoreDesignSystem design tokens, reachable from the Debug
/// Panel. Lets you browse and play with colors, typography and icons live in a real
/// (debug / PR / installable) build. Compiled only in Debug, where the package's
/// `#if DEBUG` token catalogs exist.
struct DesignSystemGalleryView: View {
    /// Called by the "Done" button. Defaults to a no-op so the view is still usable in previews.
    var onDismiss: () -> Void = {}

    var body: some View {
        // Self-contained NavigationStack: the Debug Panel is hosted in a UIKit
        // navigation controller (no SwiftUI navigation), so nested NavigationLinks need
        // their own stack to route correctly.
        NavigationStack {
            List {
                Section("Tokens") {
                    NavigationLink("Colors") { ColorTokensView() }
                    NavigationLink("Typography") { TypographyTokensView() }
                    NavigationLink("Icons") { IconTokensView() }
                }
                Section("Components") {
                    Text("Coming soon")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Design System")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onDismiss)
                }
            }
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
        .navigationTitle("Colors")
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
            Section {
                Picker("Emphasis", selection: $emphasis) {
                    ForEach(Emphasis.allCases) { Text($0.rawValue.capitalized).tag($0) }
                }
                TokenColorPicker(selection: $colorName)
            }
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
        .navigationTitle("Typography")
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
            Section {
                Picker("Style", selection: $style) {
                    ForEach(IconStyle.allCases) { Text($0.rawValue.capitalized).tag($0) }
                }
                Picker("Size", selection: $sizeName) {
                    ForEach(StoreIconSizeCatalog.all) { Text("\($0.name) (\(Int($0.value)))").tag($0.name) }
                }
                TokenColorPicker(selection: $colorName)
            }
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
        .navigationTitle("Icons")
    }
}
#endif
