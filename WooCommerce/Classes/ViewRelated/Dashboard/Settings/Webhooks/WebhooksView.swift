import SwiftUI
import Yosemite

struct WebhookRowViewModel: Identifiable {
    var id = UUID()
    let webhook: Webhook

    init(webhook: Webhook) {
        self.webhook = webhook
    }
}

struct WebhookRowView: View {
    private let viewModel: WebhookRowViewModel

    init(viewModel: WebhookRowViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if let name = viewModel.webhook.name {
                    Text(name)
                }
                Spacer()
                // TODO-gm: Forgot to model wh status!
                Text("Active")
                    .background(Color.green)
            }
            Text("Topic: \(viewModel.webhook.topic)")
                .font(.caption)
            Text("Delivery: \(viewModel.webhook.deliveryURL)")
                .font(.caption)
        }
        .padding(.vertical, 2)
        .padding(.horizontal)
        Divider()
    }
}

enum WebhooksViewState: String, CaseIterable, Identifiable {
    case listAll = "List all Webhooks"
    case createNew = "Create new Webhook"

    // Identifiable conformance
    var id: String { self.rawValue }
}

struct WebhooksView: View {
    @ObservedObject private var viewModel: WebhooksViewModel
    @State private var viewState: WebhooksViewState = .listAll

    init(viewModel: WebhooksViewModel) {
        self.viewModel = viewModel
    }

    var rowViewModels: [WebhookRowViewModel] {
        viewModel.webhooks.map {
            WebhookRowViewModel(webhook: $0)
        }
    }

    var body: some View {
        VStack {
            Picker("", selection: $viewState) {
                ForEach(WebhooksViewState.allCases) { viewState in
                    Text(viewState.rawValue)
                        .tag(viewState)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            switch viewState {
            case .listAll:
                List {
                    ForEach(rowViewModels) { viewModel in
                        WebhookRowView(viewModel: viewModel)
                    }
                }
            case .createNew:
                Text("Create new")
            }
        }
        .task {
            // TODO-gm:
            // Loading screen
            // load only when in the correct viewState
            await viewModel.listAllWebhooks()
        }
    }
}

#Preview {
    WebhooksView(viewModel: WebhooksViewModel())
}
