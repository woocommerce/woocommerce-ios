import Foundation

public struct WooPlan {
    public let planName: String
    public let id: String
    public let planDetails: [WooPlanFeatureGroup]

    init(planName: String, id: String, planDetails: [WooPlanFeatureGroup]) {
        self.planName = planName
        self.id = id
        self.planDetails = planDetails
    }

    public init?() {
        self.planName = "Woo Essentials Monthly"
        self.id = "debug.woocommerce.express.essential.monthly"
        guard let url = Bundle.main.url(forResource: "woo-express-essential-plan-benefits", withExtension: "json"),
              let jsonData = try? Data(contentsOf: url) else {
            fatalError("Failed to load JSON data from file.")
        }

        do {
            let decoder = JSONDecoder()

            guard let featureCategories = try decoder.decode([String: [WooPlanFeatureGroup]].self, from: jsonData)["feature_categories"] else {
                return nil
            }
            self.planDetails = featureCategories
        } catch {
            print("Error decoding JSON: \(error)")
            return nil
        }
    }
}
