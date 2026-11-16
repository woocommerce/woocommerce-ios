import StoreDesignSystem
import SwiftUI

struct StoreOrderListScreen: View {
    @ObservedObject var adapter: StoreOrderListAdapter

    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: StoreSpacing.s0) {
                StoreOrderListBrowsingRow(filterCount: adapter.filterCount,
                                          lastUpdatedText: adapter.lastUpdatedText,
                                          onFilterTapped: adapter.filterTapped)

                List {
                    if adapter.topBanner != .none {
                        StoreOrderListBanner(banner: adapter.topBanner,
                                             onRetryCurrency: adapter.retryCurrencyTapped,
                                             onTroubleshoot: adapter.troubleshootTapped,
                                             onContactSupport: adapter.contactSupportTapped)
                            .storeListRow()
                    }

                    content

                    if adapter.isLoadingNextPage {
                        ProgressView()
                            .tint(.storePrimary)
                            .frame(maxWidth: .infinity)
                            .padding(StorePadding.p5)
                            .storeListRow(background: .storeSurface)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(.storeSectionBackground)
                .accessibilityIdentifier("orders-table-view")
                .refreshable {
                    await adapter.refresh()
                }
                .background {
                    StoreOrderListScrollViewReader(onResolve: adapter.contentScrollViewResolved)
                }
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y
                } action: { _, _ in
                    adapter.didScroll()
                }
                .onChange(of: adapter.scrollTargetOrderID) { _, orderID in
                    guard let orderID else { return }
                    withAnimation {
                        proxy.scrollTo(orderID, anchor: .center)
                    }
                    adapter.consumeScrollTarget()
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch adapter.contentState {
        case .placeholder:
            ForEach(0..<Constants.placeholderCount, id: \.self) { _ in
                StoreOrderListSkeletonView()
                    .storeListRow(background: .storeSurface)
                StoreDivider(variant: .inset)
                    .storeListRow(background: .storeSurface)
            }
        case .empty:
            StoreOrderListEmptyView(filterDescription: emptyFilterDescription,
                                    onAction: emptyAction)
                .storeListRow()
        case .results:
            ForEach(adapter.sections) { section in
                Text(section.title)
                    .storeTextStyle(.titleSmall.emphasized)
                    .foregroundStyle(.storeOnSectionBackgroundVariant)
                    .padding(.horizontal, StorePadding.p5)
                    .padding(.vertical, StorePadding.p4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.storeSectionBackground)
                    .accessibilityAddTraits(.isHeader)
                    .storeListRow()

                ForEach(section.orders) { row in
                    StoreOrderListRow(row: row,
                                      isSelected: adapter.selectedOrderID == row.id,
                                      onSelect: { adapter.selectOrder(row.id) },
                                      onAppear: { adapter.orderAppeared(at: row.itemIndex) })
                        .id(row.id)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            if row.cellViewModel.status != .completed {
                                Button(OrderListLocalization.markCompleted,
                                       systemImage: "checkmark") {
                                    adapter.markCompleted(row.objectID)
                                }
                                .tint(.storePrimary)
                            }
                        }
                        .storeListRow(background: .storeSurface)
                    StoreDivider(variant: .inset)
                        .storeListRow(background: .storeSurface)
                }
            }
        }
    }

    private var emptyFilterDescription: String? {
        guard adapter.filterCount > 0 else { return nil }
        return adapter.filterDescription ?? OrderListLocalization.filterTitle(count: adapter.filterCount)
    }

    private var emptyAction: () -> Void {
        adapter.filterCount > 0 ? adapter.clearFiltersTapped : adapter.learnMoreTapped
    }
}

private extension View {
    func storeListRow(background: Color = .storeSectionBackground) -> some View {
        listRowInsets(.init())
            .listRowSeparator(.hidden)
            .listRowBackground(background)
    }
}

private extension StoreOrderListScreen {
    enum Constants {
        static let placeholderCount = 3
    }
}
