import Testing
import UIKit
@testable import StoreDesignSystem

/// Color tokens are stringly-typed (`Color("name", bundle: .module)`), so a typo or a
/// renamed/missing asset fails silently to a default color at runtime. These tests fail
/// loudly instead: every generated token must map to a real asset, and the registry must
/// stay in sync with the asset catalog. This is what makes the generated layer trustworthy.
struct ColorResolutionTests {

    @Test func test_every_color_token_resolves_to_a_real_asset() {
        // Given the full set of generated color token names
        // When each is loaded from the module bundle
        // Then every one resolves to an actual color asset (non-nil)
        for name in StoreColorPalette.allAssetNames {
            let color = UIColor(named: name, in: .module, compatibleWith: nil)
            #expect(color != nil, "Missing color asset for token: \(name)")
        }
    }

    @Test func test_registry_matches_the_expected_token_count() {
        // The 36 semantic tokens exported from Figma (Status 18 + Surface 10 +
        // Background 4 + Outline 2 + Overlay 2). A mismatch means codegen drifted.
        #expect(StoreColorPalette.allAssetNames.count == 36)
    }

    @Test func test_token_names_are_unique() {
        // Duplicate names would mean two tokens collide onto one asset.
        let unique = Set(StoreColorPalette.allAssetNames)
        #expect(unique.count == StoreColorPalette.allAssetNames.count)
    }
}
