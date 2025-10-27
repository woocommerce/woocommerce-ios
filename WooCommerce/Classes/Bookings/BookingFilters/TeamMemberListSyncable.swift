import Foundation
import Yosemite

/// Syncable implementation for team member (booking resource) filtering
struct TeamMemberListSyncable: ListSyncable {
    typealias StorageType = StorageBookingResource
    typealias ModelType = BookingResource

    let siteID: Int64

    var title: String { Localization.title }

    var emptyStateMessage: String { Localization.noMembersFound }

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

    // MARK: - Display Configuration

    func displayName(for item: BookingResource) -> String {
        item.name
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
