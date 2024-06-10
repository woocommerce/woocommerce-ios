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

    /// The state for the In-app Purchases feature switch.
    ///
    public var isInAppPurchasesSwitchEnabled: Bool

    /// The state for the Point Of Sale feature switch.
    ///
    public var isPointOfSaleEnabled: Bool

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

    /// The settings stored locally that indicate whether each local announcement's has been dismissed.
    ///
    public var localAnnouncementDismissed: [LocalAnnouncement: Bool]

    public init(installationDate: Date?,
                feedbacks: [FeedbackType: FeedbackSettings],
                isViewAddOnsSwitchEnabled: Bool,
                isInAppPurchasesSwitchEnabled: Bool,
                isPointOfSaleEnabled: Bool,
                knownCardReaders: [String],
                lastEligibilityErrorInfo: EligibilityErrorInfo? = nil,
                lastJetpackBenefitsBannerDismissedTime: Date? = nil,
                featureAnnouncementCampaignSettings: [FeatureAnnouncementCampaign: FeatureAnnouncementCampaignSettings],
                sitesWithAtLeastOneIPPTransactionFinished: Set<Int64>,
                isEUShippingNoticeDismissed: Bool,
                localAnnouncementDismissed: [LocalAnnouncement: Bool]) {
        self.installationDate = installationDate
        self.feedbacks = feedbacks
        self.isViewAddOnsSwitchEnabled = isViewAddOnsSwitchEnabled
        self.knownCardReaders = knownCardReaders
        self.lastEligibilityErrorInfo = lastEligibilityErrorInfo
        self.lastJetpackBenefitsBannerDismissedTime = lastJetpackBenefitsBannerDismissedTime
        self.featureAnnouncementCampaignSettings = featureAnnouncementCampaignSettings
        self.isInAppPurchasesSwitchEnabled = isInAppPurchasesSwitchEnabled
        self.isPointOfSaleEnabled = isPointOfSaleEnabled
        self.sitesWithAtLeastOneIPPTransactionFinished = sitesWithAtLeastOneIPPTransactionFinished
        self.isEUShippingNoticeDismissed = isEUShippingNoticeDismissed
        self.localAnnouncementDismissed = localAnnouncementDismissed
    }

    public static var `default`: Self {
        .init(installationDate: nil,
              feedbacks: [:],
              isViewAddOnsSwitchEnabled: false,
              isInAppPurchasesSwitchEnabled: false,
              isPointOfSaleEnabled: false,
              knownCardReaders: [],
              lastEligibilityErrorInfo: nil,
              featureAnnouncementCampaignSettings: [:],
              sitesWithAtLeastOneIPPTransactionFinished: [],
              isEUShippingNoticeDismissed: false,
              localAnnouncementDismissed: [:])
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
            isInAppPurchasesSwitchEnabled: isInAppPurchasesSwitchEnabled,
            isPointOfSaleEnabled: isPointOfSaleEnabled,
            knownCardReaders: knownCardReaders,
            lastEligibilityErrorInfo: lastEligibilityErrorInfo,
            featureAnnouncementCampaignSettings: featureAnnouncementCampaignSettings,
            sitesWithAtLeastOneIPPTransactionFinished: sitesWithAtLeastOneIPPTransactionFinished,
            isEUShippingNoticeDismissed: isEUShippingNoticeDismissed,
            localAnnouncementDismissed: localAnnouncementDismissed
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
            isInAppPurchasesSwitchEnabled: isInAppPurchasesSwitchEnabled,
            isPointOfSaleEnabled: isPointOfSaleEnabled,
            knownCardReaders: knownCardReaders,
            lastEligibilityErrorInfo: lastEligibilityErrorInfo,
            featureAnnouncementCampaignSettings: updatedSettings,
            sitesWithAtLeastOneIPPTransactionFinished: sitesWithAtLeastOneIPPTransactionFinished,
            isEUShippingNoticeDismissed: isEUShippingNoticeDismissed,
            localAnnouncementDismissed: localAnnouncementDismissed
        )
    }

    /// Returns a new instance of `GeneralAppSettings` with the provided feature announcement campaign seetings updated.
    ///
    public func updatingAsDismissed(localAnnouncement: LocalAnnouncement) -> GeneralAppSettings {
        let updatedSettings = localAnnouncementDismissed.merging([localAnnouncement: true]) {
            _, new in new
        }

        return GeneralAppSettings(
            installationDate: installationDate,
            feedbacks: feedbacks,
            isViewAddOnsSwitchEnabled: isViewAddOnsSwitchEnabled,
            isInAppPurchasesSwitchEnabled: isInAppPurchasesSwitchEnabled,
            isPointOfSaleEnabled: isPointOfSaleEnabled,
            knownCardReaders: knownCardReaders,
            lastEligibilityErrorInfo: lastEligibilityErrorInfo,
            featureAnnouncementCampaignSettings: featureAnnouncementCampaignSettings,
            sitesWithAtLeastOneIPPTransactionFinished: sitesWithAtLeastOneIPPTransactionFinished,
            isEUShippingNoticeDismissed: isEUShippingNoticeDismissed,
            localAnnouncementDismissed: updatedSettings
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
        self.isInAppPurchasesSwitchEnabled = try container.decodeIfPresent(Bool.self, forKey: .isInAppPurchasesSwitchEnabled) ?? false
        self.isPointOfSaleEnabled = try container.decodeIfPresent(Bool.self, forKey: .isPointOfSaleEnabled) ?? false
        self.knownCardReaders = try container.decodeIfPresent([String].self, forKey: .knownCardReaders) ?? []
        self.lastEligibilityErrorInfo = try container.decodeIfPresent(EligibilityErrorInfo.self, forKey: .lastEligibilityErrorInfo)
        self.lastJetpackBenefitsBannerDismissedTime = try container.decodeIfPresent(Date.self, forKey: .lastJetpackBenefitsBannerDismissedTime)
        self.featureAnnouncementCampaignSettings = try container.decodeIfPresent(
            [FeatureAnnouncementCampaign: FeatureAnnouncementCampaignSettings].self,
            forKey: .featureAnnouncementCampaignSettings) ?? [:]
        self.sitesWithAtLeastOneIPPTransactionFinished = try container.decodeIfPresent(Set<Int64>.self,
                                                                                        forKey: .sitesWithAtLeastOneIPPTransactionFinished) ?? Set<Int64>([])
        self.isEUShippingNoticeDismissed = try container.decodeIfPresent(Bool.self, forKey: .isEUShippingNoticeDismissed) ?? false
        self.localAnnouncementDismissed = try container.decodeIfPresent([LocalAnnouncement: Bool].self,
                                                                        forKey: .localAnnouncementDismissed) ?? [:]

        // Decode new properties with `decodeIfPresent` and provide a default value if necessary.
    }
}
