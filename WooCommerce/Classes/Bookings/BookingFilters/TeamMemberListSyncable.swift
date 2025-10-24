import Foundation
import Yosemite

/// Syncable implementation for team member (booking resource) filtering
struct TeamMemberListSyncable: ListSyncable {
    typealias StorageType = StorageBookingResource
    typealias ModelType = BookingResource

    let siteID: Int64

    var title: String {
        NSLocalizedString(
            "bookingTeamMemberSelectorView.title",
            value: "Team member",
            comment: "Title of the booking team member selector view"
        )
    }

    var emptyStateMessage: String {
        NSLocalizedString(
            "bookingTeamMemberSelectorView.noMembersFound",
            value: "No team members found",
            comment: "Text on the empty view of the booking team member selector view"
        )
    }

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

    // MARK: - Model Conversion

    func convert(_ storage: StorageBookingResource) -> BookingResource {
        storage.toReadOnly()
    }

    // MARK: - Display Configuration

    func displayName(for item: BookingResource) -> String {
        item.name
    }
}
