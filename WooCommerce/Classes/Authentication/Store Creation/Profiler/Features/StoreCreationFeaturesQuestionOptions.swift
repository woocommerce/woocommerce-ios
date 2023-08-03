import Foundation

extension StoreCreationFeaturesQuestionViewModel {
    // TODO: 10386 Align with Android and send these via tracks
    enum Feature: String, CaseIterable {
        case salesAndAnalyticsReports
        case productManagementAndInventoryTracking
        case flexibleAndSecurePaymentOptions
        case inPersonPayment
        case abilityToScaleAsBusinessGrows
        case customisationOptionForStoreDesign
        case wideRangeOfPluginsAndExtensions
        case others
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
        case .customisationOptionForStoreDesign:
            return NSLocalizedString("Customization options for my store design", comment: "Feature option in the store creation features question.")
        case .wideRangeOfPluginsAndExtensions:
            return NSLocalizedString("Access to a wide range of plugins and extensions", comment: "Feature option in the store creation features question.")
        case .others:
            return NSLocalizedString("Others", comment: "Feature option in the store creation features question.")
        }
    }
}
