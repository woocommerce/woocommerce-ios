import Testing
@testable import WooCommerce
import Yosemite

struct SiteTypeTests {

    @Test func init_when_standard_site_then_returns_standard() {
        // Given
        let site = Site.fake().copy(isGarden: false)

        // When
        let siteType = SiteType(site: site)

        // Then
        #expect(siteType == .standard)
    }

    @Test func init_when_garden_site_with_non_commerce_name_then_returns_standard() {
        // Given
        let site = Site.fake().copy(isGarden: true, gardenName: "not-commerce")

        // When
        let siteType = SiteType(site: site)

        // Then
        #expect(siteType == .standard)
    }

    @Test func init_when_ciab_site_then_returns_ciab() {
        // Given
        let site = Site.fake().copy(isGarden: true, gardenName: "commerce")

        // When
        let siteType = SiteType(site: site)

        // Then
        #expect(siteType == .ciab)
    }
}
