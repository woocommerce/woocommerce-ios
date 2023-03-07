import Foundation

extension StoreCreationCategoryQuestionViewModel {
    /// Industry options for a WooCommerce store. The raw value is the value that is sent to the submission API.
    /// The sources of truth are at:
    /// - Stripe industries: https://support.stripe.com/questions/setting-an-industry-group-when-creating-a-stripe-account
    /// - WC industry options: https://github.com/Automattic/woocommerce.com/blob/trunk/themes/woo/start/config/options.json
    enum Category: String, Equatable {
        case boatSales = "boat_sales"
        case carWashes = "car_washes"
        case fuelDispensers = "fuel_dispensers"
        case towingServices = "towing_services"
        case truckStop = "truck_stop"
        case aCAndHeatingContractors = "a_c_and_heating_contractors"
        case carpentryContractors = "carpentry_contractors"
        case electricalContractors = "electrical_contractors"
        case generalContractors = "general_contractors"
        case otherBuildingServices = "other_building_services"
        case specialTradeContractors = "special_trade_contractors"
        case telecomEquipment = "telecom_equipment"
        case telecomServices = "telecom_services"
        case apps = "apps"
        case blogsAndWrittenContent = "blogs_and_written_content"
        case books = "books"
        case games = "games"
        case musicOrOtherMedia = "music_or_other_media"
        case otherDigitalGoods = "other_digital_goods"
        case softwareAsAService = "software_as_a_service"
        case businessAndSecretarialSchools = "business_and_secretarial_schools"
        case childCareServices = "child_care_services"
        case collegesOrUniversities = "colleges_or_universities"
        case elementaryOrSecondarySchools = "elementary_or_secondary_schools"
        case otherEducationalServices = "other_educational_services"
        case vocationalSchoolsAndTradeSchools = "vocational_schools_and_trade_schools"
        case amusementParksCarnivalsOrCircuses = "amusement_parks,_carnivals,_or_circuses"
        case bettingOrFantasySports = "betting_or_fantasy_sports"
        case eventTicketing = "event_ticketing"
        case fortuneTellers = "fortune_tellers"
        case lotteries = "lotteries"
        case movieTheaters = "movie_theaters"
        case musiciansBandsOrOrchestras = "musicians,_bands,_or_orchestras"
        case onlineGambling = "online_gambling"
        case otherEntertainmentAndRecreation = "other_entertainment_and_recreation"
        case recreationalCamps = "recreational_camps"
        case sportsForecastingOrPredictionServices = "sports_forecasting_or_prediction_services"
        case touristAttractions = "tourist_attractions"
        case checkCashing = "check_cashing"
        case collectionsAgencies = "collections_agencies"
        case cryptocurrencies = "cryptocurrencies"
        case currencyExchanges = "currency_exchanges"
        case digitalWallets = "digital_wallets"
        case financialInformationAndResearch = "financial_information_and_research"
        case insurance = "insurance"
        case investmentServices = "investment_services"
        case loansOrLending = "loans_or_lending"
        case moneyOrders = "money_orders"
        case moneyServicesOrTransmission = "money_services_or_transmission"
        case otherFinancialInstitutions = "other_financial_institutions"
        case personalFundraisingOrCrowdfunding = "personal_fundraising_or_crowdfunding"
        case securityBrokersOrDealers = "security_brokers_or_dealers"
        case virtualCurrencies = "virtual_currencies"
        case wireTransfers = "wire_transfers"
        case barsAndNightclubs = "bars_and_nightclubs"
        case caterers = "caterers"
        case fastFoodRestaurants = "fast_food_restaurants"
        case groceryStores = "grocery_stores"
        case otherFoodAndDining = "other_food_and_dining"
        case restaurantsAndNightlife = "restaurants_and_nightlife"
        case assistedLiving = "assisted_living"
        case chiropractors = "chiropractors"
        case dentistsAndOrthodontists = "dentists_and_orthodontists"
        case doctorsAndPhysicians = "doctors_and_physicians"
        case healthAndWellnessCoaching = "health_and_wellness_coaching"
        case hospitals = "hospitals"
        case medicalDevices = "medical_devices"
        case medicalLaboratories = "medical_laboratories"
        case medicalOrganizations = "medical_organizations"
        case mentalHealthServices = "mental_health_services"
        case nursingOrPersonalCareFacilities = "nursing_or_personal_care_facilities"
        case opticiansAndEyeglasses = "opticians_and_eyeglasses"
        case optometristsAndOphthalmologists = "optometrists_and_ophthalmologists"
        case osteopaths = "osteopaths"
        case otherMedicalServices = "other_medical_services"
        case podiatristsAndChiropodists = "podiatrists_and_chiropodists"
        case telemedicineAndTelehealth = "telemedicine_and_telehealth"
        case veterinaryServices = "veterinary_services"
        case charitiesOrSocialServiceOrganizations = "charities_or_social_service_organizations"
        case civicFraternalOrSocialAssociations = "civic,_fraternal,_or_social_associations"
        case countryClubs = "country_clubs"
        case otherMembershipOrganizations = "other_membership_organizations"
        case politicalOrganizations = "political_organizations"
        case religiousOrganizations = "religious_organizations"
        case counselingServices = "counseling_services"
        case datingServices = "dating_services"
        case funeralServices = "funeral_services"
        case healthAndBeautySpas = "health_and_beauty_spas"
        case landscapingServices = "landscaping_services"
        case laundryOrCleaningServices = "laundry_or_cleaning_services"
        case massageParlors = "massage_parlors"
        case otherPersonalServices = "other_personal_services"
        case photographyStudios = "photography_studios"
        case salonsOrBarbers = "salons_or_barbers"
        case accountingAuditingOrTaxPrep = "accounting,_auditing,_or_tax_prep"
        case attorneysAndLawyers = "attorneys_and_lawyers"
        case autoServices = "auto_services"
        case bailBonds = "bail_bonds"
        case bankruptcyServices = "bankruptcy_services"
        case carRentals = "car_rentals"
        case carSales = "car_sales"
        case computerRepair = "computer_repair"
        case consulting = "consulting"
        case creditCounselingOrCreditRepair = "credit_counseling_or_credit_repair"
        case debtReductionServices = "debt_reduction_services"
        case digitalMarketing = "digital_marketing"
        case employmentAgencies = "employment_agencies"
        case governmentServices = "government_services"
        case leadGeneration = "lead_generation"
        case mortgageConsultingServices = "mortgage_consulting_services"
        case otherBusinessServices = "other_business_services"
        case otherMarketingServices = "other_marketing_services"
        case printingAndPublishing = "printing_and_publishing"
        case protectiveOrSecurityServices = "protective_or_security_services"
        case telemarketing = "telemarketing"
        case testingLaboratories = "testing_laboratories"
        case utilities = "utilities"
        case warrantyServices = "warranty_services"
        case accessoriesForTobaccoAndMarijuana = "accessories_for_tobacco_and_marijuana"
        case adultContentOrServices = "adult_content_or_services"
        case alcohol = "alcohol"
        case marijuanaDispensaries = "marijuana_dispensaries"
        case marijuanaRelatedProducts = "marijuana_related_products"
        case pharmaciesOrPharmaceuticals = "pharmacies_or_pharmaceuticals"
        case supplementsOrNutraceuticals = "supplements_or_nutraceuticals"
        case tobaccoOrCigars = "tobacco_or_cigars"
        case vapesECigarettesEJuiceOrRelatedProducts = "vapes,_e_cigarettes,_e_juice_or_related_products"
        case weaponsOrMunitions = "weapons_or_munitions"
        case accessories = "accessories"
        case antiques = "antiques"
        case autoPartsAndAccessories = "auto_parts_and_accessories"
        case beautyProducts = "beauty_products"
        case clothingAndAccessories = "clothing_and_accessories"
        case convenienceStores = "convenience_stores"
        case designerProducts = "designer_products"
        case flowers = "flowers"
        case hardwareStores = "hardware_stores"
        case homeElectronics = "home_electronics"
        case homeGoodsAndFurniture = "home_goods_and_furniture"
        case otherMerchandise = "other_merchandise"
        case shoes = "shoes"
        case software = "software"
        case airlinesAndAirCarriers = "airlines_and_air_carriers"
        case commuterTransportation = "commuter_transportation"
        case courierServices = "courier_services"
        case cruiseLines = "cruise_lines"
        case freightForwarders = "freight_forwarders"
        case otherTransportationServices = "other_transportation_services"
        case parkingLots = "parking_lots"
        case ridesharing = "ridesharing"
        case shippingOrForwarding = "shipping_or_forwarding"
        case taxisAndLimos = "taxis_and_limos"
        case travelAgencies = "travel_agencies"
        case hotelsInnsOrMotels = "hotels,_inns,_or_motels"
        case otherTravelLeisure = "other_travel_leisure"
        case propertyRentals = "property_rentals"
        case timeshares = "timeshares"
        case trailerParksAndCampgrounds = "trailer_parks_and_campgrounds"
    }

    /// Industry group of categories (industries). The sources of truth are at:
    /// - Stripe industries: https://support.stripe.com/questions/setting-an-industry-group-when-creating-a-stripe-account
    /// - WC industry options: https://github.com/Automattic/woocommerce.com/blob/trunk/themes/woo/start/config/options.json
    enum CategoryGroup: String, Equatable {
        case automotive
        case constructionIndustrial = "construction_industrial"
        case digitalProducts = "digital_products"
        case educationLearning = "education_learning"
        case entertainmentAndRecreation = "entertainment_and_recreation"
        case financialServices = "financial_services"
        case foodDrink = "food_drink"
        case medicalServices = "medical_services"
        case membershipOrganizations = "membership_organizations"
        case personalServices = "personal_services"
        case professionalServices = "professional_services"
        case regulatedAndAgeRestrictedProducts = "regulated_and_age_restricted_products"
        case retail
        case transportation
        case travelLeisure = "travel_leisure"
    }

    struct CategorySection: Hashable {
        let group: CategoryGroup
        let categories: [Category]
    }

    var categorySections: [CategorySection] {
        categoriesByGroup.map { CategorySection(group: $0.key, categories: $0.value) }
            .sorted(by: { $0.group.name < $1.group.name })
    }

    private var categoriesByGroup: [CategoryGroup: [Category]] {
        [
            .regulatedAndAgeRestrictedProducts: [
                .accessoriesForTobaccoAndMarijuana,
                .adultContentOrServices,
                .alcohol,
                .marijuanaDispensaries,
                .marijuanaRelatedProducts,
                .pharmaciesOrPharmaceuticals,
                .supplementsOrNutraceuticals,
                .tobaccoOrCigars,
                .vapesECigarettesEJuiceOrRelatedProducts,
                .weaponsOrMunitions
            ],
            .professionalServices: [
                .accountingAuditingOrTaxPrep,
                .attorneysAndLawyers,
                .autoServices,
                .bailBonds,
                .bankruptcyServices,
                .carRentals,
                .carSales,
                .computerRepair,
                .consulting,
                .creditCounselingOrCreditRepair,
                .debtReductionServices,
                .digitalMarketing,
                .employmentAgencies,
                .governmentServices,
                .leadGeneration,
                .mortgageConsultingServices,
                .otherBusinessServices,
                .otherMarketingServices,
                .printingAndPublishing,
                .protectiveOrSecurityServices,
                .telemarketing,
                .testingLaboratories,
                .utilities,
                .warrantyServices
            ],
            .personalServices: [
                .counselingServices,
                .datingServices,
                .funeralServices,
                .healthAndBeautySpas,
                .landscapingServices,
                .laundryOrCleaningServices,
                .massageParlors,
                .otherPersonalServices,
                .photographyStudios,
                .salonsOrBarbers
            ],
            .constructionIndustrial: [
                .aCAndHeatingContractors,
                .carpentryContractors,
                .electricalContractors,
                .generalContractors,
                .otherBuildingServices,
                .specialTradeContractors,
                .telecomEquipment,
                .telecomServices
            ],
            .medicalServices: [
                .assistedLiving,
                .chiropractors,
                .dentistsAndOrthodontists,
                .doctorsAndPhysicians,
                .healthAndWellnessCoaching,
                .hospitals,
                .medicalDevices,
                .medicalLaboratories,
                .medicalOrganizations,
                .mentalHealthServices,
                .nursingOrPersonalCareFacilities,
                .opticiansAndEyeglasses,
                .optometristsAndOphthalmologists,
                .osteopaths,
                .otherMedicalServices,
                .podiatristsAndChiropodists,
                .telemedicineAndTelehealth,
                .veterinaryServices
            ],
            .transportation: [
                .airlinesAndAirCarriers,
                .commuterTransportation,
                .courierServices,
                .cruiseLines,
                .freightForwarders,
                .otherTransportationServices,
                .parkingLots,
                .ridesharing,
                .shippingOrForwarding,
                .taxisAndLimos,
                .travelAgencies
            ],
            .membershipOrganizations: [
                .charitiesOrSocialServiceOrganizations,
                .civicFraternalOrSocialAssociations,
                .countryClubs,
                .otherMembershipOrganizations,
                .politicalOrganizations,
                .religiousOrganizations
            ],
            .foodDrink: [
                .barsAndNightclubs,
                .caterers,
                .fastFoodRestaurants,
                .groceryStores,
                .otherFoodAndDining,
                .restaurantsAndNightlife
            ],
            .travelLeisure: [
                .hotelsInnsOrMotels,
                .otherTravelLeisure,
                .propertyRentals,
                .timeshares,
                .trailerParksAndCampgrounds
            ],
            .digitalProducts: [
                .apps,
                .blogsAndWrittenContent,
                .books,
                .games,
                .musicOrOtherMedia,
                .otherDigitalGoods,
                .softwareAsAService
            ],
            .educationLearning: [
                .businessAndSecretarialSchools,
                .childCareServices,
                .collegesOrUniversities,
                .elementaryOrSecondarySchools,
                .otherEducationalServices,
                .vocationalSchoolsAndTradeSchools
            ],
            .retail: [
                .accessories,
                .antiques,
                .autoPartsAndAccessories,
                .beautyProducts,
                .clothingAndAccessories,
                .convenienceStores,
                .designerProducts,
                .flowers,
                .hardwareStores,
                .homeElectronics,
                .homeGoodsAndFurniture,
                .otherMerchandise,
                .shoes,
                .software
            ],
            .financialServices: [
                .checkCashing,
                .collectionsAgencies,
                .cryptocurrencies,
                .currencyExchanges,
                .digitalWallets,
                .financialInformationAndResearch,
                .insurance,
                .investmentServices,
                .loansOrLending,
                .moneyOrders,
                .moneyServicesOrTransmission,
                .otherFinancialInstitutions,
                .personalFundraisingOrCrowdfunding,
                .securityBrokersOrDealers,
                .virtualCurrencies,
                .wireTransfers
            ],
            .entertainmentAndRecreation: [
                .amusementParksCarnivalsOrCircuses,
                .bettingOrFantasySports,
                .eventTicketing,
                .fortuneTellers,
                .lotteries,
                .movieTheaters,
                .musiciansBandsOrOrchestras,
                .onlineGambling,
                .otherEntertainmentAndRecreation,
                .recreationalCamps,
                .sportsForecastingOrPredictionServices,
                .touristAttractions
            ],
            .automotive: [
                .boatSales,
                .carWashes,
                .fuelDispensers,
                .towingServices,
                .truckStop
            ]
        ]
    }
}

extension StoreCreationCategoryQuestionViewModel.Category {
    var name: String {
        switch self {
        case .boatSales:
            return NSLocalizedString("Boat Sales", comment: "Industry option in the store creation category question.")
        case .carWashes:
            return NSLocalizedString("Car Washes", comment: "Industry option in the store creation category question.")
        case .fuelDispensers:
            return NSLocalizedString("Fuel Dispensers", comment: "Industry option in the store creation category question.")
        case .towingServices:
            return NSLocalizedString("Towing Services", comment: "Industry option in the store creation category question.")
        case .truckStop:
            return NSLocalizedString("Truck Stop", comment: "Industry option in the store creation category question.")
        case .aCAndHeatingContractors:
            return NSLocalizedString("A C And Heating Contractors", comment: "Industry option in the store creation category question.")
        case .carpentryContractors:
            return NSLocalizedString("Carpentry Contractors", comment: "Industry option in the store creation category question.")
        case .electricalContractors:
            return NSLocalizedString("Electrical Contractors", comment: "Industry option in the store creation category question.")
        case .generalContractors:
            return NSLocalizedString("General Contractors", comment: "Industry option in the store creation category question.")
        case .otherBuildingServices:
            return NSLocalizedString("Other Building Services", comment: "Industry option in the store creation category question.")
        case .specialTradeContractors:
            return NSLocalizedString("Special Trade Contractors", comment: "Industry option in the store creation category question.")
        case .telecomEquipment:
            return NSLocalizedString("Telecom Equipment", comment: "Industry option in the store creation category question.")
        case .telecomServices:
            return NSLocalizedString("Telecom Services", comment: "Industry option in the store creation category question.")
        case .apps:
            return NSLocalizedString("Apps", comment: "Industry option in the store creation category question.")
        case .blogsAndWrittenContent:
            return NSLocalizedString("Blogs And Written Content", comment: "Industry option in the store creation category question.")
        case .books:
            return NSLocalizedString("Books", comment: "Industry option in the store creation category question.")
        case .games:
            return NSLocalizedString("Games", comment: "Industry option in the store creation category question.")
        case .musicOrOtherMedia:
            return NSLocalizedString("Music Or Other Media", comment: "Industry option in the store creation category question.")
        case .otherDigitalGoods:
            return NSLocalizedString("Other Digital Goods", comment: "Industry option in the store creation category question.")
        case .softwareAsAService:
            return NSLocalizedString("Software As A Service", comment: "Industry option in the store creation category question.")
        case .businessAndSecretarialSchools:
            return NSLocalizedString("Business And Secretarial Schools", comment: "Industry option in the store creation category question.")
        case .childCareServices:
            return NSLocalizedString("Child Care Services", comment: "Industry option in the store creation category question.")
        case .collegesOrUniversities:
            return NSLocalizedString("Colleges Or Universities", comment: "Industry option in the store creation category question.")
        case .elementaryOrSecondarySchools:
            return NSLocalizedString("Elementary Or Secondary Schools", comment: "Industry option in the store creation category question.")
        case .otherEducationalServices:
            return NSLocalizedString("Educational Services", comment: "Industry option in the store creation category question.")
        case .vocationalSchoolsAndTradeSchools:
            return NSLocalizedString("Vocational Schools And Trade Schools", comment: "Industry option in the store creation category question.")
        case .amusementParksCarnivalsOrCircuses:
            return NSLocalizedString("Amusement Parks, Carnivals, Or Circuses", comment: "Industry option in the store creation category question.")
        case .bettingOrFantasySports:
            return NSLocalizedString("Betting Or Fantasy Sports", comment: "Industry option in the store creation category question.")
        case .eventTicketing:
            return NSLocalizedString("Event Ticketing", comment: "Industry option in the store creation category question.")
        case .fortuneTellers:
            return NSLocalizedString("Fortune Tellers", comment: "Industry option in the store creation category question.")
        case .lotteries:
            return NSLocalizedString("Lotteries", comment: "Industry option in the store creation category question.")
        case .movieTheaters:
            return NSLocalizedString("Movie Theaters", comment: "Industry option in the store creation category question.")
        case .musiciansBandsOrOrchestras:
            return NSLocalizedString("Musicians, Bands, Or Orchestras", comment: "Industry option in the store creation category question.")
        case .onlineGambling:
            return NSLocalizedString("Online Gambling", comment: "Industry option in the store creation category question.")
        case .otherEntertainmentAndRecreation:
            return NSLocalizedString("Other Entertainment And Recreation", comment: "Industry option in the store creation category question.")
        case .recreationalCamps:
            return NSLocalizedString("Recreational Camps", comment: "Industry option in the store creation category question.")
        case .sportsForecastingOrPredictionServices:
            return NSLocalizedString("Sports Forecasting Or Prediction Services", comment: "Industry option in the store creation category question.")
        case .touristAttractions:
            return NSLocalizedString("Tourist Attractions", comment: "Industry option in the store creation category question.")
        case .checkCashing:
            return NSLocalizedString("Check Cashing", comment: "Industry option in the store creation category question.")
        case .collectionsAgencies:
            return NSLocalizedString("Collections Agencies", comment: "Industry option in the store creation category question.")
        case .cryptocurrencies:
            return NSLocalizedString("Cryptocurrencies", comment: "Industry option in the store creation category question.")
        case .currencyExchanges:
            return NSLocalizedString("Currency Exchanges", comment: "Industry option in the store creation category question.")
        case .digitalWallets:
            return NSLocalizedString("Digital Wallets", comment: "Industry option in the store creation category question.")
        case .financialInformationAndResearch:
            return NSLocalizedString("Financial Information And Research", comment: "Industry option in the store creation category question.")
        case .insurance:
            return NSLocalizedString("Insurance", comment: "Industry option in the store creation category question.")
        case .investmentServices:
            return NSLocalizedString("Investment Services", comment: "Industry option in the store creation category question.")
        case .loansOrLending:
            return NSLocalizedString("Loans Or Lending", comment: "Industry option in the store creation category question.")
        case .moneyOrders:
            return NSLocalizedString("Money Orders", comment: "Industry option in the store creation category question.")
        case .moneyServicesOrTransmission:
            return NSLocalizedString("Money Services Or Transmission", comment: "Industry option in the store creation category question.")
        case .otherFinancialInstitutions:
            return NSLocalizedString("Other Financial Institutions", comment: "Industry option in the store creation category question.")
        case .personalFundraisingOrCrowdfunding:
            return NSLocalizedString("Personal Fundraising Or Crowdfunding", comment: "Industry option in the store creation category question.")
        case .securityBrokersOrDealers:
            return NSLocalizedString("Security Brokers Or Dealers", comment: "Industry option in the store creation category question.")
        case .virtualCurrencies:
            return NSLocalizedString("Virtual Currencies", comment: "Industry option in the store creation category question.")
        case .wireTransfers:
            return NSLocalizedString("Wire Transfers", comment: "Industry option in the store creation category question.")
        case .barsAndNightclubs:
            return NSLocalizedString("Bars And Nightclubs", comment: "Industry option in the store creation category question.")
        case .caterers:
            return NSLocalizedString("Caterers", comment: "Industry option in the store creation category question.")
        case .fastFoodRestaurants:
            return NSLocalizedString("Fast Food Restaurants", comment: "Industry option in the store creation category question.")
        case .groceryStores:
            return NSLocalizedString("Grocery Stores", comment: "Industry option in the store creation category question.")
        case .otherFoodAndDining:
            return NSLocalizedString("Other Food And Dining", comment: "Industry option in the store creation category question.")
        case .restaurantsAndNightlife:
            return NSLocalizedString("Restaurants And Nightlife", comment: "Industry option in the store creation category question.")
        case .assistedLiving:
            return NSLocalizedString("Assisted Living", comment: "Industry option in the store creation category question.")
        case .chiropractors:
            return NSLocalizedString("Chiropractors", comment: "Industry option in the store creation category question.")
        case .dentistsAndOrthodontists:
            return NSLocalizedString("Dentists And Orthodontists", comment: "Industry option in the store creation category question.")
        case .doctorsAndPhysicians:
            return NSLocalizedString("Doctors And Physicians", comment: "Industry option in the store creation category question.")
        case .healthAndWellnessCoaching:
            return NSLocalizedString("Health And Wellness Coaching", comment: "Industry option in the store creation category question.")
        case .hospitals:
            return NSLocalizedString("Hospitals", comment: "Industry option in the store creation category question.")
        case .medicalDevices:
            return NSLocalizedString("Medical Devices", comment: "Industry option in the store creation category question.")
        case .medicalLaboratories:
            return NSLocalizedString("Medical Laboratories", comment: "Industry option in the store creation category question.")
        case .medicalOrganizations:
            return NSLocalizedString("Medical Organizations", comment: "Industry option in the store creation category question.")
        case .mentalHealthServices:
            return NSLocalizedString("Mental Health Services", comment: "Industry option in the store creation category question.")
        case .nursingOrPersonalCareFacilities:
            return NSLocalizedString("Nursing Or Personal Care Facilities", comment: "Industry option in the store creation category question.")
        case .opticiansAndEyeglasses:
            return NSLocalizedString("Opticians And Eyeglasses", comment: "Industry option in the store creation category question.")
        case .optometristsAndOphthalmologists:
            return NSLocalizedString("Optometrists and Ophthalmologists", comment: "Industry option in the store creation category question.")
        case .osteopaths:
            return NSLocalizedString("Osteopaths", comment: "Industry option in the store creation category question.")
        case .otherMedicalServices:
            return NSLocalizedString("Other Medical Services", comment: "Industry option in the store creation category question.")
        case .podiatristsAndChiropodists:
            return NSLocalizedString("Podiatrists and Chiropodists", comment: "Industry option in the store creation category question.")
        case .telemedicineAndTelehealth:
            return NSLocalizedString("Telemedicine And Telehealth", comment: "Industry option in the store creation category question.")
        case .veterinaryServices:
            return NSLocalizedString("Veterinary Services", comment: "Industry option in the store creation category question.")
        case .charitiesOrSocialServiceOrganizations:
            return NSLocalizedString("Charities Or Social Service Organizations", comment: "Industry option in the store creation category question.")
        case .civicFraternalOrSocialAssociations:
            return NSLocalizedString("Civic, Fraternal, Or Social Associations", comment: "Industry option in the store creation category question.")
        case .countryClubs:
            return NSLocalizedString("Country Clubs", comment: "Industry option in the store creation category question.")
        case .otherMembershipOrganizations:
            return NSLocalizedString("Other Membership Organizations", comment: "Industry option in the store creation category question.")
        case .politicalOrganizations:
            return NSLocalizedString("Political Organizations", comment: "Industry option in the store creation category question.")
        case .religiousOrganizations:
            return NSLocalizedString("Religious Organizations", comment: "Industry option in the store creation category question.")
        case .counselingServices:
            return NSLocalizedString("Counseling Services", comment: "Industry option in the store creation category question.")
        case .datingServices:
            return NSLocalizedString("Dating Services", comment: "Industry option in the store creation category question.")
        case .funeralServices:
            return NSLocalizedString("Funeral Services", comment: "Industry option in the store creation category question.")
        case .healthAndBeautySpas:
            return NSLocalizedString("Health And Beauty Spas", comment: "Industry option in the store creation category question.")
        case .landscapingServices:
            return NSLocalizedString("Landscaping Services", comment: "Industry option in the store creation category question.")
        case .laundryOrCleaningServices:
            return NSLocalizedString("Laundry Or Cleaning Services", comment: "Industry option in the store creation category question.")
        case .massageParlors:
            return NSLocalizedString("Massage Parlors", comment: "Industry option in the store creation category question.")
        case .otherPersonalServices:
            return NSLocalizedString("Other Personal Services", comment: "Industry option in the store creation category question.")
        case .photographyStudios:
            return NSLocalizedString("Photography Studios", comment: "Industry option in the store creation category question.")
        case .salonsOrBarbers:
            return NSLocalizedString("Salons Or Barbers", comment: "Industry option in the store creation category question.")
        case .accountingAuditingOrTaxPrep:
            return NSLocalizedString("Accounting, Auditing, Or Tax Prep", comment: "Industry option in the store creation category question.")
        case .attorneysAndLawyers:
            return NSLocalizedString("Attorneys And Lawyers", comment: "Industry option in the store creation category question.")
        case .autoServices:
            return NSLocalizedString("Auto Services", comment: "Industry option in the store creation category question.")
        case .bailBonds:
            return NSLocalizedString("Bail Bonds", comment: "Industry option in the store creation category question.")
        case .bankruptcyServices:
            return NSLocalizedString("Bankruptcy Services", comment: "Industry option in the store creation category question.")
        case .carRentals:
            return NSLocalizedString("Car Rentals", comment: "Industry option in the store creation category question.")
        case .carSales:
            return NSLocalizedString("Car Sales", comment: "Industry option in the store creation category question.")
        case .computerRepair:
            return NSLocalizedString("Computer Repair", comment: "Industry option in the store creation category question.")
        case .consulting:
            return NSLocalizedString("Consulting", comment: "Industry option in the store creation category question.")
        case .creditCounselingOrCreditRepair:
            return NSLocalizedString("Credit Counseling Or Credit Repair", comment: "Industry option in the store creation category question.")
        case .debtReductionServices:
            return NSLocalizedString("Debt Reduction Services", comment: "Industry option in the store creation category question.")
        case .digitalMarketing:
            return NSLocalizedString("Digital Marketing", comment: "Industry option in the store creation category question.")
        case .employmentAgencies:
            return NSLocalizedString("Employment Agencies", comment: "Industry option in the store creation category question.")
        case .governmentServices:
            return NSLocalizedString("Government Services", comment: "Industry option in the store creation category question.")
        case .leadGeneration:
            return NSLocalizedString("Lead Generation", comment: "Industry option in the store creation category question.")
        case .mortgageConsultingServices:
            return NSLocalizedString("Mortgage Consulting Services", comment: "Industry option in the store creation category question.")
        case .otherBusinessServices:
            return NSLocalizedString("Other Business Services", comment: "Industry option in the store creation category question.")
        case .otherMarketingServices:
            return NSLocalizedString("Other Marketing Services", comment: "Industry option in the store creation category question.")
        case .printingAndPublishing:
            return NSLocalizedString("Printing and Publishing", comment: "Industry option in the store creation category question.")
        case .protectiveOrSecurityServices:
            return NSLocalizedString("Protective Or Security Services", comment: "Industry option in the store creation category question.")
        case .telemarketing:
            return NSLocalizedString("Telemarketing", comment: "Industry option in the store creation category question.")
        case .testingLaboratories:
            return NSLocalizedString("Testing Laboratories", comment: "Industry option in the store creation category question.")
        case .utilities:
            return NSLocalizedString("Utilities", comment: "Industry option in the store creation category question.")
        case .warrantyServices:
            return NSLocalizedString("Warranty Services", comment: "Industry option in the store creation category question.")
        case .accessoriesForTobaccoAndMarijuana:
            return NSLocalizedString("Accessories For Tobacco And Marijuana", comment: "Industry option in the store creation category question.")
        case .adultContentOrServices:
            return NSLocalizedString("Adult Content Or Services", comment: "Industry option in the store creation category question.")
        case .alcohol:
            return NSLocalizedString("Alcohol", comment: "Industry option in the store creation category question.")
        case .marijuanaDispensaries:
            return NSLocalizedString("Marijuana Dispensaries", comment: "Industry option in the store creation category question.")
        case .marijuanaRelatedProducts:
            return NSLocalizedString("Marijuana-related Products", comment: "Industry option in the store creation category question.")
        case .pharmaciesOrPharmaceuticals:
            return NSLocalizedString("Pharmacies Or Pharmaceuticals", comment: "Industry option in the store creation category question.")
        case .supplementsOrNutraceuticals:
            return NSLocalizedString("Supplements Or Nutraceuticals", comment: "Industry option in the store creation category question.")
        case .tobaccoOrCigars:
            return NSLocalizedString("Tobacco Or Cigars", comment: "Industry option in the store creation category question.")
        case .vapesECigarettesEJuiceOrRelatedProducts:
            return NSLocalizedString("Vapes, E-cigarettes, E-juice Or Related Products", comment: "Industry option in the store creation category question.")
        case .weaponsOrMunitions:
            return NSLocalizedString("Weapons Or Munitions", comment: "Industry option in the store creation category question.")
        case .accessories:
            return NSLocalizedString("Accessories", comment: "Industry option in the store creation category question.")
        case .antiques:
            return NSLocalizedString("Antiques", comment: "Industry option in the store creation category question.")
        case .autoPartsAndAccessories:
            return NSLocalizedString("Auto Parts And Accessories", comment: "Industry option in the store creation category question.")
        case .beautyProducts:
            return NSLocalizedString("Beauty Products", comment: "Industry option in the store creation category question.")
        case .clothingAndAccessories:
            return NSLocalizedString("Clothing And Accessories", comment: "Industry option in the store creation category question.")
        case .convenienceStores:
            return NSLocalizedString("Convenience Stores", comment: "Industry option in the store creation category question.")
        case .designerProducts:
            return NSLocalizedString("Designer Products", comment: "Industry option in the store creation category question.")
        case .flowers:
            return NSLocalizedString("Flowers", comment: "Industry option in the store creation category question.")
        case .hardwareStores:
            return NSLocalizedString("Hardware Stores", comment: "Industry option in the store creation category question.")
        case .homeElectronics:
            return NSLocalizedString("Home Electronics", comment: "Industry option in the store creation category question.")
        case .homeGoodsAndFurniture:
            return NSLocalizedString("Home Goods And Furniture", comment: "Industry option in the store creation category question.")
        case .otherMerchandise:
            return NSLocalizedString("Other Merchandise", comment: "Industry option in the store creation category question.")
        case .shoes:
            return NSLocalizedString("Shoes", comment: "Industry option in the store creation category question.")
        case .software:
            return NSLocalizedString("Software", comment: "Industry option in the store creation category question.")
        case .airlinesAndAirCarriers:
            return NSLocalizedString("Airlines And Air Carriers", comment: "Industry option in the store creation category question.")
        case .commuterTransportation:
            return NSLocalizedString("Commuter Transportation", comment: "Industry option in the store creation category question.")
        case .courierServices:
            return NSLocalizedString("Courier Services", comment: "Industry option in the store creation category question.")
        case .cruiseLines:
            return NSLocalizedString("Cruise Lines", comment: "Industry option in the store creation category question.")
        case .freightForwarders:
            return NSLocalizedString("Freight Forwarders", comment: "Industry option in the store creation category question.")
        case .otherTransportationServices:
            return NSLocalizedString("Other Transportation Services", comment: "Industry option in the store creation category question.")
        case .parkingLots:
            return NSLocalizedString("Parking Lots", comment: "Industry option in the store creation category question.")
        case .ridesharing:
            return NSLocalizedString("Ridesharing", comment: "Industry option in the store creation category question.")
        case .shippingOrForwarding:
            return NSLocalizedString("Shipping Or Forwarding", comment: "Industry option in the store creation category question.")
        case .taxisAndLimos:
            return NSLocalizedString("Taxis And Limos", comment: "Industry option in the store creation category question.")
        case .travelAgencies:
            return NSLocalizedString("Travel Agencies", comment: "Industry option in the store creation category question.")
        case .hotelsInnsOrMotels:
            return NSLocalizedString("Hotels, Inns, Or Motels", comment: "Industry option in the store creation category question.")
        case .otherTravelLeisure:
            return NSLocalizedString("Other Travel And Lodging", comment: "Industry option in the store creation category question.")
        case .propertyRentals:
            return NSLocalizedString("Property Rentals", comment: "Industry option in the store creation category question.")
        case .timeshares:
            return NSLocalizedString("Timeshares", comment: "Industry option in the store creation category question.")
        case .trailerParksAndCampgrounds:
            return NSLocalizedString("Trailer Parks and Campgrounds", comment: "Industry option in the store creation category question.")
        }
    }
}

extension StoreCreationCategoryQuestionViewModel.CategoryGroup {
    var name: String {
        switch self {
        case .automotive:
            return NSLocalizedString("Autos (Sales and Service)", comment: "Industry group option in the store creation category question.")
        case .constructionIndustrial:
            return NSLocalizedString("Building Services", comment: "Industry group option in the store creation category question.")
        case .digitalProducts:
            return NSLocalizedString("Digital Products", comment: "Industry group option in the store creation category question.")
        case .educationLearning:
            return NSLocalizedString("Education", comment: "Industry group option in the store creation category question.")
        case .entertainmentAndRecreation:
            return NSLocalizedString("Entertainment And Recreation", comment: "Industry group option in the store creation category question.")
        case .financialServices:
            return NSLocalizedString("Financial Services", comment: "Industry group option in the store creation category question.")
        case .foodDrink:
            return NSLocalizedString("Food And Drink", comment: "Industry group option in the store creation category question.")
        case .medicalServices:
            return NSLocalizedString("Medical Services", comment: "Industry group option in the store creation category question.")
        case .membershipOrganizations:
            return NSLocalizedString("Membership Organizations", comment: "Industry group option in the store creation category question.")
        case .personalServices:
            return NSLocalizedString("Personal Services", comment: "Industry group option in the store creation category question.")
        case .professionalServices:
            return NSLocalizedString("Professional Services", comment: "Industry group option in the store creation category question.")
        case .regulatedAndAgeRestrictedProducts:
            return NSLocalizedString("Regulated And Age-Restricted Products", comment: "Industry group option in the store creation category question.")
        case .retail:
            return NSLocalizedString("Retail", comment: "Industry group option in the store creation category question.")
        case .transportation:
            return NSLocalizedString("Transportation", comment: "Industry group option in the store creation category question.")
        case .travelLeisure:
            return NSLocalizedString("Travel And Lodging", comment: "Industry group option in the store creation category question.")
        }
    }
}
