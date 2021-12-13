import Foundation
import CoreData


extension ShippingLabelAccountSettings {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShippingLabelAccountSettings> {
        return NSFetchRequest<ShippingLabelAccountSettings>(entityName: "ShippingLabelAccountSettings")
    }

    @NSManaged public var canEditSettings: Bool
    @NSManaged public var canManagePayments: Bool
    @NSManaged public var isEmailReceiptsEnabled: Bool
    @NSManaged public var lastSelectedPackageID: String?
    @NSManaged public var paperSize: String?
    @NSManaged public var selectedPaymentMethodID: Int64
    @NSManaged public var siteID: Int64
    @NSManaged public var storeOwnerDisplayName: String?
    @NSManaged public var storeOwnerUsername: String?
    @NSManaged public var storeOwnerWpcomEmail: String?
    @NSManaged public var storeOwnerWpcomUsername: String?
    @NSManaged public var paymentMethods: Set<ShippingLabelPaymentMethod>?

}

// MARK: Generated accessors for paymentMethods
extension ShippingLabelAccountSettings {

    @objc(addPaymentMethodsObject:)
    @NSManaged public func addToPaymentMethods(_ value: ShippingLabelPaymentMethod)

    @objc(removePaymentMethodsObject:)
    @NSManaged public func removeFromPaymentMethods(_ value: ShippingLabelPaymentMethod)

    @objc(addPaymentMethods:)
    @NSManaged public func addToPaymentMethods(_ values: NSSet)

    @objc(removePaymentMethods:)
    @NSManaged public func removeFromPaymentMethods(_ values: NSSet)

}
