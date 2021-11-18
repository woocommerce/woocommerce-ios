import SwiftUI

/// View to create a new manual order
///
struct NewOrder: View {
    @ObservedObject var viewModel: NewOrderViewModel

    var body: some View {
        ScrollView {
            EmptyView()
        }
        .background(Color(.listBackground))
            .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                switch viewModel.navigationTrailingItem {
                case .create(let rendered):
                    Button(Localization.createButton) {
                        viewModel.createOrder()
                    }
                        .renderedIf(rendered)
                case .loading:
                    ProgressView()
                }
            }
        }
        .wooNavigationBarStyle()
    }
}

// MARK: Constants
private extension NewOrder {
    enum Localization {
        static let title = NSLocalizedString("New Order", comment: "Title for the order creation screen")
        static let createButton = NSLocalizedString("Create", comment: "Button to create an order on the New Order screen")
    }
}

struct NewOrder_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = NewOrderViewModel(siteID: 123)

        NavigationView {
            NewOrder(viewModel: viewModel)
        }
    }
}
