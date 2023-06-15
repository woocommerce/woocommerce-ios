import Foundation

public struct WooPlan: Decodable {
    public let id: String
    public let name: String
    public let shortName: String
    public let planFrequency: PlanFrequency
    public let planDescription: String
    public let headerImageFileName: String
    public let planFeatureGroups: [WooPlanFeatureGroup]

    init(id: String,
         name: String,
         shortName: String,
         planFrequency: PlanFrequency,
         planDescription: String,
         headerImageFileName: String,
         planFeatureGroups: [WooPlanFeatureGroup]) {
        self.id = id
        self.name = name
        self.shortName = shortName
        self.planFrequency = planFrequency
        self.planDescription = planDescription
        self.headerImageFileName = headerImageFileName
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

        id = try container.decode(String.self, forKey: .planId)
        name = try container.decode(String.self, forKey: .planName)
        shortName = try container.decode(String.self, forKey: .planShortName)
        planFrequency = try container.decode(PlanFrequency.self, forKey: .planFrequency)
        planDescription = try container.decode(String.self, forKey: .planDescription)
        headerImageFileName = try container.decode(String.self, forKey: .headerImageFileName)
        planFeatureGroups = try container.decode([WooPlanFeatureGroup].self, forKey: .planFeatureGroups)
    }

    private enum CodingKeys: String, CodingKey {
        case planId = "plan_id"
        case planName = "plan_name"
        case planShortName = "plan_short_name"
        case planFrequency = "plan_frequency"
        case planDescription = "plan_description"
        case headerImageFileName = "header_image_filename"
        case planFeatureGroups = "feature_categories"
    }

    public enum PlanFrequency: String, Decodable {
        case month
        case year

        public var localizedString: String {
            switch self {
            case .month:
                return Localization.month
            case .year:
                return Localization.year
            }
        }

        private enum Localization {
            static let month = NSLocalizedString("per month", comment: "Description of the frequency of a monthly Woo plan")
            static let year = NSLocalizedString("per year", comment: "Description of the frequency of a yearly Woo plan")
        }
    }
}
