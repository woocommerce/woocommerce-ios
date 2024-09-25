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

    private var formattedTopicSelectionText: String {
        String.localizedStringWithFormat(Localization.topicSelectionText,
                                         "Topic: ", viewModel.webhook.topic)
    }

    private var formattedDeliveryURLText: String {
        String.localizedStringWithFormat(Localization.deliveryURLText,
                                         "Delivery URL: ", viewModel.webhook.deliveryURL.absoluteString)
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if let name = viewModel.webhook.name {
                    Text(name)
                }
                Spacer()
                Text(viewModel.webhook.status.capitalized)
                    .font(.caption)
                    .padding(2)
                    .background(RoundedRectangle(cornerRadius: CGFloat(8)).fill(statusLabelColor))
                    .foregroundColor(.primary)
            }
            Text(formattedTopicSelectionText)
                .font(.caption)
            Text(formattedDeliveryURLText)
                .font(.caption)
        }
        .padding(.vertical, 2)
        .padding(.horizontal)
    }
}

private extension WebhookRowView {
    enum Localization {
        static let topicSelectionText =
        NSLocalizedString("settings.webhookRowView.topicSelectionText",
                          value: "%1$@ %2$@",
                          comment: "Hint shown to the merchant to choose one of different webhook options"
                          + "Reads as: 'Topic: {selection}'")
        static let deliveryURLText =
        NSLocalizedString("settings.webhookRowView.deliveryURLText",
                          value: "%1$@ %2$@",
                          comment: "Hint shown to the merchant to type a delivery URL for a webhook"
                          + "Reads as: 'Delivery URL: {URL}'")
    }
}
