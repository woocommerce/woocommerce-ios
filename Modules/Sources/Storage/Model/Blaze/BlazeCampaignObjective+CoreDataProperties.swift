import Foundation
import CoreData

extension BlazeCampaignObjective {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BlazeCampaignObjective> {
        return NSFetchRequest<BlazeCampaignObjective>(entityName: "BlazeCampaignObjective")
    }

    @NSManaged public var id: String
    @NSManaged public var title: String
    @NSManaged public var generalDescription: String
    @NSManaged public var suitableForDescription: String
    @NSManaged public var locale: String

}
