import StoreDesignSystem
import SwiftUI
import UIKit
import Yosemite

/// Hosts the design-system Sort/Filter rail above the Products table.
@MainActor
final class StoreProductListHeaderView: UIView {
    // A hosting controller, not `UIHostingConfiguration`, so the rail can present the sort sheet.
    private var hostingController: UIHostingController<StoreProductListRail>?
    // The hosting controller needs a parent to present the sort picker.
    private weak var parent: UIViewController?

    init(parent: UIViewController) {
        self.parent = parent
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(sortTitle: String, sortOrder: ProductsSortOrder,
                   filterTitle: String, hasActiveFilters: Bool,
                   onSortTapped: @escaping () -> Void,
                   onSortOrderSelected: @escaping (ProductsSortOrder) -> Void,
                   onFilter: @escaping () -> Void) {
        let rail = StoreProductListRail(sortTitle: sortTitle,
                                        sortOrder: sortOrder,
                                        filterTitle: filterTitle,
                                        hasActiveFilters: hasActiveFilters,
                                        onSortTapped: onSortTapped,
                                        onSortOrderSelected: onSortOrderSelected,
                                        onFilter: onFilter,
                                        prefersSortPopover: { [weak self] in self?.prefersSortPopover ?? false })

        // Same root view type, so SwiftUI keeps the rail's state and an open sheet stays open.
        if let hostingController {
            hostingController.rootView = rail
            hostingController.view.invalidateIntrinsicContentSize()
            return
        }

        let hostingController = UIHostingController(rootView: rail)
        hostingController.sizingOptions = .intrinsicContentSize
        hostingController.safeAreaRegions = []
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        parent?.addChild(hostingController)
        addSubview(hostingController.view)
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        hostingController.didMove(toParent: parent)
        self.hostingController = hostingController
    }

    // The legacy picker's rule, read from the window: the split view's primary column reports compact.
    private var prefersSortPopover: Bool {
        window?.traitCollection.horizontalSizeClass == .regular && !traitCollection.preferredContentSizeCategory.isAccessibilityCategory
    }
}

struct StoreProductListRail: View {
    /// Titles both the Sort chip and its picker.
    let sortTitle: String
    let sortOrder: ProductsSortOrder
    let filterTitle: String
    let hasActiveFilters: Bool
    let onSortTapped: () -> Void
    let onSortOrderSelected: (ProductsSortOrder) -> Void
    let onFilter: () -> Void
    /// Asked when Sort is tapped, so an open picker keeps its style until dismissed.
    let prefersSortPopover: () -> Bool

    @State private var sortPresentation: SortPresentation?

    var body: some View {
        HStack(spacing: StoreSpacing.s3) {
            StoreFilterChip(sortTitle, icon: sortIcon, isSelected: false) {
                onSortTapped()
                sortPresentation = prefersSortPopover() ? .popover : .sheet
            }
            .accessibilityValue(sortOrder.actionSheetTitle)
            .popover(isPresented: isShowingSortPopover, arrowEdge: .top) {
                ScrollView {
                    sortOptions
                }
                .scrollBounceBehavior(.basedOnSize)
                .frame(width: Layout.popoverWidth)
                .presentationCompactAdaptation(.popover)
                .presentationBackground(Color.storeSurfaceBright)
            }
            Spacer(minLength: StoreSpacing.s0)
            StoreFilterChip(filterTitle,
                            icon: StoreIcon.BarsFilter.regular,
                            isSelected: hasActiveFilters,
                            action: onFilter)
                .accessibilityIdentifier("product-filter-button")
        }
        .padding(.horizontal, StorePadding.p5)
        .padding(.vertical, StorePadding.p2)
        .storeSheet(isPresented: isShowingSortSheet) {
            sortOptions
        }
    }

    private var isShowingSortSheet: Binding<Bool> {
        isShowing(.sheet)
    }

    private var isShowingSortPopover: Binding<Bool> {
        isShowing(.popover)
    }

    private func isShowing(_ presentation: SortPresentation) -> Binding<Bool> {
        Binding(get: { sortPresentation == presentation }, set: { isShowing in
            if !isShowing, sortPresentation == presentation {
                sortPresentation = nil
            }
        })
    }

    private var sortOptions: some View {
        StoreProductListSortSheet(title: sortTitle, selected: sortOrder) { sortOrder in
            sortPresentation = nil
            onSortOrderSelected(sortOrder)
        }
    }

    private var sortIcon: StoreIconImage {
        switch sortOrder {
        case .dateAscending, .nameAscending:
            return StoreIcon.ArrowUp.regular
        case .dateDescending, .nameDescending:
            return StoreIcon.ArrowDown.regular
        }
    }
}

private extension StoreProductListRail {
    enum SortPresentation {
        case sheet
        case popover
    }

    enum Layout {
        static let popoverWidth: CGFloat = 320
    }
}

private struct StoreProductListSortSheet: View {
    let title: String
    let selected: ProductsSortOrder
    let onSelect: (ProductsSortOrder) -> Void

    var body: some View {
        let command = ProductsSortOrderBottomSheetListSelectorCommand(selected: selected, onSelection: onSelect)
        VStack(alignment: .leading, spacing: StoreSpacing.s0) {
            Text(title)
                .storeTextStyle(.titleLarge.strong)
                .foregroundStyle(.storeOnSurface)
                .accessibilityAddTraits(.isHeader)
                .padding(.horizontal, StorePadding.p7)
                .padding(.vertical, StorePadding.p5)
            ForEach(command.data, id: \.rawValue) { sortOrder in
                let isSelected = command.isSelected(model: sortOrder)
                StoreCell(sortOrder.actionSheetTitle, action: { command.handleSelectedChange(selected: sortOrder) }) {
                    if isSelected {
                        StoreIcon.Check.solid.image(size: .large)
                            .foregroundStyle(.storePrimary)
                            .accessibilityHidden(true)
                    }
                }
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}

#if DEBUG
#Preview("Rail") {
    VStack {
        StoreProductListRail(sortTitle: "Sort by", sortOrder: .dateDescending,
                             filterTitle: "Filter", hasActiveFilters: false,
                             onSortTapped: {}, onSortOrderSelected: { _ in }, onFilter: {}, prefersSortPopover: { false })
        StoreProductListRail(sortTitle: "Sort by", sortOrder: .nameAscending,
                             filterTitle: "Filter (2)", hasActiveFilters: true,
                             onSortTapped: {}, onSortOrderSelected: { _ in }, onFilter: {}, prefersSortPopover: { false })
    }
}

#Preview("Sort sheet") {
    StoreProductListSortSheet(title: "Sort by", selected: .nameAscending, onSelect: { _ in })
}
#endif
