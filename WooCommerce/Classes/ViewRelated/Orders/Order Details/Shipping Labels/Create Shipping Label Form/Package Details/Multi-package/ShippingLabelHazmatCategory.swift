import Foundation

enum ShippingLabelHazmatCategory: String, CaseIterable {
    case none
    case airEligibleEthanol = "AIR_ELIGIBLE_ETHANOL"
    case class1 = "CLASS_1"
    case class3 = "CLASS_3"
    case class4 = "CLASS_4"
    case class5 = "CLASS_5"
    case class6 = "CLASS_6"
    case class7 = "CLASS_7"
    case class8Corrosive = "CLASS_8_CORROSIVE"
    case class8WetBattery = "CLASS_8_WET_BATTERY"
    case class9NewLithiumIndividual = "CLASS_9_NEW_LITHIUM_INDIVIDUAL"
    case class9UsedLithium = "CLASS_9_USED_LITHIUM"
    case class9newLithiumDevice = "CLASS_9_NEW_LITHIUM_DEVICE"
    case class9DryIce = "CLASS_9_DRY_ICE"
    case class9UnmarkedLithium = "CLASS_9_UNMARKED_LITHIUM"
    case class9Magnitized = "CLASS_9_MAGNETIZED"
    case division41 = "DIVISION_4_1"
    case division51 = "DIVISION_5_1"
    case division52 = "DIVISION_5_2"
    case division61 = "DIVISION_6_1"
    case division62 = "DIVISION_6_2"
    case exceptedQuantityProvision = "EXCEPTED_QUANTITY_PROVISION"
    case groundOnly = "GROUND_ONLY"
    case id8000 = "ID8000"
    case lighters = "LIGHTERS"
    case limitedQuantity = "LIMITED_QUANTITY"
    case smallQuantityProvision = "SMALL_QUANTITY_PROVISION"

    var localizedName: String {
        switch self {
        case .none:
            return Localization.selectCategory
        case .airEligibleEthanol:
            return Localization.airEligibleEthanol
        case .class1:
            return Localization.class1
        case .class3:
            return Localization.class3
        case .class4:
            return Localization.class4
        case .class5:
            return Localization.class5
        case .class6:
            return Localization.class6
        case .class7:
            return Localization.class7
        case .class8Corrosive:
            return Localization.class8Corrosive
        case .class8WetBattery:
            return Localization.class8Wetbattery
        case .class9NewLithiumIndividual:
            return Localization.class9NewLithiumIndividual
        case .class9UsedLithium:
            return Localization.class9UsedLithium
        case .class9newLithiumDevice:
            return Localization.class9newLithiumDevice
        case .class9DryIce:
            return Localization.class9DryIce
        case .class9UnmarkedLithium:
            return Localization.class9UnmarkedLithium
        case .class9Magnitized:
            return Localization.class9Magnitized
        case .division41:
            return Localization.division41
        case .division51:
            return Localization.division51
        case .division52:
            return Localization.division52
        case .division61:
            return Localization.division61
        case .division62:
            return Localization.division62
        case .exceptedQuantityProvision:
            return Localization.exceptedQuantityProvision
        case .groundOnly:
            return Localization.groundOnly
        case .id8000:
            return Localization.id8000
        case .lighters:
            return Localization.lighters
        case .limitedQuantity:
            return Localization.limitedQuantity
        case .smallQuantityProvision:
            return Localization.smallQuantityProvision
        }
    }
}

extension ShippingLabelHazmatCategory {
    enum Localization {
        static let selectCategory = NSLocalizedString("Select a category", comment: "Title of the Hazmat category selection list")
        static let airEligibleEthanol = NSLocalizedString("Air Eligible Ethanol Package - (authorized fragrance and hand sanitizer shipments)",
                                                          comment: "A hazardous material description stating when a package can fit into this category")
        static let class1 = NSLocalizedString("Class 1 – Toy Propellant/Safety Fuse Package",
                                              comment: "A hazardous material description stating when a package can fit into this category")
        static let class3 = NSLocalizedString("Class 3 - Package (Hand sanitizer, rubbing alcohol, ethanol base products, flammable liquids etc.)",
                                              comment: "A hazardous material description stating when a package can fit into this category")
        static let class4 = NSLocalizedString("Class 4 - Package (Flammable solids)",
                                              comment: "A hazardous material description stating when a package can fit into this category")
        static let class5 = NSLocalizedString("Class 5 - Package (Oxidizers)",
                                              comment: "A hazardous material description stating when a package can fit into this category")
        static let class6 = NSLocalizedString("Class 6 - Package (Poisonous materials)",
                                              comment: "A hazardous material description stating when a package can fit into this category")
        static let class7 = NSLocalizedString("Class 7 – Radioactive Materials Package (e.g., smoke detectors, minerals, gun sights, etc.)",
                                              comment: "A hazardous material description stating when a package can fit into this category")
        static let class8Corrosive = NSLocalizedString("Class 8 – Corrosive Materials Package - Air Eligible Corrosive Materials (certain cleaning or " +
                                                       "tree/weed killing compounds, etc.)",
                                                       comment: "A hazardous material description stating when a package can fit into this category")
        static let class8Wetbattery = NSLocalizedString("Class 8 – Nonspillable Wet Battery Package - Sealed lead acid batteries",
                                                        comment: "A hazardous material description stating when a package can fit into this category")
        static let class9NewLithiumIndividual = NSLocalizedString("Class 9 - Lithium Battery Marked – Ground Only Package - New Individual or spare lithium " +
                                                                  "batteries (marked UN3480 or UN3090)",
                                                                  comment: "A hazardous material description stating when a " +
                                                                  "package can fit into this category")
        static let class9UsedLithium = NSLocalizedString("Class 9 - Lithium Battery – Returns Package - Used electronic devices containing or packaged with " +
                                                         "lithium batteries (markings required)",
                                                         comment: "A hazardous material description stating when a package can fit into this category")
        static let class9newLithiumDevice = NSLocalizedString("Class 9 - Lithium batteries, marked package - New electronic devices packaged with lithium " +
                                                              "batteries (marked UN3481 or UN3091)",
                                                              comment: "A hazardous material description stating when a package can fit into this category")
        static let class9DryIce = NSLocalizedString("Class 9 – Dry Ice Package (limited to 5 lbs. if shipped via Air)",
                                                    comment: "A hazardous material description stating when a package can fit into this category")
        static let class9UnmarkedLithium = NSLocalizedString("Class 9 – Lithium batteries, unmarked package - New electronic devices installed or packaged " +
                                                             "with lithium batteries (no marking)",
                                                             comment: "A hazardous material description stating when a package can fit into this category")
        static let class9Magnitized = NSLocalizedString("Class 9 – Magnetized Materials Package",
                                                        comment: "A hazardous material description stating when a package can fit into this category")
        static let division41 = NSLocalizedString("Division 4.1 – Mailable flammable solids and Safety Matches Package - Safety/strike on box matches, " +
                                                  "book matches, mailable flammable solids",
                                                  comment: "A hazardous material description stating when a package can fit into this category")
        // Note: We're specifically using the `FULLWIDTH PERCENT SIGN` (U+FF05) character instead of the regular`%`
        // To avoid issues with our string linter detecting a false positive of this string having a `% c` placeholder in it
        // See https://github.com/woocommerce/woocommerce-ios/pull/5580
        // See p8Qyks-2co-p2#comment-753
        // See p1641398973203300-slack-C02AED43D
        // See p1694580825965539-slack-C02KLTL3MKM
        static let division51 = NSLocalizedString("Division 5.1 – Oxidizers Package - Hydrogen peroxide (8 to 20％ concentration)",
                                                  comment: "A hazardous material description stating when a package can fit into this category")
        static let division52 = NSLocalizedString("Division 5.2 – Organic Peroxides Package",
                                                  comment: "A hazardous material description stating when a package can fit into this category")
        static let division61 = NSLocalizedString("Division 6.1 – Toxic Materials Package (with an LD50 of 50 mg/kg or less) - (pesticides, herbicides, etc.)",
                                                  comment: "A hazardous material description stating when a package can fit into this category")
        static let division62 = NSLocalizedString("Division 6.2 - Hazardous Materials - Biological Materials (e.g., lab test kits, authorized COVID test " +
                                                  "kit returns)",
                                                  comment: "A hazardous material description stating when a package can fit into this category")
        static let exceptedQuantityProvision = NSLocalizedString("Excepted Quantity Provision Package (e.g., small volumes of flammable liquids, corrosive, " +
                                                                 "toxic or environmentally hazardous materials - marking required)",
                                                                 comment: "A hazardous material description stating when a package can fit into this category")
        static let groundOnly = NSLocalizedString("Ground Only Hazardous Materials (For items that are not listed, but are restricted to surface only)",
                                                  comment: "A hazardous material description stating when a package can fit into this category")
        static let id8000 = NSLocalizedString("ID8000 Consumer Commodity Package - Air Eligible ID8000 Consumer Commodity (Non-flammableaerosols, Flammable " +
                                              "combustible liquids, Toxic Substance, Miscellaneious hazardous materials)",
                                              comment: "A hazardous material description stating when a package can fit into this category")
        static let lighters = NSLocalizedString("Lighters Package - Authorized Lighters",
                                                comment: "A hazardous material description stating when a package can fit into this category")
        // NSLocalizedStrings that are longer than 255 characters need a separate "key" value due to GlotPress's key character limit
        static let limitedQuantity = NSLocalizedString("limited_quantity_category",
                                                       value: "LTD QTY Ground Package - Aerosols, spray disinfectants, spray paint, hair spray, propane, " +
                                                       "butane, cleaning products, etc. - Fragrances, nail polish, nail polish remover, solvents, " +
                                                       "hand sanitizer, rubbing alcohol, ethanol base products, etc. - Other limited quantity surface " +
                                                       "materials (cosmetics, cleaning products, paints, etc.)",
                                                       comment: "A hazardous material description stating when a package can fit into this category")
        static let smallQuantityProvision = NSLocalizedString("Small Quantity Provision Package (markings required)",
                                                              comment: "A hazardous material description stating when a package can fit into this category")
    }
}
