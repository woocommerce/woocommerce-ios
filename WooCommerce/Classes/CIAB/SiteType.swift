import Yosemite

/// Represents the type of a WooCommerce site.
///
/// Used by the composition root (`SiteFeatureFactory`) to determine which
/// feature providers to assemble. Adding a new site type means adding a case
/// here and a branch in each factory `switch` — the compiler enforces exhaustiveness.
///
enum SiteType {
    case standard
    case ciab

    init(site: Site) {
        if Site.isCIAB(isGarden: site.isGarden, gardenName: site.gardenName) {
            self = .ciab
        } else {
            self = .standard
        }
    }
}
