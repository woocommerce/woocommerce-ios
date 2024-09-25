import SwiftUI
import Yosemite

enum WebhooksViewState: String, CaseIterable, Identifiable {
    case listAll = "All Webhooks"
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
            .padding()
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
                            Image(.magnifyingGlassNotFound)
                                .padding(.bottom)
                            Text(Localization.noWebhooksFoundMessage)
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
                    Group {
                        Text(Localization.addNewWebhookHint1)
                        Text(Localization.addNewWebhookHint2)
                    }
                    .subheadlineStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom)

                    HStack() {
                        Text(Localization.topicSelectionHint)
                            .subheadlineStyle()
                        Spacer()
                        Picker("", selection: $selectedOption) {
                            ForEach(AvailableWebhook.allCases, id: \.self) { option in
                                Text(option.rawValue)
                                    .tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    TextField(Localization.deliveryURLPlaceholder, text: $deliveryURLString)
                        .textFieldStyle(RoundedBorderTextFieldStyle(focused: true))

                    Spacer()

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
                        Text(Localization.createWebhookButtonTitle)
                    })
                    .buttonStyle(PrimaryButtonStyle())
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
            Alert(title: Text(Localization.createWebhookErrorTitle),
                  message: Text(Localization.createWebhookErrorMessage),
                  dismissButton: .default(Text(Localization.createWebhookErrorDismiss)))
        }
        .alert(isPresented: $showSuccessModal) {
            Alert(title: Text(Localization.createWebhookSuccessTitle),
                  message: Text(Localization.createWebhookSuccessMessage),
                  dismissButton: .default(Text(Localization.createWebhookSuccessOkButton)))
        }
    }
}

private extension WebhooksView {
    enum Localization {
        static let noWebhooksFoundMessage = NSLocalizedString(
            "settings.webhooksview.noWebhooksFoundMessage",
            value: "No webhooks have been configured yet on your site.",
            comment: "Message shown to the merchant when no webhooks are found on their site."
        )
        static let addNewWebhookHint1 = NSLocalizedString(
            "settings.webhooksview.addNewWebhookHint1",
            value: "Webhooks are event notifications sent to URLs of your choice.",
            comment: "Message shown to the merchant in order to setup their webhooks"
        )
        static let addNewWebhookHint2 = NSLocalizedString(
            "settings.webhooksview.addNewWebhookHint2",
            value: "They can be used to integrate with third-party services which support them.",
            comment: "Message shown to the merchant in order to setup their webhooks"
        )
        static let deliveryURLPlaceholder = NSLocalizedString(
            "settings.webhooksview.deliveryURLPlaceholder",
            value: "Delivery URL:",
            comment: "Texfield's placeholder message indicating an URL must be typed"
        )
        static let createWebhookButtonTitle = NSLocalizedString(
            "settings.webhooksview.createWebhookButtonTitle",
            value: "Create",
            comment: "Title for the button to create a webhook"
        )
        static let createWebhookErrorTitle = NSLocalizedString(
            "settings.webhooksview.createWebhookErrorTitle",
            value: "Error",
            comment: "Error title when webhook creation fails"
        )
        static let createWebhookErrorMessage = NSLocalizedString(
            "settings.webhooksview.createWebhookErrorMessage",
            value: "There was an error creating the webhook. Please try again.",
            comment: "Error message when webhook creation fails"
        )
        static let createWebhookErrorDismiss = NSLocalizedString(
            "settings.webhooksview.createWebhookErrorDismiss",
            value: "Dismiss",
            comment: "Title for the dismiss button when a webhook creation fails"
        )
        static let createWebhookSuccessTitle = NSLocalizedString(
            "settings.webhooksview.createWebhookSuccessTitle",
            value: "Success!",
            comment: "Title shown in an alert when a webhook creation succeeds"
        )
        static let createWebhookSuccessMessage = NSLocalizedString(
            "settings.webhooksview.createWebhookSuccessMessage",
            value: "A new webhook has been created in your site.",
            comment: "Message shown in an alert when a webhook creation succeeds"
        )
        static let createWebhookSuccessOkButton = NSLocalizedString(
            "settings.webhooksview.createWebhookSuccessOkButton",
            value: "Ok",
            comment: "Title for the button that dismisses the alert when a webhook creation succeeds"
        )
        static let topicSelectionHint = NSLocalizedString(
            "settings.webhooksview.topicSelectionHint",
            value: "Select a topic:",
            comment: "Message shown to the merchant so they can select between different available webhook options"
        )
    }
}

#Preview {
    WebhooksView(viewModel: WebhooksViewModel())
}
