import Foundation

extension StoreCreationFeaturesQuestionViewModel {
    enum Feature: String, CaseIterable {
        case salesAndAnalyticsReports = "sales_and_analytics"
        case productManagementAndInventoryTracking = "product_management_and_inventory"
        case flexibleAndSecurePaymentOptions = "payment_options"
        case inPersonPayment = "in_person_payments"
        case abilityToScaleAsBusinessGrows = "scale_as_business_grows"
        case customizationOptionForStoreDesign = "customization_options_for_store_design"
        case wideRangeOfPluginsAndExtensions = "access_plugin_and_extensions"
        case other = "other"
    }

    var features: [Feature] {
        Feature.allCases
    }
}

extension StoreCreationFeaturesQuestionViewModel.Feature {
    var name: String {
        switch self {
        case .salesAndAnalyticsReports:
            return NSLocalizedString("Comprehensive sales and analytics reports", comment: "Feature option in the store creation features question.")
        case .productManagementAndInventoryTracking:
            return NSLocalizedString("Easy product management and inventory tracking", comment: "Feature option in the store creation features question.")
        case .flexibleAndSecurePaymentOptions:
            return NSLocalizedString("Flexible and secure payment options", comment: "Feature option in the store creation features question.")
        case .inPersonPayment:
            return NSLocalizedString("In-person payment", comment: "Feature option in the store creation features question.")
        case .abilityToScaleAsBusinessGrows:
            return NSLocalizedString("Ability to scale as my business grows", comment: "Feature option in the store creation features question.")
        case .customizationOptionForStoreDesign:
            return NSLocalizedString("Customization options for my store design", comment: "Feature option in the store creation features question.")
        case .wideRangeOfPluginsAndExtensions:
            return NSLocalizedString("Access to a wide range of plugins and extensions", comment: "Feature option in the store creation features question.")
        case .other:
            return NSLocalizedString("Other", comment: "Feature option in the store creation features question.")
        }
    }
}
