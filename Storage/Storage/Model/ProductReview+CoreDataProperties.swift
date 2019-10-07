import Foundation
import CoreData


extension ProductReview {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductReview> {
        return NSFetchRequest<ProductReview>(entityName: "ProductReview")
    }

    @NSManaged public var dateCreated: Date?
    @NSManaged public var productID: Int64
    @NSManaged public var rating: Int64
    @NSManaged public var review: String?
    @NSManaged public var reviewer: String?
    @NSManaged public var reviewerEmail: String?
    @NSManaged public var reviewerAvatarURL: String?
    @NSManaged public var reviewID: Int64
    @NSManaged public var siteID: Int64
    @NSManaged public var statusKey: String?
    @NSManaged public var verified: Bool

}
