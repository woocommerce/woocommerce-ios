import Foundation
import CoreData

extension BookingResource {
    @NSManaged public var siteID: Int64
    @NSManaged public var resourceID: Int64
    @NSManaged public var name: String?
    @NSManaged public var quantity: Int64
    @NSManaged public var role: String?
    @NSManaged public var email: String?
    @NSManaged public var phoneNumber: String?
    @NSManaged public var imageID: Int64
    @NSManaged public var imageURL: String?
    @NSManaged public var descriptionText: String?
}
