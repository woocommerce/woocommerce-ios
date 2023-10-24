extension WooAnalyticsEvent {
    enum Blaze {
        /// Event property keys.
        private enum Key {
            static let source = "source"
            static let step = "current_step"
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

        /// Tracked when the Blaze webview is first loaded.
        static func blazeFlowStarted(source: BlazeSource) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .blazeFlowStarted,
                              properties: [Key.source: source.analyticsValue])
        }

        /// Tracked when the Blaze webview is dismissed without completing the flow.
        static func blazeFlowCanceled(source: BlazeSource, step: Step) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .blazeFlowCanceled,
                              properties: [Key.source: source.analyticsValue,
                                           Key.step: step.analyticsValue])
        }

        /// Tracked when the Blaze webview flow completes.
        static func blazeFlowCompleted(source: BlazeSource, step: Step) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .blazeFlowCompleted,
                              properties: [Key.source: source.analyticsValue,
                                           Key.step: step.analyticsValue])
        }

        /// Tracked when the Blaze webview returns an error.
        static func blazeFlowError(source: BlazeSource, step: Step, error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .blazeFlowError,
                              properties: [Key.source: source.analyticsValue,
                                           Key.step: step.analyticsValue],
                              error: error)
        }

        /// Tracked when the Blaze banner is dismissed.
        static func blazeBannerDismissed(entryPoint: BlazeBanner.EntryPoint) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .blazeBannerDismissed,
                              properties: [Key.source: entryPoint.blazeSource.analyticsValue])
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

        /// Tracked when then intro screen for Blaze is displayed.
        static func blazeIntroDisplayed() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .blazeIntroDisplayed, properties: [:])
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
        case .productMoreMenu:
            return "product_more_menu"
        case .campaignList:
            return "campaign_list"
        case .myStoreSectionCreateCampaignButton:
            return "my_store_section_create_campaign_button"
        case .introView:
            return "intro_view"
        }
    }
}
