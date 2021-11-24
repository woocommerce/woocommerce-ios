import SwiftUI
import Combine

/// Hosting controller that wraps an `NewOrder` view.
///
final class NewOrderHostingController: UIHostingController<NewOrder> {
    private let noticePresenter: NoticePresenter

    /// References to keep the Combine subscriptions alive within the lifecycle of the object.
    ///
    private var subscriptions: Set<AnyCancellable> = []

    init(viewModel: NewOrderViewModel, noticePresenter: NoticePresenter = ServiceLocator.noticePresenter) {
        self.noticePresenter = noticePresenter
        super.init(rootView: NewOrder(viewModel: viewModel))

        observeNoticeIntent()
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Observe the present notice intent and set it back after presented.
    ///
    private func observeNoticeIntent() {
        rootView.viewModel.$presentNotice
            .compactMap { $0 }
            .sink { [weak self] notice in
                switch notice {
                case .error:
                    self?.noticePresenter.enqueue(notice: .init(title: Localization.errorMessage, feedbackType: .error))
                }

                // Nullify the presentation intent.
                self?.rootView.viewModel.presentNotice = nil
            }
            .store(in: &subscriptions)
    }
}

/// View to create a new manual order
///
struct NewOrder: View {
    @ObservedObject var viewModel: NewOrderViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Layout.noSpacing) {
                Spacer(minLength: Layout.spacerHeight)

                ProductsSection()
            }
        }
        .background(Color(.listBackground))
            .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                switch viewModel.navigationTrailingItem {
                case .none:
                    EmptyView()
                case .create:
                    Button(Localization.createButton) {
                        viewModel.createOrder()
                    }
                case .loading:
                    ProgressView()
                }
            }
        }
        .wooNavigationBarStyle()
    }
}

/// Represents the Products section
///
private struct ProductsSection: View {
    var body: some View {
        Group {
            Divider()

            VStack(alignment: .leading, spacing: NewOrder.Layout.verticalSpacing) {

                Text(Localization.products)
                    .headlineStyle()

                // TODO: Add a list of products added to the order

                AddButton(title: Localization.addProduct) {
                    // TODO: Open Add Product modal view
                }
            }
            .padding()
            .background(Color(.listForeground))

            Divider()
        }
    }
}

/// Represents a button with a plus icon.
/// Used for any button that adds items to the order.
///
private struct AddButton: View {
    let title: String
    let onButtonTapped: () -> Void

    var body: some View {
        Button(action: { onButtonTapped() }) {
            Label {
                Text(title)
            } icon: {
                Image(uiImage: .plusImage)
            }
            Spacer()
        }
    }
}

// MARK: Constants
private extension NewOrder {
    enum Layout {
        static let spacerHeight: CGFloat = 16.0
        static let verticalSpacing: CGFloat = 22.0
        static let noSpacing: CGFloat = 0.0
    }
}

private enum Localization {
    static let title = NSLocalizedString("New Order", comment: "Title for the order creation screen")
    static let createButton = NSLocalizedString("Create", comment: "Button to create an order on the New Order screen")
    static let errorMessage = NSLocalizedString("Unable to create new order", comment: "Notice displayed when order creation fails")
    static let products = NSLocalizedString("Products", comment: "Title text of the section that shows the Products when creating a new order")
    static let addProduct = NSLocalizedString("Add product", comment: "Title text of the button that adds a product when creating a new order")
}

struct NewOrder_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = NewOrderViewModel(siteID: 123)

        NavigationView {
            NewOrder(viewModel: viewModel)
        }
    }
}
