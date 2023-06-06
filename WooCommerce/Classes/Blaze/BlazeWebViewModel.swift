import Foundation
import WebKit
import Yosemite

enum BlazeSource {
    case menu
    case productMoreMenu
}

final class BlazeWebViewModel: AuthenticatedWebViewModel {
    let title = Localization.title

    // MARK: Private Variables

    private let source: BlazeSource
    private let site: Site
    private let productID: Int64?

    // MARK: Initializer

    init(source: BlazeSource,
         site: Site,
         productID: Int64?) {
        self.source = source
        self.site = site
        self.productID = productID
    }

    // MARK: Computed Variables

    var initialURL: URL? {
        let siteURL = site.url.trimHTTPScheme()
        let urlString: String = {
            if let productID {
                return String(format: Constants.blazePostURLFormat, siteURL, productID, source.analyticsValue)
            } else {
                return String(format: Constants.blazeSiteURLFormat, siteURL, source.analyticsValue)
            }
        }()
        return URL(string: urlString)
    }

    private var baseURLString: String {
        let siteURL = site.url.trimHTTPScheme()
        return String(format: Constants.baseURLFormat, siteURL)
    }

    // MARK: `AuthenticatedWebViewModel` conformance

    func decidePolicy(for navigationURL: URL) async -> WKNavigationActionPolicy {
        .allow
    }

    func handleDismissal() {

    }

    func handleRedirect(for url: URL?) {

    }
}

private extension BlazeSource {
    var analyticsValue: String {
        switch self {
        case .menu:
            return "menu"
        case .productMoreMenu:
            return "product_more_menu"
        }
    }
}

private extension BlazeWebViewModel {
    enum Constants {
        static let baseURLFormat = "https://wordpress.com/advertising/%@"
        static let blazeSiteURLFormat = "https://wordpress.com/advertising/%@?source=%@"
        static let blazePostURLFormat = "https://wordpress.com/advertising/%@?blazepress-widget=post-%d&source=%@"
    }

    enum Localization {
        static let title = NSLocalizedString("Blaze", comment: "Title of the Blaze view.")
    }
}
