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
            EmptyView()
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

// MARK: Constants
private enum Localization {
    static let title = NSLocalizedString("New Order", comment: "Title for the order creation screen")
    static let createButton = NSLocalizedString("Create", comment: "Button to create an order on the New Order screen")
    static let errorMessage = NSLocalizedString("Unable to create new order", comment: "Notice displayed when order creation fails")
}

struct NewOrder_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = NewOrderViewModel(siteID: 123)

        NavigationView {
            NewOrder(viewModel: viewModel)
        }
    }
}
