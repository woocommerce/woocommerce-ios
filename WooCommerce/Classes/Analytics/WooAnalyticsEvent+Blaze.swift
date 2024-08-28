extension WooAnalyticsEvent {
    enum Blaze {
        /// Event property keys.
        private enum Key {
            static let source = "source"
            static let step = "current_step"
            static let duration = "duration"
            static let totalBudget = "total_budget"
            static let isAISuggestedAdContent = "is_ai_suggested_ad_content"
            static let campaignType = "campaign_type"
        }

        private enum Values {
            enum CampaignType {
                static let startEnd = "start_end"
                static let evergreen = "evergreen"
            }
        }

        /// Tracked when the Blaze entry point is shown to the user.
        static func blazeEntryPointDisplayed(source: BlazeSource) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .blazeEntryPointDisplayed,
                              properties: [Key.source: source.analyticsValue])
        }

        /// Tracked when the Blaze entry point is tapped by the user.
        /// - Parameter source: Entry point to the Blaze flow.
        static func blazeEntryPointTapped(source: BlazeSource) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .blazeEntryPointTapped,
                              properties: [Key.source: source.analyticsValue])
        }

        /// Tracked when the Blaze campaign list entry point is selected.
        static func blazeCampaignListEntryPointSelected(source: BlazeCampaignListSource) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .blazeCampaignListEntryPointSelected,
                              properties: [Key.source: source.rawValue])
        }

        /// Tracked when a Blaze campaign detail is selected.
        static func blazeCampaignDetailSelected(source: BlazeCampaignDetailSource) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .blazeCampaignDetailSelected,
                              properties: [Key.source: source.rawValue])
        }

        /// Tracked when an entry point to Blaze is dismissed.
        static func blazeViewDismissed(source: BlazeSource) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .blazeViewDismissed, properties: [Key.source: source.analyticsValue])
        }

        /// Tracked when the intro screen for Blaze is displayed.
        static func introDisplayed() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .blazeIntroDisplayed, properties: [:])
        }

        /// Tracked upon tapping "Learn how Blaze works" in Intro screen
        static func introLearnMoreTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .blazeIntroLearnMoreTapped, properties: [:])
        }

        enum CreationForm {
            /// Tracked when Blaze creation form is displayed
            static func creationFormDisplayed() -> WooAnalyticsEvent {
                WooAnalyticsEvent(statName: .blazeCreationFormDisplayed, properties: [:])
            }

            /// Tracked upon tapping "Edit ad" in Blaze creation form
            static func editAdTapped() -> WooAnalyticsEvent {
                WooAnalyticsEvent(statName: .blazeEditAdTapped, properties: [:])
            }

            /// Tracked upon tapping "Confirm Details" in Blaze creation form
            static func confirmDetailsTapped(isAISuggestedAdContent: Bool,
                                             isEvergreen: Bool) -> WooAnalyticsEvent {
                WooAnalyticsEvent(statName: .blazeCreationConfirmDetailsTapped,
                                  properties: [Key.isAISuggestedAdContent: isAISuggestedAdContent,
                                               Key.campaignType: isEvergreen ?
                                                Values.CampaignType.evergreen :
                                                Values.CampaignType.startEnd])
            }
        }

        enum EditAd {
            /// Tracked upon selecting AI suggestion in Edit Ad screen
            static func aiSuggestionTapped() -> WooAnalyticsEvent {
                WooAnalyticsEvent(statName: .blazeEditAdAISuggestionTapped, properties: [:])
            }

            /// Tracked upon tapping "Save" in Edit Ad screen
            static func saveTapped() -> WooAnalyticsEvent {
                WooAnalyticsEvent(statName: .blazeEditAdSaveTapped, properties: [:])
            }
        }

        enum Budget {
            /// Tracked upon tapping "Update" in Blaze set budget screen
            static func updateTapped(duration: Int, totalBudget: Double, hasEndDate: Bool) -> WooAnalyticsEvent {
                WooAnalyticsEvent(statName: .blazeEditBudgetSaveTapped,
                                  properties: [Key.duration: duration,
                                               Key.totalBudget: totalBudget,
                                               Key.campaignType: hasEndDate ?
                                                Values.CampaignType.startEnd :
                                                Values.CampaignType.evergreen])
            }

            /// Tracked upon changing schedule in Blaze set budget screen
            static func changedSchedule(duration: Int, hasEndDate: Bool) -> WooAnalyticsEvent {
                WooAnalyticsEvent(statName: .blazeEditBudgetDurationApplied,
                                  properties: [Key.duration: duration,
                                               Key.campaignType: hasEndDate ?
                                                Values.CampaignType.startEnd :
                                                Values.CampaignType.evergreen])
            }
        }

        enum Language {
            /// Tracked upon tapping "Save" in Blaze language selection screen
            static func saveTapped() -> WooAnalyticsEvent {
                WooAnalyticsEvent(statName: .blazeEditLanguageSaveTapped, properties: [:])
            }
        }

        enum Device {
            /// Tracked upon tapping "Save" in Blaze device selection screen
            static func saveTapped() -> WooAnalyticsEvent {
                WooAnalyticsEvent(statName: .blazeEditDeviceSaveTapped, properties: [:])
            }
        }

        enum Location {
            /// Tracked upon tapping "Save" in Blaze location selection screen
            static func saveTapped() -> WooAnalyticsEvent {
                WooAnalyticsEvent(statName: .blazeEditLocationSaveTapped, properties: [:])
            }
        }

        enum Interest {
            /// Tracked upon tapping "Save" in Blaze interests selection screen
            static func saveTapped() -> WooAnalyticsEvent {
                WooAnalyticsEvent(statName: .blazeEditInterestSaveTapped, properties: [:])
            }
        }

        enum AdDestination {
            /// Tracked upon tapping "Save" in Blaze ad destination selection screen
            static func saveTapped() -> WooAnalyticsEvent {
                WooAnalyticsEvent(statName: .blazeEditDestinationSaveTapped, properties: [:])
            }
        }

        enum Payment {
            /// Tracked upon tapping "Submit Campaign" in confirm payment screen
            static func submitCampaignTapped() -> WooAnalyticsEvent {
                WooAnalyticsEvent(statName: .blazeSubmitCampaignTapped, properties: [:])
            }

            /// Tracked upon displaying "Add payment method" web view screen
            static func addPaymentMethodWebViewDisplayed() -> WooAnalyticsEvent {
                WooAnalyticsEvent(statName: .blazeAddPaymentMethodWebViewDisplayed, properties: [:])
            }

            /// Tracked upon adding a payment method
            static func addPaymentMethodSuccess() -> WooAnalyticsEvent {
                WooAnalyticsEvent(statName: .blazeAddPaymentMethodSuccess, properties: [:])
            }

            /// Tracked when campaign creation is successful
            static func campaignCreationSuccess(isEvergreen: Bool) -> WooAnalyticsEvent {
                WooAnalyticsEvent(statName: .blazeCampaignCreationSuccess, properties: [
                    Key.campaignType: isEvergreen ? Values.CampaignType.evergreen : Values.CampaignType.startEnd
                ])
            }

            /// Tracked when campaign creation fails
            static func campaignCreationFailed(error: Error) -> WooAnalyticsEvent {
                WooAnalyticsEvent(statName: .blazeCampaignCreationFailed, properties: [:], error: error)
            }
        }
    }
}

extension WooAnalyticsEvent.Blaze {
    enum Step: Equatable {
        case unspecified
        case productList
        case campaignList
        case step1
        case custom(step: String)
    }
}

private extension WooAnalyticsEvent.Blaze.Step {
    var analyticsValue: String {
        switch self {
        case .unspecified:
            return "unspecified"
        case .productList:
            return "products-list"
        case .campaignList:
            return "campaigns-list"
        case .step1:
            return "step-1"
        case .custom(let step):
            return step
        }
    }
}

extension BlazeSource {
    var analyticsValue: String {
        switch self {
        case .campaignList:
            return "campaign_list"
        case .myStoreSection:
            return "my_store_section"
        case .introView:
            return "intro_view"
        case .productDetailPromoteButton:
            return "product_detail_promote_button"
        }
    }
}
