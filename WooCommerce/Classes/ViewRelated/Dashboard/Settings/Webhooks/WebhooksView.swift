import SwiftUI
import Yosemite

enum WebhooksViewState: String, CaseIterable, Identifiable {
    case listAll = "List all Webhooks"
    case createNew = "Create new Webhook"

    // Identifiable conformance
    var id: String { self.rawValue }
}

enum AvailableWebhook: String, CaseIterable {
    case orderCreated = "Order created"
    case couponCreated = "Coupon created"
    case customerCreated = "Customer created"
    case productCreated = "Product created"
}

struct WebhooksView: View {
    @ObservedObject private var viewModel: WebhooksViewModel
    @State private var viewState: WebhooksViewState = .listAll
    @State private var isLoading: Bool = false

    @State private var deliveryURLString: String = ""
    @State private var showErrorModal: Bool = false
    @State private var showSuccessModal: Bool = false

    @State private var selectedOption: AvailableWebhook = .orderCreated

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
                if isLoading {
                    ProgressView()
                        .padding()
                    Spacer()
                } else {
                    if rowViewModels.isEmpty {
                        VStack(alignment: .center) {
                            Spacer()
                            Image(.emptyBox)
                            Text("Webhooks are event notifications sent to URLs of your choice.")
                                .subheadlineStyle()
                            Text("They can be used to integrate with third-party services which support them.")
                                .subheadlineStyle()
                            Spacer()
                        }
                        .padding()
                    } else {
                        List {
                            ForEach(rowViewModels) { viewModel in
                                WebhookRowView(viewModel: viewModel)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            case .createNew:
                VStack {
                    Picker("option", selection: $selectedOption) {
                        ForEach(AvailableWebhook.allCases, id: \.self) { option in
                            Text(option.rawValue)
                                .tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    Spacer()
                    TextField("Delivery URL", text: $deliveryURLString)
                        .textFieldStyle(RoundedBorderTextFieldStyle(focused: true))
                    Button(action: {
                        Task {
                            do {
                                try await viewModel.createWebhook($selectedOption.wrappedValue,
                                                                  $deliveryURLString.wrappedValue)
                                showSuccessModal = true
                            } catch {
                                showErrorModal = true
                            }
                        }
                    }, label: {
                        Text("Create")
                    })
                    .buttonStyle(PrimaryButtonStyle())
                    Spacer()
                }
                .padding()
            }
        }
        .task {
            if viewState == .listAll {
                do {
                    isLoading = true
                    try await viewModel.listAllWebhooks()
                } catch {
                    showErrorModal = true
                }
                isLoading = false
            }
        }
        .refreshable {
            do {
                isLoading = true
                try await viewModel.listAllWebhooks()
                isLoading = false
            } catch {
                showErrorModal = true
            }
        }
        .alert(isPresented: $showErrorModal) {
            Alert(title: Text("Error"),
                  message: Text("Error message"),
                  dismissButton: .default(Text("Dismiss")))
        }
        .alert(isPresented: $showSuccessModal) {
            Alert(title: Text("Success!"),
                  message: Text("A new webhook has been created in your site."),
                  dismissButton: .default(Text("Ok")))
        }
    }
}

#Preview {
    WebhooksView(viewModel: WebhooksViewModel())
}
