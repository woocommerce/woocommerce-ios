import Foundation
import Yosemite

struct WebhookRowViewModel: Identifiable {
    var id = UUID()
    let webhook: Webhook

    init(webhook: Webhook) {
        self.webhook = webhook
    }
}
