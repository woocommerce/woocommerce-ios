import Foundation
import CoreData


extension PaymentGatewayAccount {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PaymentGatewayAccount> {
        return NSFetchRequest<PaymentGatewayAccount>(entityName: "PaymentGatewayAccount")
    }

    @NSManaged public var country: String
    @NSManaged public var currentDeadline: Date?
    @NSManaged public var defaultCurrency: String
    @NSManaged public var gatewayID: String
    @NSManaged public var hasOverdueRequirements: Bool
    @NSManaged public var hasPendingRequirements: Bool
    @NSManaged public var isCardPresentEligible: Bool
    @NSManaged public var siteID: Int64
    @NSManaged public var statementDescriptor: String
    @NSManaged public var status: String
    @NSManaged public var supportedCurrencies: [String]
    @NSManaged public var isLive: Bool
    @NSManaged public var isInTestMode: Bool
}

extension PaymentGatewayAccount: Identifiable {

}
