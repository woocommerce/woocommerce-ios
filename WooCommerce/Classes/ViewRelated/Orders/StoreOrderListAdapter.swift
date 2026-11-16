import Combine
import Foundation
import UIKit
import Yosemite

@MainActor
final class StoreOrderListAdapter: ObservableObject {
    enum ContentState: Equatable {
        case placeholder
        case results
        case empty
    }

    struct DaySection: Identifiable {
        let id: String
        let title: String
        let orders: [OrderRow]
    }

    struct OrderRow: Identifiable {
        let id: Int64
        let objectID: FetchResultSnapshotObjectID
        let cellViewModel: OrderListCellViewModel
        let detailsViewModel: OrderDetailsViewModel
        let itemIndex: Int
    }

    @Published private(set) var sections: [DaySection] = []
    @Published private(set) var contentState: ContentState = .placeholder
    @Published private(set) var topBanner: OrderListViewModel.TopBanner = .none
    @Published private(set) var isLoadingNextPage = false
    @Published private(set) var filterCount: Int
    @Published private(set) var filterDescription: String?
    @Published private(set) var lastUpdatedText: String?
    @Published var selectedOrderID: Int64?
    @Published var scrollTargetOrderID: Int64?

    var onRefresh: (() async -> Void)?
    var onOrderSelected: ((Int64) -> Void)?
    var onOrderAppeared: ((Int) -> Void)?
    var onMarkCompleted: ((FetchResultSnapshotObjectID) -> Void)?
    var onFilterTapped: (() -> Void)?
    var onLearnMoreTapped: (() -> Void)?
    var onClearFiltersTapped: (() -> Void)?
    var onRetryCurrencyTapped: (() -> Void)?
    var onTroubleshootTapped: ((Error) -> Void)?
    var onContactSupportTapped: (() -> Void)?
    var onContentScrollViewResolved: ((UIScrollView) -> Void)?
    var onScroll: (() -> Void)?
    var onSnapshotChanged: (() -> Void)?

    private let viewModel: OrderListViewModel
    private var snapshot = FetchResultSnapshot()
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: OrderListViewModel) {
        self.viewModel = viewModel
        self.filterCount = viewModel.filters?.numberOfActiveFilters ?? 0
        self.filterDescription = viewModel.filters?.readableString
    }

    func activate() {
        viewModel.snapshot
            .sink { [weak self] snapshot in
                guard let self else { return }
                self.snapshot = snapshot
                self.rebuildSections()
                if snapshot.numberOfItems > 0 {
                    self.contentState = .results
                }
                self.onSnapshotChanged?()
            }
            .store(in: &cancellables)

        viewModel.statusesDidChange
            .sink { [weak self] in
                self?.rebuildSections()
            }
            .store(in: &cancellables)

        viewModel.$topBanner
            .sink { [weak self] banner in
                self?.topBanner = banner
            }
            .store(in: &cancellables)

        viewModel.activate()
    }

    func beginSync(isFirstPage: Bool) {
        if snapshot.numberOfItems == 0 {
            contentState = .placeholder
        } else if !isFirstPage {
            isLoadingNextPage = true
        }
    }

    func completeSync() {
        isLoadingNextPage = false
        contentState = snapshot.numberOfItems == 0 ? .empty : .results
    }

    func updateFilters(count: Int, readableDescription: String?) {
        filterCount = count
        filterDescription = readableDescription
    }

    func updateLastSyncTime(_ time: String) {
        lastUpdatedText = time.isEmpty ? nil : OrderListLocalization.lastUpdated(time: time)
    }

    func row(withID orderID: Int64) -> OrderRow? {
        sections.lazy.flatMap(\.orders).first { $0.id == orderID }
    }

    func allDetailsViewModels() -> [OrderDetailsViewModel] {
        sections.flatMap(\.orders).map(\.detailsViewModel)
    }

    func refresh() async {
        await onRefresh?()
    }

    func selectOrder(_ orderID: Int64) {
        onOrderSelected?(orderID)
    }

    func orderAppeared(at itemIndex: Int) {
        onOrderAppeared?(itemIndex)
    }

    func markCompleted(_ objectID: FetchResultSnapshotObjectID) {
        onMarkCompleted?(objectID)
    }

    func filterTapped() {
        onFilterTapped?()
    }

    func learnMoreTapped() {
        onLearnMoreTapped?()
    }

    func clearFiltersTapped() {
        onClearFiltersTapped?()
    }

    func retryCurrencyTapped() {
        onRetryCurrencyTapped?()
    }

    func troubleshootTapped(_ error: Error) {
        onTroubleshootTapped?(error)
    }

    func contactSupportTapped() {
        onContactSupportTapped?()
    }

    func contentScrollViewResolved(_ scrollView: UIScrollView) {
        onContentScrollViewResolved?(scrollView)
    }

    func didScroll() {
        onScroll?()
    }

    func consumeScrollTarget() {
        scrollTargetOrderID = nil
    }

    private func rebuildSections() {
        sections = snapshot.sectionIdentifiers.compactMap { sectionID in
            let rows = snapshot.itemIdentifiers(inSection: sectionID).compactMap { objectID -> OrderRow? in
                guard let cellViewModel = viewModel.cellViewModel(withID: objectID),
                      let detailsViewModel = viewModel.detailsViewModel(withID: objectID),
                      let itemIndex = snapshot.indexOfItem(objectID) else {
                    return nil
                }
                return OrderRow(id: detailsViewModel.order.orderID,
                                objectID: objectID,
                                cellViewModel: cellViewModel,
                                detailsViewModel: detailsViewModel,
                                itemIndex: itemIndex)
            }
            guard rows.isNotEmpty else { return nil }
            return DaySection(id: sectionID,
                              title: viewModel.sectionTitleFor(sectionIdentifier: sectionID) ?? "",
                              orders: rows)
        }
    }
}
