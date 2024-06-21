import Foundation
import WebKit

final class GoogleAdsWebViewModel: AuthenticatedWebViewModel {

    let title = "Google Ads"
    let initialURL: URL?

    private let onCampaignCreated: (() -> Void)?

    init(siteURL: String,
         onCampaignCreated: (() -> Void)? = nil) {
        self.onCampaignCreated = onCampaignCreated
        self.initialURL = {
            let urlString: String = {
                return siteURL + "/wp-admin/admin.php?page=wc-admin&path=%2Fgoogle%2Fdashboard&subpath=%2Fcampaigns%2Fcreate"
            }()
            return URL(string: urlString)
        }()
    }

    func handleDismissal() {
        // TODO
    }

    func handleRedirect(for url: URL?) {
        guard let url else {
            return
        }
        DDLogDebug("🧭" + url.absoluteString)
    }

    func decidePolicy(for navigationURL: URL) async -> WKNavigationActionPolicy {
        .allow
    }
}
