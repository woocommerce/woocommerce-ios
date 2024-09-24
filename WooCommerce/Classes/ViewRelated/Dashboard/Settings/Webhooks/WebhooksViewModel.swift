import Foundation
import Yosemite
import SwiftUI

final class WebhooksViewModel: ObservableObject {
    var siteID: Int64 = ServiceLocator.stores.sessionManager.defaultSite?.siteID ?? 0
    var credentials: Credentials = ServiceLocator.stores.sessionManager.defaultCredentials ?? .init(authToken: "")
    var service: WebhooksService

    var webhooks: [Webhook] = []

    init() {
        service = WebhooksService(siteID: siteID, credentials: credentials)
    }

    @MainActor
    func listAllWebhooks() async {
        do {
            webhooks = try await service.listAllWebhooks()
            debugPrint("🍍 Webhooks: \(webhooks)")
        } catch {
            // TODO-gm: Modal with error
            debugPrint(error)
        }
    }
}
