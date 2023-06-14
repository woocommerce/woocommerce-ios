import Foundation

public struct WooPlan: Decodable {
    public let name: String
    public let id: String
    public let planDescription: String
    public let planFeatureGroups: [WooPlanFeatureGroup]

    init(name: String, id: String, planDescription: String, planFeatureGroups: [WooPlanFeatureGroup]) {
        self.name = name
        self.id = id
        self.planDescription = planDescription
        self.planFeatureGroups = planFeatureGroups
    }

    public init?() {
        guard let url = Bundle.main.url(forResource: "woo-express-essential-plan-benefits", withExtension: "json") else {
            DDLogError("Error loading Woo Express Plans data from file: could not find file in bundle")
            return nil
        }

        do {
            let jsonData = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            self = try decoder.decode(WooPlan.self, from: jsonData)
        } catch let error where error is DecodingError {
            DDLogError("Error decoding Woo Express Plans JSON: \(error)")
            return nil
        } catch {
            DDLogError("Error loading Woo Express Plans data from file: \(error)")
            return nil
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try container.decode(String.self, forKey: .planName)
        id = try container.decode(String.self, forKey: .planId)
        planDescription = try container.decode(String.self, forKey: .planDescription)
        planFeatureGroups = try container.decode([WooPlanFeatureGroup].self, forKey: .planFeatureGroups)
    }

    private enum CodingKeys: String, CodingKey {
        case planName = "plan_name"
        case planId = "plan_id"
        case planDescription = "plan_description"
        case planFeatureGroups = "feature_categories"
    }
}
