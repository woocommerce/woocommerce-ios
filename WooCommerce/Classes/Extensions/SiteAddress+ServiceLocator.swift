import class Yosemite.SiteAddress

extension SiteAddress {
    convenience init() {
        self.init(siteSettings: ServiceLocator.selectedSiteSettings.siteSettings)
    }
}
