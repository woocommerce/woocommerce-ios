import SwiftUI
import struct Yosemite.POSOrder
import enum Yosemite.OrderPaymentMethod

struct POSOrderListView: View {
    let onClose: () -> Void

    @Environment(POSOrderListModel.self) private var orderListModel
    @Environment(\.keyboardObserver) private var keyboardObserver
    @Environment(\.posAnalytics) private var analytics
    @Environment(\.siteTimezone) private var siteTimezone
    @StateObject private var infiniteScrollTriggerDeterminer = ThresholdInfiniteScrollTriggerDeterminer()

    @State private var isSearching: Bool = false
    @State private var searchTerm: String = ""
    @Namespace private var searchTransition

    private var ordersViewState: POSOrderListState {
        orderListModel.ordersController.ordersViewState
    }

    var body: some View {
        VStack(spacing: 0) {
            POSPageHeaderView(
                items: isSearching ? [] : [.init(
                    title: Localization.ordersTitle,
                    subtitle: nil,
                    isSelected: true,
                    isLoading: isSearching ? false : {
                        if case .loading(let orders) = ordersViewState {
                            return !orders.isEmpty
                        }
                        return false
                    }()
                )],
                backButtonConfiguration: isSearching ? nil : .init(state: .enabled, action: onClose, buttonIcon: "xmark"),
                trailingContent: {
                    if !isSearching && !ordersViewState.orders.isEmpty {
                        POSPageHeaderActionButton(
                            systemName: "magnifyingglass",
                            backgroundColor: .posSurface,
                            imageColor: .posOnSurface
                        ) {
                            analytics.track(event: WooAnalyticsEvent.PointOfSale.ordersListSearchButtonTapped())
                            setSearch(true)
                        }
                        .matchedGeometryEffect(id: Constants.searchControlID, in: searchTransition)
                        .transition(.opacity.combined(with: .scale))
                    }

                    if isSearching {
                        POSSearchField(
                            searchTerm: $searchTerm,
                            searchable: POSOrderSearchable(ordersController: orderListModel.ordersController),
                            onBack: {
                                setSearch(false)
                            }
                        )
                        .matchedGeometryEffect(id: Constants.searchControlID, in: searchTransition)
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                        .onChange(of: searchTerm) { _, newValue in
                            if newValue.isEmpty {
                                orderListModel.ordersController.clearSearchOrders()
                            }
                        }
                    }
                }
            )
            .animation(.easeInOut(duration: Constants.animationDuration), value: isSearching)

            switch ordersViewState {
            case .empty:
                POSListEmptyView(
                    viewModel: POSOrderListEmptyViewModel(isSearching: isSearching)
                ) {
                    Task { @MainActor in
                        await orderListModel.ordersController.loadOrders()
                    }
                }
                .padding(.bottom, keyboardObserver.keyboardHeight)
            case .error(let errorState):
                POSListErrorView(error: errorState) {
                    Task { @MainActor in
                        await orderListModel.ordersController.loadOrders()
                    }
                }
                .padding(.bottom, keyboardObserver.keyboardHeight)
            default:
                listView
            }
        }
        .animation(.default, value: orderListModel.ordersController.ordersViewState.isEmpty)
        .background(Color.posSurfaceBright)
        .navigationBarHidden(true)
        .refreshable {
            analytics.track(event: WooAnalyticsEvent.PointOfSale.ordersListPullToRefresh())
            await orderListModel.ordersController.refreshOrders()
        }
        .task {
            await orderListModel.ordersController.loadOrders()
        }
    }

    @ViewBuilder
    private var headerRows: some View {
        switch ordersViewState {
        case .inlineError(_, let errorState, .refresh):
            POSListInlineErrorView(errorState: errorState) {
                Task { @MainActor in
                    await orderListModel.ordersController.loadOrders()
                }
            }
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var listView: some View {
        InfiniteScrollView(
            triggerDeterminer: infiniteScrollTriggerDeterminer,
            loadMore: {
                guard case .loaded(_, let hasMoreItems) = ordersViewState, hasMoreItems else { return }
                await orderListModel.ordersController.loadNextOrders()
            },
            content: {
                LazyVStack(spacing: POSSpacing.small) {
                    headerRows

                    let orders = ordersViewState.orders
                    ForEach(Array(orders.enumerated()), id: \.element.id) { index, order in
                        Button(action: {
                            analytics.track(event: WooAnalyticsEvent.PointOfSale.ordersListRowTapped(
                                orderID: order.id,
                                orderStatus: order.status.rawValue,
                                listPosition: index,
                                orderCreatedDate: order.dateCreated,
                                siteTimezone: siteTimezone
                            ))
                            orderListModel.ordersController.selectOrder(order)
                        }) {
                            OrderRowView(order: order, isSelected: orderListModel.ordersController.selectedOrder?.id == order.id)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .animation(.default, value: orders.first?.id)

                    footerRows
                }
                .padding(.horizontal)
                .padding(.bottom, POSPadding.medium)
            }
        )
        .scrollDismissesKeyboard(.immediately)
    }

    @ViewBuilder
    private var footerRows: some View {
        switch ordersViewState {
        case .loading(let orders):
            if orders.isEmpty {
                ForEach(0..<8, id: \.self) { _ in
                    GhostOrderRowView()
                }
                .opacity(orders.isEmpty ? 1 : 0)
                .animation(.default, value: orders.isEmpty)
            } else {
                GhostOrderRowView()
            }
        case .inlineError(_, let errorState, .pagination):
            POSListInlineErrorView(errorState: errorState) {
                Task { @MainActor in
                    await orderListModel.ordersController.loadNextOrders()
                }
            }
        default:
            EmptyView()
        }
    }
}

private struct OrderRowView: View {
    let order: POSOrder
    let isSelected: Bool

    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    private var minHeight: CGFloat {
        min(Constants.orderCardMinHeight * scale, Constants.maximumOrderCardHeight)
    }

    var body: some View {
        HStack(alignment: .center, spacing: POSSpacing.medium) {
            VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                Text("#\(order.number)") // TODO: WOOMOB-1142
                    .font(.posBodySmallBold)
                    .foregroundStyle(Color.posOnSurface)
                    .fixedSize(horizontal: false, vertical: true)

                Text(DateFormatter.dateAndTimeFormatter.string(from: order.dateCreated))
                    .font(.posBodySmallRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
                    .fixedSize(horizontal: false, vertical: true)


                if let customerEmail = order.customerEmail, customerEmail.isNotEmpty {
                    Text(customerEmail)
                        .font(.posBodySmallRegular())
                        .foregroundStyle(Color.posOnSurfaceVariantHighest)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .multilineTextAlignment(.leading)

            Spacer()

            VStack(alignment: .trailing, spacing: POSSpacing.xSmall) {
                Text(order.formattedTotal)
                    .font(.posBodyLargeBold)
                    .foregroundStyle(Color.posOnSurface)

                PointOfSaleOrderBadgeView(order: order)
            }
            .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, POSPadding.medium * (1 / scale))
        .padding(.vertical, POSPadding.medium * (1 / scale))
        .frame(maxWidth: .infinity, minHeight: dynamicTypeSize.isAccessibilitySize ? nil : minHeight, alignment: .leading)
        .background(isSelected ? Color.posSurfaceDim : Color.posSurfaceContainerLowest)
        .posItemCardBorderStyles()
    }
}

private struct GhostOrderRowView: View {
    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    private var minHeight: CGFloat {
        min(Constants.orderCardMinHeight * scale, Constants.maximumOrderCardHeight)
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                HStack(alignment: .center, spacing: POSSpacing.medium) {
                    VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                        Rectangle()
                            .fill(Color.posOnSurfaceVariantLowest)
                            .frame(width: geometry.size.width * 0.2, height: 16)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .shimmering()

                        Rectangle()
                            .fill(Color.posOnSurfaceVariantLowest)
                            .frame(width: geometry.size.width * 0.4, height: 14)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .shimmering()
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: POSSpacing.xSmall) {
                        Rectangle()
                            .fill(Color.posOnSurfaceVariantLowest)
                            .frame(width: geometry.size.width * 0.25, height: 18)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .shimmering()

                        Rectangle()
                            .fill(Color.posOnSurfaceVariantLowest)
                            .frame(width: geometry.size.width * 0.28, height: 14)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .shimmering()
                    }
                }
                Spacer()
            }
        }
        .padding(.horizontal, POSPadding.medium * (1 / scale))
        .padding(.vertical, POSPadding.medium * (1 / scale))
        .frame(maxWidth: .infinity, minHeight: dynamicTypeSize.isAccessibilitySize ? nil : minHeight, alignment: .leading)
        .background(Color.posSurfaceContainerLowest)
        .posItemCardBorderStyles()
        .geometryGroup()
    }
}

// MARK: - Order Badge View

struct PointOfSaleOrderBadgeView: View {
    let order: POSOrder

    init(order: POSOrder) {
        self.order = order
    }

    var body: some View {
        HStack(spacing: POSSpacing.xSmall) {
            if let paymentMethodIcon = paymentMethodIcon {
                Image(systemName: paymentMethodIcon)
                    .foregroundStyle(statusColor)
                    .font(.caption)
            }
            Text(order.status.localizedName)
                .font(.posCaptionRegular)
                .foregroundStyle(statusColor)
        }
        .padding(.horizontal, POSPadding.small)
        .padding(.vertical, POSPadding.xSmall)
        .background(statusColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
    }

    private var paymentMethodIcon: String? {
        let paymentMethod = OrderPaymentMethod(rawValue: order.paymentMethodID)
        switch paymentMethod {
        case .cod:
            return "banknote"
        case .stripe, .woocommercePayments:
            return "creditcard"
        default:
            return nil
        }
    }

    private var statusColor: Color {
        switch order.status {
        case .completed:
            return .posSuccess
        case .failed:
            return .posError
        default:
            return .posOnSurfaceVariantLowest
        }
    }
}

// MARK: - Search

private extension POSOrderListView {
    func setSearch(_ isSearchingValue: Bool) {
        if isSearchingValue {
            isSearching = true
        } else {
            searchTerm = ""
            isSearching = false
            // Clear search results and return to default orders
            orderListModel.ordersController.clearSearchOrders()
        }
    }
}

final class POSOrderSearchable: POSSearchable {
    private let ordersController: POSSearchingOrderListControllerProtocol

    init(ordersController: POSSearchingOrderListControllerProtocol) {
        self.ordersController = ordersController
    }

    var searchFieldPlaceholder: String {
        Localization.searchFieldPlaceholder
    }

    var searchHistory: [String] {
        []
    }

    func performSearch(term: String) async {
        await ordersController.searchOrders(searchTerm: term)
    }

    func clearSearchResults() {
        ordersController.clearSearchOrders()
    }
}

// MARK: - Constants

private enum Constants {
    static let orderCardMinHeight: CGFloat = 90
    static let maximumOrderCardHeight: CGFloat = Constants.orderCardMinHeight * 2
    static let animationDuration: CGFloat = 0.2
    static let searchControlID = "searchControl"
}

extension POSOrderListView {
    enum Localization {
        static let ordersTitle = NSLocalizedString(
            "pos.orderListView.ordersTitle",
            value: "Orders",
            comment: "Title at the header for the Orders view.")
    }
}

private enum Localization {
    static let searchFieldPlaceholder = NSLocalizedString(
        "pos.orderListView.searchFieldPlaceholder",
        value: "Search orders",
        comment: "Placeholder for a search field in the Orders view."
    )
}

#if DEBUG
#Preview("List") {
    NavigationSplitView(columnVisibility: .constant(.all)) {
        POSOrderListView(onClose: {})
            .navigationSplitViewColumnWidth(450)
            .environment(POSPreviewHelpers.makePreviewOrdersModel(state: .loaded([POSPreviewHelpers.makePreviewOrder()], hasMoreItems: false)))
    } detail: {
        Text("Detail View")
    }
    .navigationSplitViewStyle(.balanced)
}

#Preview("Empty State") {
    NavigationSplitView(columnVisibility: .constant(.all)) {
        POSOrderListView(onClose: {})
            .navigationSplitViewColumnWidth(450)
            .environment(POSPreviewHelpers.makePreviewOrdersModel(state: .empty))
    } detail: {
        Text("Detail View")
    }
}

#Preview("Error State") {
    NavigationSplitView(columnVisibility: .constant(.all)) {
        POSOrderListView(onClose: {})
            .navigationSplitViewColumnWidth(450)
            .environment(POSPreviewHelpers.makePreviewOrdersModel(state: .error(.errorOnLoadingOrders())))
    } detail: {
        Text("Detail View")
    }
}

#Preview("Loading State") {
    NavigationSplitView(columnVisibility: .constant(.all)) {
        POSOrderListView(onClose: {})
            .navigationSplitViewColumnWidth(450)
            .environment(POSPreviewHelpers.makePreviewOrdersModel(state: .loading([])))
    } detail: {
        Text("Detail View")
    }
}

#Preview("Inline Error - Refresh") {
    NavigationSplitView(columnVisibility: .constant(.all)) {
        POSOrderListView(onClose: {})
            .navigationSplitViewColumnWidth(450)
            .environment(POSPreviewHelpers.makePreviewOrdersModel(
                state: .inlineError([POSPreviewHelpers.makePreviewOrder()],
                                   error: .errorOnLoadingOrders(),
                                   context: .refresh)
            ))
    } detail: {
        Text("Detail View")
    }
}

#Preview("Inline Error - Pagination") {
    NavigationSplitView(columnVisibility: .constant(.all)) {
        POSOrderListView(onClose: {})
            .navigationSplitViewColumnWidth(450)
            .environment(POSPreviewHelpers.makePreviewOrdersModel(
                state: .inlineError([POSPreviewHelpers.makePreviewOrder()],
                                   error: .errorOnLoadingOrdersNextPage(),
                                   context: .pagination)
            ))
    } detail: {
        Text("Detail View")
    }
}

#Preview("Search Empty State") {
    NavigationSplitView(columnVisibility: .constant(.all)) {
        POSOrderListView(onClose: {})
            .navigationSplitViewColumnWidth(450)
            .environment(POSPreviewHelpers.makePreviewOrdersModel(state: .empty))
    } detail: {
        Text("Detail View")
    }
}

#endif
