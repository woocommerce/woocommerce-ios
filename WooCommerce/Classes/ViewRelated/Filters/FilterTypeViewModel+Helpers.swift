import Foundation

private extension Collection where Element == FilterTypeViewModel {
    /// The number of filters that are currently set to an active value.
    var numberOfActiveFilters: Int {
        let selectedFilterTypes = map { $0.selectedValue }
        return selectedFilterTypes.filter({ $0.isActive }).count
    }
}

extension FilterListViewModel {
    /// The number of filters that are currently set to an active value.
    var numberOfActiveFilters: Int {
        return filterTypeViewModels.numberOfActiveFilters
    }
}

extension FilterTypeViewModel {
    var cellViewModel: FilterListCellViewModel {
        return FilterListCellViewModel(title: title, value: selectedValue.description)
    }
}
