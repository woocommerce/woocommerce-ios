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

    /// The state(`true` or `false`) for the application passwords feature switch.
    ///
    public var isApplicationPasswordsSwitchEnabled: Bool

    /// The state(`true` or `false`) for the POS local catalog beta feature switch.
    ///
    public var isPOSLocalCatalogSwitchEnabled: Bool

    /// A list (possibly empty) of known card reader IDs - i.e. IDs of card readers that should be reconnected to automatically
    /// e.g. ["CHB204909005931"]
    ///
    public var knownCardReaders: [String]

    /// The last known eligibility error information persisted locally.
    ///
    public var lastEligibilityErrorInfo: EligibilityErrorInfo?

    /// The last time the Jetpack benefits banner is dismissed.
    public var lastJetpackBenefitsBannerDismissedTime: Date?

    /// The settings stored locally for each feature announcement campaign
    ///
    public var featureAnnouncementCampaignSettings: [FeatureAnnouncementCampaign: FeatureAnnouncementCampaignSettings]

    /// Whether the user finished an IPP transaction for the given site
    ///
    public var sitesWithAtLeastOneIPPTransactionFinished: Set<Int64>

    /// Whether the EU Shipping Notice was dismissed.
    ///
    public var isEUShippingNoticeDismissed: Bool

    /// Whether the Custom Fields top banner was dismissed
    ///
    public var isCustomFieldsTopBannerDismissed: Bool

    /// Whether the Point of Sale survey notification has been scheduled for potential merchants
    ///
    public var isPOSSurveyPotentialMerchantNotificationScheduled: Bool

    /// Whether the Point of Sale survey notification has been scheduled for current merchants
    ///
    public var isPOSSurveyCurrentMerchantNotificationScheduled: Bool

    /// Whether POS mode has been opened at least once
    ///
    public var hasPOSBeenOpenedAtLeastOnce: Bool

    public init(installationDate: Date?,
                feedbacks: [FeedbackType: FeedbackSettings],
                isViewAddOnsSwitchEnabled: Bool,
                isApplicationPasswordsSwitchEnabled: Bool,
                isPOSLocalCatalogSwitchEnabled: Bool,
                knownCardReaders: [String],
                lastEligibilityErrorInfo: EligibilityErrorInfo? = nil,
                lastJetpackBenefitsBannerDismissedTime: Date? = nil,
                featureAnnouncementCampaignSettings: [FeatureAnnouncementCampaign: FeatureAnnouncementCampaignSettings],
                sitesWithAtLeastOneIPPTransactionFinished: Set<Int64>,
                isEUShippingNoticeDismissed: Bool,
                isCustomFieldsTopBannerDismissed: Bool,
                isPOSSurveyPotentialMerchantNotificationScheduled: Bool,
                isPOSSurveyCurrentMerchantNotificationScheduled: Bool,
                hasPOSBeenOpenedAtLeastOnce: Bool) {
        self.installationDate = installationDate
        self.feedbacks = feedbacks
        self.isViewAddOnsSwitchEnabled = isViewAddOnsSwitchEnabled
        self.isApplicationPasswordsSwitchEnabled = isApplicationPasswordsSwitchEnabled
        self.isPOSLocalCatalogSwitchEnabled = isPOSLocalCatalogSwitchEnabled
        self.knownCardReaders = knownCardReaders
        self.lastEligibilityErrorInfo = lastEligibilityErrorInfo
        self.lastJetpackBenefitsBannerDismissedTime = lastJetpackBenefitsBannerDismissedTime
        self.featureAnnouncementCampaignSettings = featureAnnouncementCampaignSettings
        self.sitesWithAtLeastOneIPPTransactionFinished = sitesWithAtLeastOneIPPTransactionFinished
        self.isEUShippingNoticeDismissed = isEUShippingNoticeDismissed
        self.isCustomFieldsTopBannerDismissed = isCustomFieldsTopBannerDismissed
        self.isPOSSurveyPotentialMerchantNotificationScheduled = isPOSSurveyPotentialMerchantNotificationScheduled
        self.isPOSSurveyCurrentMerchantNotificationScheduled = isPOSSurveyCurrentMerchantNotificationScheduled
        self.hasPOSBeenOpenedAtLeastOnce = hasPOSBeenOpenedAtLeastOnce
    }

    public static var `default`: Self {
        .init(installationDate: nil,
              feedbacks: [:],
              isViewAddOnsSwitchEnabled: false,
              isApplicationPasswordsSwitchEnabled: true,
              isPOSLocalCatalogSwitchEnabled: true,
              knownCardReaders: [],
              lastEligibilityErrorInfo: nil,
              featureAnnouncementCampaignSettings: [:],
              sitesWithAtLeastOneIPPTransactionFinished: [],
              isEUShippingNoticeDismissed: false,
              isCustomFieldsTopBannerDismissed: false,
              isPOSSurveyPotentialMerchantNotificationScheduled: false,
              isPOSSurveyCurrentMerchantNotificationScheduled: false,
              hasPOSBeenOpenedAtLeastOnce: false)
    }

    /// Returns the status of a given feedback type. If the feedback is not stored in the feedback array. it is assumed that it has a pending status.
    ///
    public func feedbackStatus(of type: FeedbackType) -> FeedbackSettings.Status {
        guard let feedbackSetting = feedbacks[type] else {
            return .pending
        }

        return feedbackSetting.status
    }

    /// Returns a new instance of `GeneralAppSettings` with the provided feedback seetings updated.
    ///
    public func replacing(feedback: FeedbackSettings) -> GeneralAppSettings {
        let updatedFeedbacks = feedbacks.merging([feedback.name: feedback]) {
            _, new in new
        }

        return GeneralAppSettings(
            installationDate: installationDate,
            feedbacks: updatedFeedbacks,
            isViewAddOnsSwitchEnabled: isViewAddOnsSwitchEnabled,
            isApplicationPasswordsSwitchEnabled: isApplicationPasswordsSwitchEnabled,
            isPOSLocalCatalogSwitchEnabled: isPOSLocalCatalogSwitchEnabled,
            knownCardReaders: knownCardReaders,
            lastEligibilityErrorInfo: lastEligibilityErrorInfo,
            featureAnnouncementCampaignSettings: featureAnnouncementCampaignSettings,
            sitesWithAtLeastOneIPPTransactionFinished: sitesWithAtLeastOneIPPTransactionFinished,
            isEUShippingNoticeDismissed: isEUShippingNoticeDismissed,
            isCustomFieldsTopBannerDismissed: isCustomFieldsTopBannerDismissed,
            isPOSSurveyPotentialMerchantNotificationScheduled: isPOSSurveyPotentialMerchantNotificationScheduled,
            isPOSSurveyCurrentMerchantNotificationScheduled: isPOSSurveyCurrentMerchantNotificationScheduled,
            hasPOSBeenOpenedAtLeastOnce: hasPOSBeenOpenedAtLeastOnce
        )
    }

    /// Returns a new instance of `GeneralAppSettings` with the provided feature announcement campaign seetings updated.
    ///
    public func replacing(featureAnnouncementSettings: FeatureAnnouncementCampaignSettings, for campaign: FeatureAnnouncementCampaign) -> GeneralAppSettings {
        let updatedSettings = featureAnnouncementCampaignSettings.merging([campaign: featureAnnouncementSettings]) {
            _, new in new
        }

        return GeneralAppSettings(
            installationDate: installationDate,
            feedbacks: feedbacks,
            isViewAddOnsSwitchEnabled: isViewAddOnsSwitchEnabled,
            isApplicationPasswordsSwitchEnabled: isApplicationPasswordsSwitchEnabled,
            isPOSLocalCatalogSwitchEnabled: isPOSLocalCatalogSwitchEnabled,
            knownCardReaders: knownCardReaders,
            lastEligibilityErrorInfo: lastEligibilityErrorInfo,
            featureAnnouncementCampaignSettings: updatedSettings,
            sitesWithAtLeastOneIPPTransactionFinished: sitesWithAtLeastOneIPPTransactionFinished,
            isEUShippingNoticeDismissed: isEUShippingNoticeDismissed,
            isCustomFieldsTopBannerDismissed: isCustomFieldsTopBannerDismissed,
            isPOSSurveyPotentialMerchantNotificationScheduled: isPOSSurveyPotentialMerchantNotificationScheduled,
            isPOSSurveyCurrentMerchantNotificationScheduled: isPOSSurveyCurrentMerchantNotificationScheduled,
            hasPOSBeenOpenedAtLeastOnce: hasPOSBeenOpenedAtLeastOnce
        )
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
        self.isApplicationPasswordsSwitchEnabled = try container.decodeIfPresent(Bool.self, forKey: .isApplicationPasswordsSwitchEnabled) ?? false
        self.isPOSLocalCatalogSwitchEnabled = try container.decodeIfPresent(Bool.self, forKey: .isPOSLocalCatalogSwitchEnabled) ?? true
        self.knownCardReaders = try container.decodeIfPresent([String].self, forKey: .knownCardReaders) ?? []
        self.lastEligibilityErrorInfo = try container.decodeIfPresent(EligibilityErrorInfo.self, forKey: .lastEligibilityErrorInfo)
        self.lastJetpackBenefitsBannerDismissedTime = try container.decodeIfPresent(Date.self, forKey: .lastJetpackBenefitsBannerDismissedTime)
        self.featureAnnouncementCampaignSettings = try container.decodeIfPresent(
            [FeatureAnnouncementCampaign: FeatureAnnouncementCampaignSettings].self,
            forKey: .featureAnnouncementCampaignSettings) ?? [:]
        self.sitesWithAtLeastOneIPPTransactionFinished = try container.decodeIfPresent(Set<Int64>.self,
                                                                                        forKey: .sitesWithAtLeastOneIPPTransactionFinished) ?? Set<Int64>([])
        self.isEUShippingNoticeDismissed = try container.decodeIfPresent(Bool.self, forKey: .isEUShippingNoticeDismissed) ?? false
        self.isCustomFieldsTopBannerDismissed = try container.decodeIfPresent(Bool.self, forKey: .isCustomFieldsTopBannerDismissed) ?? false
        //swiftlint:disable:next line_length
        self.isPOSSurveyPotentialMerchantNotificationScheduled = try container.decodeIfPresent(Bool.self, forKey: .isPOSSurveyPotentialMerchantNotificationScheduled) ?? false
        //swiftlint:disable:next line_length
        self.isPOSSurveyCurrentMerchantNotificationScheduled = try container.decodeIfPresent(Bool.self, forKey: .isPOSSurveyCurrentMerchantNotificationScheduled) ?? false
        self.hasPOSBeenOpenedAtLeastOnce = try container.decodeIfPresent(Bool.self, forKey: .hasPOSBeenOpenedAtLeastOnce) ?? false
        // Decode new properties with `decodeIfPresent` and provide a default value if necessary.
    }
}
