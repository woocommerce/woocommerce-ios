import Foundation
import Codegen

/// An encodable/decodable data structure that can be used to save files. This contains
/// miscellaneous app settings.
///
/// Sometimes I wonder if `AppSettingsStore` should just use one plist file. Maybe things will
/// be simpler?
///
public struct GeneralAppSettings: Codable, Equatable, GeneratedCopiable {
    /// The known `Date` that the app was installed.
    ///
    /// Note that this is not accurate because this property/setting was created when we have
    /// thousands of users already.
    ///
    public var installationDate: Date?

    /// Key/Value type to store feedback settings
    /// Key: A `FeedbackType` to identify the feedback
    /// Value: A `FeedbackSetting` to store the feedback state
    public var feedbacks: [FeedbackType: FeedbackSettings]

    /// The state(`true` or `false`) for the view add-on beta feature switch.
    ///
    public var isViewAddOnsSwitchEnabled: Bool

    /// The state(`true` or `false`) for the Order Creation feature switch.
    ///
    public var isOrderCreationSwitchEnabled: Bool

    /// The state for the Stripe Gateway Extension IPP feature switch
    ///
    public var isStripeInPersonPaymentsSwitchEnabled: Bool

    /// The state for the In-Person Payments in Canada feature switch
    ///
    public var isCanadaInPersonPaymentsSwitchEnabled: Bool

    /// The state(`true` or `false`) for the Product SKU Input Scanner feature switch.
    ///
    public var isProductSKUInputScannerSwitchEnabled: Bool

    /// The state for the Coupon Management feature switch.
    ///
    public var isCouponManagementSwitchEnabled: Bool

    /// A list (possibly empty) of known card reader IDs - i.e. IDs of card readers that should be reconnected to automatically
    /// e.g. ["CHB204909005931"]
    ///
    public var knownCardReaders: [String]

    /// The last known eligibility error information persisted locally.
    ///
    public var lastEligibilityErrorInfo: EligibilityErrorInfo?

    /// The last time the Jetpack benefits banner is dismissed.
    public var lastJetpackBenefitsBannerDismissedTime: Date?

    public init(installationDate: Date?,
                feedbacks: [FeedbackType: FeedbackSettings],
                isViewAddOnsSwitchEnabled: Bool,
                isOrderCreationSwitchEnabled: Bool,
                isStripeInPersonPaymentsSwitchEnabled: Bool,
                isCanadaInPersonPaymentsSwitchEnabled: Bool,
                isProductSKUInputScannerSwitchEnabled: Bool,
                isCouponManagementSwitchEnabled: Bool,
                knownCardReaders: [String],
                lastEligibilityErrorInfo: EligibilityErrorInfo? = nil,
                lastJetpackBenefitsBannerDismissedTime: Date? = nil) {
        self.installationDate = installationDate
        self.feedbacks = feedbacks
        self.isViewAddOnsSwitchEnabled = isViewAddOnsSwitchEnabled
        self.isOrderCreationSwitchEnabled = isOrderCreationSwitchEnabled
        self.isStripeInPersonPaymentsSwitchEnabled = isStripeInPersonPaymentsSwitchEnabled
        self.isCanadaInPersonPaymentsSwitchEnabled = isCanadaInPersonPaymentsSwitchEnabled
        self.isProductSKUInputScannerSwitchEnabled = isProductSKUInputScannerSwitchEnabled
        self.isCouponManagementSwitchEnabled = isCouponManagementSwitchEnabled
        self.knownCardReaders = knownCardReaders
        self.lastEligibilityErrorInfo = lastEligibilityErrorInfo
        self.lastJetpackBenefitsBannerDismissedTime = lastJetpackBenefitsBannerDismissedTime
    }

    public static var `default`: GeneralAppSettings {
        GeneralAppSettings(installationDate: nil,
                                  feedbacks: [:],
                                  isViewAddOnsSwitchEnabled: false,
                                  isOrderCreationSwitchEnabled: false,
                                  isStripeInPersonPaymentsSwitchEnabled: false,
                                  isCanadaInPersonPaymentsSwitchEnabled: false,
                                  isProductSKUInputScannerSwitchEnabled: false,
                                  isCouponManagementSwitchEnabled: false,
                                  knownCardReaders: [],
                                  lastEligibilityErrorInfo: nil)
    }
}

// MARK: Custom Decoding
extension GeneralAppSettings {
    /// We need a custom decoding to make sure it doesn't fails when this type is updated (eg: when adding/removing new properties)
    /// Otherwise we will lose previously stored information.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.installationDate = try container.decodeIfPresent(Date.self, forKey: .installationDate)
        self.feedbacks = try container.decodeIfPresent([FeedbackType: FeedbackSettings].self, forKey: .feedbacks) ?? [:]
        self.isViewAddOnsSwitchEnabled = try container.decodeIfPresent(Bool.self, forKey: .isViewAddOnsSwitchEnabled) ?? false
        self.isOrderCreationSwitchEnabled = try container.decodeIfPresent(Bool.self, forKey: .isOrderCreationSwitchEnabled) ?? false
        self.isStripeInPersonPaymentsSwitchEnabled = try container.decodeIfPresent(Bool.self, forKey: .isStripeInPersonPaymentsSwitchEnabled) ?? false
        self.isCanadaInPersonPaymentsSwitchEnabled = try container.decodeIfPresent(Bool.self, forKey: .isCanadaInPersonPaymentsSwitchEnabled) ?? false
        self.isProductSKUInputScannerSwitchEnabled = try container.decodeIfPresent(Bool.self, forKey: .isProductSKUInputScannerSwitchEnabled) ?? false
        self.isCouponManagementSwitchEnabled = try container.decodeIfPresent(Bool.self, forKey: .isCouponManagementSwitchEnabled) ?? false
        self.knownCardReaders = try container.decodeIfPresent([String].self, forKey: .knownCardReaders) ?? []
        self.lastEligibilityErrorInfo = try container.decodeIfPresent(EligibilityErrorInfo.self, forKey: .lastEligibilityErrorInfo)
        self.lastJetpackBenefitsBannerDismissedTime = try container.decodeIfPresent(Date.self, forKey: .lastJetpackBenefitsBannerDismissedTime)

        // Decode new properties with `decodeIfPresent` and provide a default value if necessary.
    }
}
