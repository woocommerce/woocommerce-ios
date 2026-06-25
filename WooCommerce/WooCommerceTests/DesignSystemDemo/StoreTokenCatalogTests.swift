#if DEBUG || ALPHA
import Foundation
import Testing
import SwiftUI
import StoreDesignSystem
@testable import WooCommerce

/// Guards the in-app Design System demo catalogs against silent drift: the catalogs are
/// hand/AI-maintained, so these tests assert each one enumerates exactly the tokens declared
/// in the `StoreDesignSystem` package. Adding a token to the package without updating the
/// matching catalog fails here.
struct StoreTokenCatalogTests {
    @Test func color_catalog_enumerates_every_palette_token() throws {
        let defined = try Self.declaredNames(in: "Color/Color+StoreColorPalette.swift",
                                             pattern: #"static let (\w+) = bundledColor"#)
        #expect(Set(Color.storeColorCatalog.map(\.name)) == defined)
    }

    @Test func icon_catalog_enumerates_every_icon_token() throws {
        let defined = try Self.declaredNames(in: "Icons/StoreIcon.swift",
                                             pattern: #"    public enum (\w+) \{"#)
        #expect(Set(StoreIcon.catalog.map(\.name)) == defined)
    }

    @Test func text_style_catalog_enumerates_every_preset() throws {
        let defined = try Self.declaredNames(in: "Typography/StoreTextStyle.swift",
                                             pattern: #"static let (\w+) = StoreTextStyle\("#)
        #expect(Set(StoreTextStyle.catalog.map(\.name)) == defined)
    }

    // MARK: - Helpers

    /// The names captured by `pattern` (group 1) in the given StoreDesignSystem source file.
    private static func declaredNames(in relativePath: String, pattern: String) throws -> Set<String> {
        // This file lives at <repo>/WooCommerce/WooCommerceTests/DesignSystemDemo/<file>.swift
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // DesignSystemDemo
            .deletingLastPathComponent() // WooCommerceTests
            .deletingLastPathComponent() // WooCommerce
            .deletingLastPathComponent() // repo root
        let source = try String(
            contentsOf: repoRoot
                .appendingPathComponent("StoreDesignSystem/Sources/StoreDesignSystem")
                .appendingPathComponent(relativePath),
            encoding: .utf8
        )
        let regex = try NSRegularExpression(pattern: pattern)
        let range = NSRange(source.startIndex..., in: source)
        var names: Set<String> = []
        regex.enumerateMatches(in: source, range: range) { match, _, _ in
            guard let match, let captured = Range(match.range(at: 1), in: source) else { return }
            names.insert(String(source[captured]))
        }
        return names
    }
}
#endif
