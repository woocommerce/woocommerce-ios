import Foundation
import Yosemite

/// Syncable implementation for team member (booking resource) filtering
struct TeamMemberListSyncable: ListSyncable {
    typealias StorageType = StorageBookingResource
    typealias ModelType = BookingResource
    typealias ListFilterType = BookingTeamMemberFilter

    let siteID: Int64

    let title = Localization.title

    let emptyItemTitlePlaceholder: String? = nil
    let emptyStateMessage = Localization.noMembersFound

    let searchConfiguration: ListSearchConfiguration? = nil

    let selectionDisabledMessage: String? = nil

    // MARK: - ResultsController Configuration

    func createPredicate() -> NSPredicate {
        NSPredicate(format: "siteID == %lld", siteID)
    }

    func createSortDescriptors() -> [NSSortDescriptor] {
        [NSSortDescriptor(key: "resourceID", ascending: false)]
    }

    // MARK: - Sync Configuration

    func createSyncAction(
        pageNumber: Int,
        pageSize: Int,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) -> Action {
        BookingAction.synchronizeResources(
            siteID: siteID,
            pageNumber: pageNumber,
            pageSize: pageSize,
            onCompletion: completion
        )
    }

    /// Creates the action to search items with keyword
    func createSearchAction(keyword: String, pageNumber: Int, pageSize: Int, completion: @escaping (Result<Bool, Error>) -> Void) -> Action {
        fatalError("Searching is not supported")
    }

    /// Creates the predicate for filtering search results
    /// - Returns: nil because searching is not supported for team members
    func createSearchPredicate(keyword: String) -> NSPredicate? {
        nil
    }

    // MARK: - Display Configuration

    func displayName(for item: BookingResource) -> String {
        item.name
    }

    /// Returns the description for an item
    func description(for item: BookingResource) -> String? { nil }

    func selectionEnabled(for item: BookingResource) -> Bool { true }

    func filterItem(for item: BookingResource) -> BookingTeamMemberFilter {
        BookingTeamMemberFilter(resourceID: item.resourceID, name: item.name)
    }
}

private extension TeamMemberListSyncable {
    enum Localization {
        static let title = NSLocalizedString(
            "bookingTeamMemberSelectorView.title",
            value: "Team member",
            comment: "Title of the booking team member selector view"
        )
        static let noMembersFound = NSLocalizedString(
            "bookingTeamMemberSelectorView.noMembersFound",
            value: "No team members found",
            comment: "Text on the empty view of the booking team member selector view"
        )
    }
}
