import Foundation
import Yosemite
import SwiftUI

final class WebhooksViewModel: ObservableObject {
    var siteID: Int64 = ServiceLocator.stores.sessionManager.defaultSite?.siteID ?? 0
    var credentials: Credentials = ServiceLocator.stores.sessionManager.defaultCredentials ?? .init(authToken: "")
    var service: WebhooksService

    @Published var webhooks: [Webhook] = []

    init() {
        service = WebhooksService(siteID: siteID, credentials: credentials)
    }

    @MainActor
    func listAllWebhooks() async throws {
        do {
            webhooks = try await service.listAllWebhooks()
        } catch {
            throw NSError(domain: error.localizedDescription, code: 0)
        }
    }

    func createWebhook() async throws {
        let webhook = try await service.createWebhook()
        debugPrint("🍍 \(webhook)")
    }
}
