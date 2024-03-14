import SwiftUI
import Yosemite

/// SwiftUI view for the coupon list screen.
///
struct EnhancedCouponListView: View {
    private let siteID: Int64

    @ObservedObject private var viewModel: CouponListViewModel

    @State private var showingCouponSearch = false
    @State private var showingCouponTypeSheet = false
    @State private var selectedCouponType: Coupon.DiscountType?
    @State private var showingCouponDetail = false
    @State private var showingSearchResult = false
    @State private var selectedCoupon: Coupon?
    @State private var notice: Notice?

    private let couponTypes: [Coupon.DiscountType] = [
        .percent,
        .fixedCart,
        .fixedProduct
    ]

    init(siteID: Int64, viewModel: CouponListViewModel) {
        self.siteID = siteID
        self.viewModel = viewModel
    }

    var body: some View {
        CouponListView(siteID: siteID,
                       viewModel: viewModel,
                       emptyStateActionTitle: Localization.createCoupon,
                       emptyStateAction: { showingCouponTypeSheet = true },
                       onCouponSelected: { coupon in
            selectedCoupon = coupon
            showingCouponDetail = true
        })
        .navigationTitle(Localization.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.couponViewModels.isNotEmpty {
                Button(action: {
                    ServiceLocator.analytics.track(.couponsListSearchTapped)
                    showingCouponSearch = true
                }) {
                    Image(systemName: "magnifyingglass")
                }
                .accessibilityIdentifier("coupon-search-button")
            }

            Button(action: {
                ServiceLocator.analytics.track(.couponsListCreateTapped)
                showingCouponTypeSheet = true
            }) {
                Image(systemName: "plus")
            }
            .accessibilityIdentifier("coupon-create-button")
        }
        .sheet(isPresented: $showingCouponSearch) {
            NavigationStack {
                CouponSearchView(siteID: siteID) { coupon in
                    selectedCoupon = coupon
                    showingSearchResult = true
                }
                .navigationDestination(isPresented: $showingSearchResult) {
                    couponDetailView
                }
            }
        }
        .sheet(isPresented: $showingCouponTypeSheet) {
            bottomSheet.presentationDetents([.medium])
        }
        .sheet(item: $selectedCouponType) { discountType in
            AddEditCoupon(AddEditCouponViewModel(siteID: siteID,
                                                 discountType: discountType,
                                                 onSuccess: { _ in
                selectedCouponType = nil
            }))
        }
        .notice($notice)
        .navigationDestination(isPresented: $showingCouponDetail) {
            couponDetailView
        }
    }
}

private extension EnhancedCouponListView {
    var bottomSheet: some View {
        List {
            Section(Localization.createCoupon) {
                ForEach(couponTypes) { type in
                    Button {
                        showingCouponTypeSheet = false
                        selectedCouponType = type
                    } label: {
                        HStack(alignment: .top) {
                            if let image = type.actionSheetIcon {
                                Image(uiImage: image)
                                    .renderingMode(.template)
                                    .foregroundColor(Color(.gray(.shade20)))
                            }
                            VStack(alignment: .leading) {
                                Text(type.localizedName)
                                    .bodyStyle()
                                Text(type.actionSheetDescription ?? "")
                                    .secondaryBodyStyle()
                            }
                        }
                        .clipShape(Rectangle())
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.grouped)
        .background(Color(.listForeground(modal: false)))
    }

    @ViewBuilder
    var couponDetailView: some View {
        if let selectedCoupon {
            CouponDetails(viewModel: CouponDetailsViewModel(coupon: selectedCoupon,
                                                            onUpdate: {},
                                                            onDeletion: {
                showingCouponDetail = false
                notice = Notice(title: Localization.couponDeleted, feedbackType: .success)
            }))
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
        static let createCoupon = NSLocalizedString(
            "enhancedCouponListView.createCoupon",
            value: "Create Coupon",
            comment: "Title of the coupon type bottom sheet"
        )
        static let couponDeleted = NSLocalizedString(
            "enhancedCouponListView.couponDeleted",
            value: "Coupon deleted",
            comment: "Notice message after deleting coupon from the Coupon Details screen"
        )
    }
}

/// SwiftUI wrapper view for coupon search
///
private struct CouponSearchView: UIViewControllerRepresentable {
    let siteID: Int64
    let onSelection: (Coupon) -> Void

    func makeUIViewController(context: Self.Context) -> SearchViewController<TitleAndSubtitleAndStatusTableViewCell, CouponSearchUICommand> {
        let searchViewController = SearchViewController<TitleAndSubtitleAndStatusTableViewCell, CouponSearchUICommand>(
            storeID: siteID,
            command: CouponSearchUICommand(siteID: siteID, onSelection: onSelection),
            cellType: TitleAndSubtitleAndStatusTableViewCell.self,
            cellSeparator: .singleLine
        )
        return searchViewController
    }

    func updateUIViewController(_ uiViewController: SearchViewController<TitleAndSubtitleAndStatusTableViewCell, CouponSearchUICommand>, context: Context) {
        // nothing to do here
    }
}
