import Combine
import SwiftUI

/// SwiftUI view for the coupon list screen.
///
struct EnhancedCouponListView: View {
    private let siteID: Int64
    private let navigationPublisher: AnyPublisher<Void, Never>

    @ObservedObject private var viewModel: CouponListViewModel

    private var searchActionPublisher: AnyPublisher<Void, Never> {
        searchActionSubject.eraseToAnyPublisher()
    }
    private let searchActionSubject = PassthroughSubject<Void, Never>()

    private var addActionPublisher: AnyPublisher<Void, Never> {
        addActionSubject.eraseToAnyPublisher()
    }
    private let addActionSubject = PassthroughSubject<Void, Never>()

    init(siteID: Int64, viewModel: CouponListViewModel, navigationPublisher: AnyPublisher<Void, Never>) {
        self.siteID = siteID
        self.navigationPublisher = navigationPublisher
        self.viewModel = viewModel
    }

    var body: some View {
        EnhancedCouponListWrapperView(siteID: siteID,
                                      viewModel: viewModel,
                                      navigationPublisher: navigationPublisher,
                                      searchActionPublisher: searchActionPublisher,
                                      addActionPublisher: addActionPublisher)
            .navigationTitle(Localization.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewModel.couponViewModels.isNotEmpty {
                    Button(action: {
                        searchActionSubject.send()
                    }) {
                        Image(systemName: "magnifyingglass")
                    }
                    .accessibilityIdentifier("coupon-search-button")
                }

                Button(action: {
                    addActionSubject.send()
                }) {
                    Image(systemName: "plus")
                }
                .accessibilityIdentifier("coupon-create-button")
            }
    }
}

private extension EnhancedCouponListView {
    enum Localization {
        static let navigationTitle = NSLocalizedString(
            "enhancedCouponListView.navigationTitle",
            value: "Coupons",
            comment: "Navigation title for the coupon list screen"
        )
    }
}

private struct EnhancedCouponListWrapperView: UIViewControllerRepresentable {
    private let siteID: Int64
    private var viewModel: CouponListViewModel
    private let navigationPublisher: AnyPublisher<Void, Never>
    private let searchActionPublisher: AnyPublisher<Void, Never>
    private let addActionPublisher: AnyPublisher<Void, Never>

    init(siteID: Int64,
         viewModel: CouponListViewModel,
         navigationPublisher: AnyPublisher<Void, Never>,
         searchActionPublisher: AnyPublisher<Void, Never>,
         addActionPublisher: AnyPublisher<Void, Never>) {
        self.siteID = siteID
        self.viewModel = viewModel
        self.navigationPublisher = navigationPublisher
        self.searchActionPublisher = searchActionPublisher
        self.addActionPublisher = addActionPublisher
    }

    func makeUIViewController(context: Self.Context) -> EnhancedCouponListViewController {
        let viewController = EnhancedCouponListViewController(siteID: siteID,
                                                              viewModel: viewModel,
                                                              navigationPublisher: navigationPublisher,
                                                              searchActionPublisher: searchActionPublisher,
                                                              addActionPublisher: addActionPublisher)
        return viewController
    }

    func updateUIViewController(_ uiViewController: EnhancedCouponListViewController, context: Context) {
        // nothing to do here
    }
}
