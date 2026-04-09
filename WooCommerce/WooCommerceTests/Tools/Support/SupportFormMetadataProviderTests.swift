import Testing
import Yosemite
@testable import WooCommerce

@MainActor
struct SupportFormMetadataProviderTests {

    // MARK: - CIAB Tag

    @Test
    func systemTags_when_site_is_CIAB_then_includes_commerce_in_a_box_tag() {
        // Given
        let sessionManager = SessionManager.makeForTesting(
            authenticated: true,
            defaultSite: Site.fake().copy(isGarden: true, gardenName: "commerce")
        )
        let stores = MockStoresManager(sessionManager: sessionManager)
        let provider = SupportFormMetadataProvider(
            stores: stores,
            sessionManager: sessionManager
        )

        // When
        let tags = provider.systemTags()

        // Then
        #expect(tags.contains("commerce_in_a_box"))
    }

    @Test
    func systemTags_when_site_is_not_CIAB_then_does_not_include_commerce_in_a_box_tag() {
        // Given
        let sessionManager = SessionManager.makeForTesting(
            authenticated: true,
            defaultSite: Site.fake().copy(isGarden: false)
        )
        let stores = MockStoresManager(sessionManager: sessionManager)
        let provider = SupportFormMetadataProvider(
            stores: stores,
            sessionManager: sessionManager
        )

        // When
        let tags = provider.systemTags()

        // Then
        #expect(!tags.contains("commerce_in_a_box"))
    }

    @Test
    func systemTags_when_site_is_garden_but_not_commerce_then_does_not_include_commerce_in_a_box_tag() {
        // Given
        let sessionManager = SessionManager.makeForTesting(
            authenticated: true,
            defaultSite: Site.fake().copy(isGarden: true, gardenName: "not-commerce")
        )
        let stores = MockStoresManager(sessionManager: sessionManager)
        let provider = SupportFormMetadataProvider(
            stores: stores,
            sessionManager: sessionManager
        )

        // When
        let tags = provider.systemTags()

        // Then
        #expect(!tags.contains("commerce_in_a_box"))
    }

    @Test
    func systemTags_when_no_default_site_then_does_not_include_commerce_in_a_box_tag() {
        // Given
        let sessionManager = SessionManager.makeForTesting(authenticated: true)
        let stores = MockStoresManager(sessionManager: sessionManager)
        let provider = SupportFormMetadataProvider(
            stores: stores,
            sessionManager: sessionManager
        )

        // When
        let tags = provider.systemTags()

        // Then
        #expect(!tags.contains("commerce_in_a_box"))
    }
}
