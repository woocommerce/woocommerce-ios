import SwiftUI
import Testing
@testable import StoreDesignSystem

@Suite struct StoreIconContainerToneTests {

    @Test func test_sandstone_tone_when_resolving_appearance_then_uses_adaptive_background_and_sandstone_foreground() {
        // Given / When the sandstone icon container tone resolves its appearance
        let sut = StoreIconContainerTone.sandstone.appearance

        // Then it uses the adaptive sandstone container role with the sandstone foreground
        #expect(sut.background == .storeIconContainerSandstone)
        #expect(sut.foreground == .storePaletteSandstone60)
    }
}
