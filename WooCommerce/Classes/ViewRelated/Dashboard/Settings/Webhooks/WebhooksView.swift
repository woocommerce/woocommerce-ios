import SwiftUI
import Networking

final class WebhooksService: ObservableObject {
    let credentials = ServiceLocator.stores.sessionManager.defaultCredentials
    let siteID = ServiceLocator.stores.sessionManager.defaultSite?.siteID
    var remote: WebhooksRemote

    var webhooks: [Webhook] = []

    init() {
        self.remote = WebhooksRemote(network: AlamofireNetwork(credentials: credentials))
    }

    @MainActor
    func listAllWebhooks() async {
        guard let siteID = ServiceLocator.stores.sessionManager.defaultSite?.siteID else {
            debugPrint("🍍 Couldn't retrieve site ID")
            return
        }
        Task {
            webhooks = try await remote.listAllWebhooks(for: siteID)
            debugPrint("🍍 Webhooks: \(webhooks)")
        }
    }
}

struct WebhooksView: View {
    @ObservedObject private var service = WebhooksService()

    var body: some View {
        VStack {
            Text("Webhooks")
            Text("(Check the console!)")
                .font(.caption)
        }
        .task {
            await service.listAllWebhooks()
        }
    }
}

#Preview {
    WebhooksView()
}
