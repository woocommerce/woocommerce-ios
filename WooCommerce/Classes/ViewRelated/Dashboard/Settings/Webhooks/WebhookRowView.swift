import Foundation
import SwiftUI

struct WebhookRowView: View {
    private let viewModel: WebhookRowViewModel

    init(viewModel: WebhookRowViewModel) {
        self.viewModel = viewModel
    }

    var statusLabelColor: Color {
        switch viewModel.webhook.status {
        case "active":
            Color.green
        case "paused":
            Color.yellow
        case "disabled":
            Color.gray
        default:
            Color.white
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if let name = viewModel.webhook.name {
                    Text(name)
                }
                Spacer()
                Text(viewModel.webhook.status)
                    .background(statusLabelColor)
            }
            Text("Topic: \(viewModel.webhook.topic)")
                .font(.caption)
            Text("Delivery: \(viewModel.webhook.deliveryURL)")
                .font(.caption)
        }
        .padding(.vertical, 2)
        .padding(.horizontal)
    }
}
