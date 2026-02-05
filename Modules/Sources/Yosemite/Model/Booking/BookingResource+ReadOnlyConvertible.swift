import Foundation
import Storage

// MARK: - Storage.BookingResource: ReadOnlyConvertible
//
extension Storage.BookingResource: ReadOnlyConvertible {

    /// Updates the Storage.BookingResource with the a ReadOnly.
    ///
    public func update(with resource: Yosemite.BookingResource) {
        siteID = resource.siteID
        resourceID = resource.resourceID
        name = resource.name
        quantity = resource.quantity
        role = resource.role
        email = resource.email
        phoneNumber = resource.phoneNumber
        imageID = resource.imageID ?? 0
        imageURL = resource.imageURL
        descriptionText = resource.description
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.BookingResource {
        BookingResource(siteID: siteID,
                        resourceID: resourceID,
                        name: name ?? "",
                        quantity: quantity,
                        role: role,
                        email: email,
                        phoneNumber: phoneNumber,
                        imageID: imageID,
                        imageURL: imageURL,
                        description: descriptionText)
    }
}

extension Yosemite.BookingResource: ReadOnlyType {
    /// Indicates if the receiver is a representation of a specified Storage.Entity instance.
    ///
    public func isReadOnlyRepresentation(of storageEntity: Any) -> Bool {
        guard let storageResource = storageEntity as? Storage.BookingResource else {
            return false
        }

        return siteID == Int(storageResource.siteID) && resourceID == Int(storageResource.resourceID)
    }
}
