import Foundation

enum ShippingLabelHazmatCategory: String, CaseIterable {
    case none
    case airEligibleEthanol
    case class1
    case class3
    case class4
    case class5
    case class6
    case class7
    case class8Corrosive
    case class8WetBattery
    case class9NewLithiumIndividual
    case class9usedLithium
    case class9newLithiumDevice
    case class9DryIce
    case class9UnmarkedLithium
    case class9Magnitized
    case division41
    case division51
    case division52
    case division61
    case division62
    case exceptedQuantityProvision
    case groundOnly
    case id8000
    case lighters
    case limitedQuantity
    case smallQuantityProvision
    
    var localizedName: String {
        ""
    }
}

extension ShippingLabelHazmatCategory {
    enum Localization {
        
    }
}
