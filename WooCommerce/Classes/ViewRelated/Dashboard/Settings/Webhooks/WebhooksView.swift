import SwiftUI

struct WebhooksView: View {
    @ObservedObject private var viewModel: WebhooksViewModel

    init(viewModel: WebhooksViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text("Webhooks")
            Text("(Check the console!)")
                .font(.caption)
        }
        .task {
            await viewModel.listAllWebhooks()
        }
    }
}

#Preview {
    WebhooksView(viewModel: WebhooksViewModel())
}
