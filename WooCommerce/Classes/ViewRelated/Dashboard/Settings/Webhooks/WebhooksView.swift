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

    @State private var orderCreatedToggle: Bool = false
    @State private var deliveryURLString: String = ""
    @State private var showErrorModal: Bool = false

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
                .listStyle(.plain)
            case .createNew:
                VStack {
                    Toggle(isOn: $orderCreatedToggle, label: { Text("Order created")} )
                    Spacer()
                    TextField("Delivery URL", text: $deliveryURLString)
                        .textFieldStyle(RoundedBorderTextFieldStyle(focused: true))
                    Button(action: {
                        Task {
                            do {
                                try await viewModel.createWebhook( $deliveryURLString.wrappedValue)
                            } catch {
                                showErrorModal = true
                            }
                        }
                    }, label: {
                        Text("Create")
                    })
                    .disabled(orderCreatedToggle ? false : true)
                    .buttonStyle(PrimaryButtonStyle())
                    Spacer()
                }
                .padding()
            }
        }
        .task {
            if viewState == .listAll {
                do {
                    try await viewModel.listAllWebhooks()
                } catch {
                    showErrorModal = true
                }
            }
        }
        .alert(isPresented: $showErrorModal) {
            Alert(title: Text("Error"),
                  message: Text("Error message"),
                  dismissButton: .default(Text("Dismiss")))
        }
    }
}

#Preview {
    WebhooksView(viewModel: WebhooksViewModel())
}
