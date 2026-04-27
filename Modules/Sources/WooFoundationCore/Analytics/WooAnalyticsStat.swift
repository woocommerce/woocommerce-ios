import Foundation

/// This enum contains all of the events we track in the WooCommerce app.
///
/// One of goals of this `enum` is to be able to list all the event names that we use throughout
/// the app. We can also potentially make a parser to gather all the event names and automatically
/// compare them with WCAndroid. With that, we can make sure both platforms are tracking the
/// same events.
///
/// ### Type-Safe Properties
///
/// If an event has custom properties, add and use a constructor defined in `WooAnalyticsEvent`.
///
/// ### Excluding Site Properties
///
/// Note: If you would like to exclude site properties (e.g. `blog_id`) for a given event, please
/// add the event to the `WooAnalyticsStat.shouldSendSiteProperties` var.
///
public enum WooAnalyticsStat: String {
    // MARK: Application Events
    //
    case applicationInstalled = "application_installed"
    case applicationUpgraded = "application_upgraded"
    case applicationOpened = "application_opened"
    case applicationClosed = "application_closed"
    case applicationOpenedWaitingTimeLoaded = "application_opened_waiting_time_loaded"
    case applicationSiteSnapshot = "application_store_snapshot"

    // MARK: Authentication Events
    //
    case signedIn = "signed_in"
    case logout = "account_logout"
    case openedLogin = "login_accessed"
    case loginNewToWooButtonTapped = "login_new_to_woo_button_tapped"
    case loginFailed = "login_failed_to_login"
    case loginAutoFillCredentialsFilled = "login_autofill_credentials_filled"
    case loginAutoFillCredentialsUpdated = "login_autofill_credentials_updated"
    case loginEmailFormViewed = "login_email_form_viewed"
    case loginJetpackRequiredScreenViewed = "login_jetpack_required_screen_viewed"
    case loginJetpackRequiredViewInstructionsButtonTapped = "login_jetpack_required_view_instructions_button_tapped"
    case loginWhatIsJetpackHelpScreenViewed = "login_what_is_jetpack_help_screen_viewed"
    case loginWhatIsJetpackHelpScreenOkButtonTapped = "login_what_is_jetpack_help_screen_ok_button_tapped"
    case loginWhatIsJetpackHelpScreenLearnMoreButtonTapped = "login_what_is_jetpack_help_screen_learn_more_button_tapped"
    case loginMagicLinkOpenEmailClientViewed = "login_magic_link_open_email_client_viewed"
    case loginMagicLinkRequestFormViewed = "login_magic_link_request_form_viewed"
    case loginMagicLinkExited = "login_magic_link_exited"
    case loginMagicLinkFailed = "login_magic_link_failed"
    case loginMagicLinkOpened = "login_magic_link_opened"
    case loginMagicLinkRequested = "login_magic_link_requested"
    case loginMagicLinkSucceeded = "login_magic_link_succeeded"
    case loginOnboardingShown = "login_onboarding_shown"
    case loginOnboardingNextButtonTapped = "login_onboarding_next_button_tapped"
    case loginOnboardingSkipButtonTapped = "login_onboarding_skip_button_tapped"
    case loginPasswordFormViewed = "login_password_form_viewed"
    case loginURLFormViewed = "login_url_form_viewed"
    case loginURLHelpScreenViewed = "login_url_help_screen_viewed"
    case loginUsernamePasswordFormViewed = "login_username_password_form_viewed"
    case loginTwoFactorFormViewed = "login_two_factor_form_viewed"
    case loginEpilogueViewed = "login_epilogue_viewed"
    case loginProloguePaged = "login_prologue_paged"
    case loginPrologueViewed = "login_prologue_viewed"
    case loginPrologueContinueTapped = "login_prologue_jetpack_login_button_tapped"
    case loginPrologueJetpackInstructions = "login_prologue_jetpack_configuration_instructions_link_tapped"
    case loginForgotPasswordClicked = "login_forgot_password_clicked"
    case loginSocialButtonClick = "login_social_button_click"
    case loginSocialButtonFailure = "login_social_button_failure"
    case loginSocialConnectSuccess = "login_social_connect_success"
    case loginSocialConnectFailure = "login_social_connect_failure"
    case loginSocialSuccess = "login_social_login_success"
    case loginSocialFailure = "login_social_login_failure"
    case loginSocial2faNeeded = "login_social_2fa_needed"
    case loginSocialAccountsNeedConnecting = "login_social_accounts_need_connecting"
    case loginSocialErrorUnknownUser = "login_social_error_unknown_user"
    case onePasswordFailed = "one_password_failed"
    case onePasswordLogin = "one_password_login"
    case onePasswordSignup = "one_password_signup"
    case twoFactorCodeRequested = "two_factor_code_requested"
    case twoFactorSentSMS = "two_factor_sent_sms"
    case loginInvalidEmailScreenViewed = "login_invalid_email_screen_viewed"
    case whatIsWPComOnInvalidEmailScreenTapped = "what_is_wordpress_com_on_invalid_email_screen"
    case loginInsufficientRole = "login_insufficient_role"
    case blackFlaggedWebsiteDetected = "black_flagged_website_detected"

    // MARK: REST API login
    //
    case loginSiteAddressSiteInfoFetched = "login_site_address_site_info_fetched"
    case loginSiteCredentialsFailed = "login_site_credentials_login_failed"

    // MARK: Site credentials
    //
    case loginJetpackSiteCredentialScreenViewed = "login_jetpack_site_credential_screen_viewed"
    case loginJetpackSiteCredentialScreenDismissed = "login_jetpack_site_credential_screen_dismissed"
    case loginJetpackSiteCredentialInstallTapped = "login_jetpack_site_credential_install_button_tapped"
    case loginJetpackSiteCredentialResetPasswordTapped = "login_jetpack_site_credential_reset_password_button_tapped"
    case loginJetpackSiteCredentialDidShowErrorAlert = "login_jetpack_site_credential_did_show_error_alert"
    case loginJetpackSiteCredentialDidFinishLogin = "login_jetpack_site_credential_did_finish_login"
    case loginAppLoginLinkSuccess = "login_app_login_link_success"
    case loginMalformedAppLoginLink = "login_malformed_app_login_link"

    case loginSiteCredentialsInvalidLoginPageDetected = "login_site_credentials_invalid_login_page_detected"
    case loginSiteCredentialsAppPasswordExplanationDismissed = "login_site_credentials_app_password_explanation_dismissed"
    case loginSiteCredentialsAppPasswordExplanationContactSupportTapped = "login_site_credentials_app_password_explanation_contact_support_tapped"
    case loginSiteCredentialsAppPasswordExplanationContinueButtonTapped = "login_site_credentials_app_password_explanation_continue_button_tapped"
    case loginSiteCredentialsAppPasswordLoginExitConfirmation = "login_site_credentials_app_password_login_exit_confirmation"
    case loginSiteCredentialsAppPasswordLoginDismissed = "login_site_credentials_app_password_login_dismissed"

    // MARK: No matched site alert
    //
    case loginJetpackNoMatchedSiteErrorViewed = "login_jetpack_no_matched_site_error_viewed"
    case loginJetpackNoMatchedSiteErrorTryAgainButtonTapped = "login_jetpack_no_matched_site_error_try_again_button_tapped"
    case loginJetpackNoMatchedSiteErrorContactSupportButtonTapped = "login_jetpack_no_matched_site_error_contact_support_button_tapped"

    // MARK: Local notifications
    //
    case localNotificationTapped = "local_notification_tapped"
    case localNotificationDismissed = "local_notification_dismissed"
    case localNotificationScheduled = "local_notification_scheduled"
    case localNotificationDisplayed = "local_notification_displayed"
    case localNotificationCanceled = "local_notification_canceled"

    // MARK: Dashboard View Events
    //
    case dashboardLoaded = "dashboard_loaded"
    case siteConnectionTypeIdentified = "site_connection_type_identified"
    case dashboardSelected = "main_tab_dashboard_selected"
    case dashboardReselected = "main_tab_dashboard_reselected"
    case dashboardPulledToRefresh = "dashboard_pulled_to_refresh"
    case dashboardNewOrdersButtonTapped = "dashboard_unfulfilled_orders_button_tapped"
    case dashboardShareStoreButtonTapped = "dashboard_share_your_store_button_tapped"
    case dashboardSeeMoreAnalyticsTapped = "dashboard_see_more_analytics_tapped"

    // MARK: Dashboard Data/Action Events
    //
    case dashboardMainStatsDate = "dashboard_main_stats_date"
    case dashboardMainStatsLoaded = "dashboard_main_stats_loaded"
    case dashboardTopPerformersDate = "dashboard_top_performers_date"
    case dashboardTopPerformersLoaded = "dashboard_top_performers_loaded"
    case dashboardUnfulfilledOrdersLoaded = "dashboard_unfulfilled_orders_loaded"
    case dashboardMainStatsWaitingTimeLoaded = "dashboard_main_stats_waiting_time_loaded"
    case dashboardTopPerformersWaitingTimeLoaded = "dashboard_top_performers_waiting_time_loaded"
    case dashboardStoreTimezoneDifferFromDevice = "dashboard_store_timezone_differ_from_device"

    // MARK: Dashboard stats custom range
    case dashboardStatsCustomRangeAddButtonTapped = "dashboard_stats_custom_range_add_button_tapped"
    case dashboardStatsCustomRangeConfirmed = "dashboard_stats_custom_range_confirmed"
    case dashboardStatsCustomRangeTabSelected = "dashboard_stats_custom_range_tab_selected"
    case dashboardStatsCustomRangeEditButtonTapped = "dashboard_stats_custom_range_edit_button_tapped"
    case dashboardStatsCustomRangeInteracted = "dashboard_stats_custom_range_interacted"

    // MARK: Dashboard Stats v3/v4 Events
    //
    case dashboardNewStatsAvailabilityBannerCancelTapped = "dashboard_new_stats_availability_banner_cancel_tapped"
    case dashboardNewStatsAvailabilityBannerTryTapped = "dashboard_new_stats_availability_banner_try_tapped"
    case dashboardNewStatsRevertedBannerDismissTapped = "dashboard_new_stats_reverted_banner_dismiss_tapped"
    case dashboardNewStatsRevertedBannerLearnMoreTapped = "dashboard_new_stats_reverted_banner_learn_more_tapped"
    case usedAnalytics = "used_analytics"

    // MARK: Dynamic Dashboard Events
    case dynamicDashboardEditLayoutButtonTapped = "dynamic_dashboard_edit_layout_button_tapped"
    case dynamicDashboardHideCardTapped = "dynamic_dashboard_hide_card_tapped"
    case dynamicDashboardEditorSaveTapped = "dynamic_dashboard_editor_save_tapped"
    case dynamicDashboardCardRetryTapped = "dynamic_dashboard_card_retry_tapped"
    case dynamicDashboardCardInteracted = "dynamic_dashboard_card_interacted"
    case dynamicDashboardAddNewSectionsTapped = "dynamic_dashboard_add_new_sections_tapped"
    case dynamicDashboardCardDataLoadingStarted = "dynamic_dashboard_card_data_loading_started"
    case dynamicDashboardCardDataLoadingCompleted = "dynamic_dashboard_card_data_loading_completed"
    case dynamicDashboardCardDataLoadingFailed = "dynamic_dashboard_card_data_loading_failed"

    // MARK: Analytics Hub Events
    //
    case analyticsHubDateRangeButtonTapped = "analytics_hub_date_range_button_tapped"
    case analyticsHubDateRangeOptionSelected = "analytics_hub_date_range_option_selected"
    case analyticsHubDateRangeSelectionFailed = "analytics_hub_date_range_selection_failed"
    case analyticsHubWaitingTimeLoaded = "analytics_hub_waiting_time_loaded"
    case analyticsHubEnableJetpackStatsShown = "analytics_hub_enable_jetpack_stats_shown"
    case analyticsHubEnableJetpackStatsTapped = "analytics_hub_enable_jetpack_stats_tapped"
    case analyticsHubEnableJetpackStatsSuccess = "analytics_hub_enable_jetpack_stats_success"
    case analyticsHubEnableJetpackStatsFailed = "analytics_hub_enable_jetpack_stats_failed"
    case analyticsHubViewFullReportTapped = "analytics_hub_view_full_report_tapped"
    case analyticsHubSettingsOpened = "analytics_hub_settings_opened"
    case analyticsHubSettingsSaved = "analytics_hub_settings_saved"
    case analyticsHubCardMetricSelected = "analytics_hub_card_metric_selected"

    // MARK: Blaze Events
    //
    case blazeEntryPointDisplayed = "blaze_entry_point_displayed"
    case blazeEntryPointTapped = "blaze_entry_point_tapped"
    case blazeCampaignListEntryPointSelected = "blaze_campaign_list_entry_point_selected"
    case blazeCampaignDetailSelected = "blaze_campaign_detail_selected"
    case blazeViewDismissed = "blaze_view_dismissed"
    case blazeIntroDisplayed = "blaze_intro_displayed"
    case blazeIntroLearnMoreTapped = "blaze_intro_learn_more_tapped"
    case blazeCreationFormDisplayed = "blaze_creation_form_displayed"
    case blazeEditAdTapped = "blaze_creation_edit_ad_tapped"
    case blazeCampaignObjectiveSaved = "blaze_campaign_objective_saved"
    case blazeCreationConfirmDetailsTapped = "blaze_creation_confirm_details_tapped"
    case blazeEditAdSaveTapped = "blaze_creation_edit_ad_save_tapped"
    case blazeEditAdAISuggestionTapped = "blaze_creation_edit_ad_ai_suggestion_tapped"
    case blazeEditBudgetSaveTapped = "blaze_creation_edit_budget_save_tapped"
    case blazeEditBudgetDurationApplied = "blaze_creation_edit_budget_set_duration_applied"
    case blazeEditLanguageSaveTapped = "blaze_creation_edit_language_save_tapped"
    case blazeEditDeviceSaveTapped = "blaze_creation_edit_device_save_tapped"
    case blazeEditLocationSaveTapped = "blaze_creation_edit_location_save_tapped"
    case blazeEditInterestSaveTapped = "blaze_creation_edit_interest_save_tapped"
    case blazeEditDestinationSaveTapped = "blaze_creation_edit_destination_save_tapped"
    case blazeSubmitCampaignTapped = "blaze_creation_payment_submit_campaign_tapped"
    case blazeAddPaymentMethodWebViewDisplayed = "blaze_creation_add_payment_method_web_view_displayed"
    case blazeAddPaymentMethodSuccess = "blaze_creation_add_payment_method_success"
    case blazeCampaignCreationSuccess = "blaze_campaign_creation_success"
    case blazeCampaignCreationFailed = "blaze_campaign_creation_failed"
    case blazeCampaignCreationFeedback = "blaze_campaign_creation_feedback"
    case blazeSuggestionsLoadingFailed = "blaze_suggestions_loading_failed"

    // MARK: Store Onboarding Events
    //
    case storeOnboardingShown = "store_onboarding_shown"
    case storeOnboardingTaskTapped = "store_onboarding_task_tapped"
    case storeOnboardingTaskCompleted = "store_onboarding_task_completed"
    case storeOnboardingCompleted = "store_onboarding_completed"
    case storeOnboardingHideList = "store_onboarding_hide_list"
    case storeOnboardingWCPayBeginSetupTapped = "store_onboarding_wcpay_begin_setup_tapped"
    case storeOnboardingWCPayTermsContinueTapped = "store_onboarding_wcpay_terms_continue_tapped"

    // MARK: Site picker. Can be triggered by login epilogue or settings.
    //
    case sitePickerContinueTapped = "site_picker_continue_tapped"
    case sitePickerStoresShown = "site_picker_stores_shown"
    case sitePickerHelpButtonTapped = "site_picker_help_button_tapped"
    case sitePickerLogoutButtonTapped = "site_picker_logout_tapped"
    case sitePickerNonWooSiteTapped = "site_picker_non_woo_site_tapped"
    case sitePickerSiteDiscovery = "site_picker_site_discovery"
    case sitePickerNewToWooTapped = "site_picker_new_to_woo_tapped"
    case sitePickerAddStoreTapped = "site_picker_add_a_store_tapped"
    case sitePickerConnectExistingStoreTapped = "site_picker_connect_existing_store_tapped"
    case sitePickerEditButtonShown = "site_picker_edit_button_shown"
    case sitePickerEditButtonTapped = "site_picker_edit_button_tapped"
    case sitePickerListSaveButtonTapped = "site_picker_list_save_button_tapped"
    case sitePickerListSavingSuccess = "site_picker_list_saving_success"
    case sitePickerListSavingFailure = "site_picker_list_saving_failure"

    // MARK: Site creation
    //
    case siteCreated = "login_woocommerce_site_created"
    case siteCreationFailed = "site_creation_failed"
    case siteCreationDismissed = "site_creation_dismissed"
    case siteCreationFlowStarted = "site_creation_flow_started"
    case siteCreationStep = "site_creation_step"
    case siteCreationSitePreviewed = "site_creation_site_previewed"
    case siteCreationManageStoreTapped = "site_creation_store_management_opened"
    case siteCreationProfilerData = "site_creation_profiler_data"
    case siteCreationProfilerQuestionSkipped = "site_creation_profiler_question_skipped"
    case siteCreationTryForFreeTapped = "site_creation_try_for_free_tapped"
    case siteCreationTimedOut = "site_creation_timed_out"
    case siteCreationTimeoutRetried = "site_creation_timeout_retried"
    case siteCreationPropertiesOutOfSync = "site_creation_properties_out_of_sync"
    case siteCreationFreeTrialCreatedSuccess = "site_creation_free_trial_created_success"
    case loginPrologueCreateSiteTapped = "login_prologue_create_site_tapped"
    case loginPrologueStartingANewStoreTapped = "login_prologue_starting_a_new_store_tapped"
    case signupFormLoginTapped = "signup_login_button_tapped"
    case signupSubmitted = "signup_submitted"
    case signupSuccess = "signup_success"
    case signupFailed = "signup_failed"
    case storeReadyAlertDisplayed = "site_creation_store_ready_alert_displayed"
    case storeReadyAlertSwitchStoreTapped = "site_creation_store_ready_alert_switch_store_tapped"

    // MARK: Help & Support Events
    //
    case supportHelpCenterViewed = "support_help_center_viewed"
    case supportNewRequestViewed = "support_new_request_viewed"
    case supportNewRequestCreated = "support_new_request_created"
    case supportNewRequestFailed = "support_new_request_failed"
    case supportNewRequestFileAttached = "support_new_request_file_attached"
    case supportNewRequestFileAttachmentFailed = "support_new_request_file_attachment_failed"
    case supportTicketUserReplied = "support_ticket_user_replied"
    case supportTicketUserReplyFailed = "support_ticket_user_reply_failed"
    case supportTicketListViewed = "support_ticket_list_viewed"
    case supportTicketListViewFailed = "support_ticket_list_view_failed"
    case supportTicketUserViewed = "support_ticket_user_viewed"
    case supportTicketViewFailed = "support_ticket_view_failed"
    case supportHelpCenterUserSearched = "support_help_center_user_searched"
    case supportIdentityFormViewed = "support_identity_form_viewed"
    case supportIdentitySet = "support_identity_set"
    case supportSSROpened = "support_ssr_opened"
    case supportSSRCopyButtonTapped = "support_ssr_copy_button_tapped"

    // MARK: Settings Plugin List Events
    //
    case settingsPluginListTapped = "settings_plugin_list_tapped"
    case outOfDatePluginList = "out_of_date_plugin_list"

    // MARK: Settings View Events
    //
    case settingsTapped = "main_menu_settings_tapped"
    case settingsSelectedStoreTapped = "settings_selected_site_tapped"
    case settingsContactSupportTapped = "main_menu_contact_support_tapped"
    case settingsTroubleshootConnectionTapped = "settings_troubleshoot_connection_tapped"

    case settingsBetaFeaturesButtonTapped = "settings_beta_features_button_tapped"
    case settingsBetaFeaturesProductsToggled = "settings_beta_features_products_toggled"
    case settingsBetaFeaturesOrderAddOnsToggled = "settings_beta_features_order_addons_toggled"
    case settingsBetaFeaturesApplicationPasswordsToggled = "settings_beta_features_application_passwords_toggled"
    case settingsBetaFeaturesPOSLocalCatalogToggled = "settings_beta_features_pos_local_catalog_toggled"
    case settingsBetaFeatureToggled = "settings_beta_feature_toggled"

    case settingsPrivacySettingsTapped = "settings_privacy_settings_button_tapped"
    case settingsCollectInfoToggled = "privacy_settings_collect_info_toggled"
    case settingsReportCrashesToggled = "privacy_settings_crash_reporting_toggled"
    case settingsPrivacyPolicyTapped = "privacy_settings_privacy_policy_link_tapped"
    case settingsShareInfoLearnMoreTapped = "privacy_settings_share_info_link_tapped"
    case settingsThirdPartyLearnMoreTapped = "privacy_settings_third_party_tracking_info_link_tapped"
    case settingsLicensesLinkTapped = "settings_about_open_source_licenses_link_tapped"
    case settingsAboutLinkTapped = "settings_about_woocommerce_link_tapped"
    case settingsNotificationSettingsTapped = "settings_notification_settings_tapped"

    case settingsLogoutTapped = "settings_logout_button_tapped"
    case settingsLogoutConfirmation = "settings_logout_confirmation_dialog_result"
    case settingsWereHiringTapped = "settings_we_are_hiring_button_tapped"

    // MARK: Notification Settings
    //
    case notificationSettingsUpdateButtonTapped = "notification_settings_update_button_tapped"
    case notificationSettingsSaveButtonTapped = "notification_settings_save_button_tapped"
    case notificationSettingsSavingSuccess = "notification_settings_saving_success"
    case notificationSettingsSavingFailed = "notification_settings_saving_failed"

    // MARK: Card Reader Connection Events
    //
    case cardReaderSelectTypeShown = "card_present_select_reader_type_shown"
    case cardReaderSelectTypeTapToPayTapped = "card_present_select_reader_type_built_in_tapped"
    case cardReaderSelectTypeBluetoothTapped = "card_present_select_reader_type_bluetooth_tapped"
    case cardReaderDiscoveryFailed = "card_reader_discovery_failed"
    case cardReaderConnectionFailed = "card_reader_connection_failed"
    case cardReaderConnectionSuccess = "card_reader_connection_success"
    case cardReaderDisconnectTapped = "card_reader_disconnect_tapped"
    case manageCardReadersTapToPayReaderAutoDisconnect = "manage_card_readers_automatic_disconnect_built_in_reader"
    case cardReaderAutomaticDisconnect = "card_reader_automatic_disconnect"
    case cardReaderLocationPermissionPreAlertShown = "card_reader_location_permission_pre_alert_shown"
    case cardReaderLocationPermissionRequiredShown = "card_reader_location_permission_required_shown"

    // MARK: Card Reader Software Update Events
    //
    case cardReaderSoftwareUpdateTapped = "card_reader_software_update_tapped"
    case cardReaderSoftwareUpdateStarted = "card_reader_software_update_started"
    case cardReaderSoftwareUpdateSuccess = "card_reader_software_update_success"
    case cardReaderSoftwareUpdateFailed = "card_reader_software_update_failed"
    case cardReaderSoftwareUpdateCancelTapped = "card_reader_software_update_cancel_tapped"
    case cardReaderSoftwareUpdateCanceled = "card_reader_software_update_canceled"

    // MARK: Card-Present Payments Onboarding
    case cardPresentOnboardingLearnMoreTapped = "card_present_onboarding_learn_more_tapped"
    case cardPresentOnboardingCompleted = "card_present_onboarding_completed"
    case cardPresentOnboardingNotCompleted = "card_present_onboarding_not_completed"
    case cardPresentOnboardingStepSkipped = "card_present_onboarding_step_skipped"
    case cardPresentOnboardingCtaTapped = "card_present_onboarding_cta_tapped"
    case cardPresentOnboardingCtaFailed = "card_present_onboarding_cta_failed"

    // MARK: Tap to Pay
    case tapToPaySummaryTryPaymentTapped = "tap_to_pay_summary_try_payment_tapped"
    case tapToPaySummaryTryPaymentSkipTapped = "tap_to_pay_summary_try_payment_skip_tapped"
    case tapToPaySetupInformationSetUpTapped = "tap_to_pay_set_up_information_set_up_tapped"
    case tapToPaySetupInformationCancelTapped = "tap_to_pay_set_up_information_cancel_tapped"
    case tapToPaySetupOnboardingCancelTapped = "tap_to_pay_set_up_onboarding_cancel_tapped"
    case tapToPaySetupSuccessDoneTapped = "tap_to_pay_set_up_success_done_tapped"
    case tapToPaySummaryShown = "tap_to_pay_summary_shown"
    case aboutTapToPayOrderCardReaderTapped = "about_tap_to_pay_order_card_reader_tapped"
    case tapToPayAutoRefundSuccess = "card_present_tap_to_pay_test_payment_refund_success"
    case tapToPayAutoRefundFailed = "card_present_tap_to_pay_test_payment_refund_failed"
    case tapToPayAwarenessShown = "tap_to_pay_awareness_shown"
    case tapToPayTermsOfServiceAccepted = "tap_to_pay_terms_of_service_accepted"

    // MARK: Tap to Pay Education
    case tapToPayEducationShown = "tap_to_pay_education_shown"
    case tapToPayEducationDone = "tap_to_pay_education_done"
    case tapToPayEducationSkipped = "tap_to_pay_education_skipped"

    // MARK: Cash on Delivery Enable events
    case enableCashOnDeliverySuccess = "enable_cash_on_delivery_success"
    case enableCashOnDeliveryFailed = "enable_cash_on_delivery_failed"
    case disableCashOnDeliverySuccess = "disable_cash_on_delivery_success"
    case disableCashOnDeliveryFailed = "disable_cash_on_delivery_failed"
    case paymentsHubCashOnDeliveryToggled = "payments_hub_cash_on_delivery_toggled"
    case paymentsHubCashOnDeliveryToggleLearnMoreTapped = "payments_hub_cash_on_delivery_toggle_learn_more_tapped"

    // MARK: Payment Gateways selection
    case cardPresentPaymentGatewaySelected = "card_present_payment_gateway_selected"

    // MARK: Order View Events
    //
    case ordersSelected = "main_tab_orders_selected"
    case ordersReselected = "main_tab_orders_reselected"
    case ordersListPulledToRefresh = "orders_list_pulled_to_refresh"
    case ordersListSearchTapped = "orders_list_menu_search_tapped"
    case filterOrdersOptionSelected = "filter_orders_by_status_dialog_option_selected"
    case orderDetailAddNoteButtonTapped = "order_detail_add_note_button_tapped"
    case orderDetailPulledToRefresh = "order_detail_pulled_to_refresh"
    case orderNoteAddButtonTapped = "add_order_note_add_button_tapped"
    case orderNoteEmailCustomerToggled = "add_order_note_email_note_to_customer_toggled"
    case orderDetailAddTrackingButtonTapped = "order_detail_tracking_add_tracking_button_tapped"
    case orderDetailShowBillingTapped = "order_detail_customer_info_show_billing_tapped"
    case orderDetailCustomerAddressTapped = "order_detail_customer_address_tapped"
    case orderDetailCustomerAddressEditTapped = "order_detail_customer_address_edit_tapped"
    case orderDetailCustomerEmailMenuTapped = "order_detail_customer_info_email_menu_tapped"
    case orderDetailCustomerEmailOptionTapped = "order_detail_customer_info_email_option_tapped"
    case orderDetailCustomerEmailCopyOptionTapped = "order_detail_customer_info_email_copy_option_tapped"
    case orderDetailCustomerPhoneMenuTapped = "order_detail_customer_info_phone_menu_tapped"
    case orderDetailCustomerPhoneOptionTapped = "order_detail_customer_info_phone_menu_phone_tapped"
    case orderDetailCustomerSMSOptionTapped = "order_detail_customer_info_phone_menu_sms_tapped"
    case orderDetailCustomerCopyNumberOptionTapped = "order_detail_customer_info_phone_menu_copy_tapped"
    case orderDetailCustomerWhatsappOptionTapped = "order_detail_customer_info_phone_menu_whatsapp_tapped"
    case orderDetailCustomerTelegramOptionTapped = "order_detail_customer_info_phone_menu_telegram_tapped"
    case orderDetailOrderStatusEditButtonTapped = "order_detail_order_status_edit_button_tapped"
    case orderDetailRefundDetailTapped = "order_detail_refund_detail_tapped"
    case orderDetailAddOnsViewed = "order_detail_addons_viewed"
    case refundedProductsDetailTapped = "order_detail_refunded_products_detail_tapped"
    case orderDetailTrackPackageButtonTapped = "order_detail_track_package_button_tapped"
    case orderDetailTrackingDeleteButtonTapped = "order_detail_tracking_delete_button_tapped"
    case orderFulfillmentCompleteButtonTapped = "order_fulfillment_mark_order_complete_button_tapped"
    case orderMarkedCompleteUndoButtonTapped = "snack_order_marked_complete_undo_button_tapped"
    case orderShipmentTrackingAddButtonTapped = "order_shipment_tracking_add_button_tapped"
    case orderShipmentTrackingCarrierSelected = "order_shipment_tracking_carrier_selected"
    case orderShipmentTrackingCustomProviderSelected = "order_shipment_tracking_custom_provider_selected"
    case orderDetailEditFlowStarted = "order_detail_edit_flow_started"
    case orderDetailEditFlowCompleted = "order_detail_edit_flow_completed"
    case orderDetailEditFlowCanceled = "order_detail_edit_flow_canceled"
    case orderDetailEditFlowFailed = "order_detail_edit_flow_failed"
    case orderDetailPaymentLinkShared = "order_detail_payment_link_shared"
    case orderDetailTrashButtonTapped = "order_detail_trash_tapped"
    case orderDetailEditAddressMapPickerTapped = "order_detail_edit_address_map_picker_tapped"
    case orderDetailEditAddressMapPickerUseAddressTapped = "order_detail_edit_address_map_picker_use_address_tapped"

    // MARK: Test order
    //
    case orderListTestOrderDisplayed = "order_list_test_order_displayed"
    case orderListTryTestOrderTapped = "order_list_try_test_order_tapped"
    case testOrderStartTapped = "test_order_start_tapped"

    // MARK: Order Data/Action Events
    //
    case orderOpen = "order_open"
    case orderAddNew = "orders_add_new"
    case orderProductsLoaded = "order_products_loaded"
    case orderNotesLoaded = "order_notes_loaded"
    case orderNoteAdd = "order_note_add"
    case orderNoteAddSuccess = "order_note_add_success"
    case orderNoteAddFailed = "order_note_add_failed"
    case orderCreateButtonTapped = "order_create_button_tapped"
    case orderCreationSuccess = "order_creation_success"
    case orderCreationFailed = "order_creation_failed"
    case orderCreationCustomerAdded = "order_creation_customer_added"
    case orderCreationCustomerSearch = "order_creation_customer_search"
    case orderCreationCustomerAddManuallyTapped = "order_creation_customer_add_manually_tapped"
    case orderCreationProductSelectorItemSelected = "order_creation_product_selector_item_selected"
    case orderCreationProductSelectorItemUnselected = "order_creation_product_selector_item_unselected"
    case orderCreationProductSelectorConfirmButtonTapped = "order_creation_product_selector_confirm_button_tapped"
    case orderCreationProductSelectorClearSelectionButtonTapped = "order_creation_product_selector_clear_selection_button_tapped"
    case orderCreationProductSelectorSearchTriggered = "order_creation_product_selector_search_triggered"
    case orderCreationSetNewTaxRateTapped = "order_creation_set_new_tax_rate_tapped"
    case orderCreationStoredTaxRateBottomSheetAppear = "tax_rate_auto_tax_rate_bottom_sheet_displayed"
    case orderCreationSetNewTaxRateFromBottomSheetTapped = "tax_rate_auto_tax_rate_set_new_rate_for_order_tapped"
    case orderCreationAddCustomAmountTapped = "order_creation_add_custom_amount_tapped"
    case orderCreationEditCustomAmountTapped = "order_creation_edit_custom_amount_tapped"
    case orderCreationRemoveCustomAmountTapped = "order_creation_remove_custom_amount_tapped"
    case orderCreationClearAddressFromBottomSheetTapped = "tax_rate_auto_tax_rate_clear_address_tapped"
    case orderFormTotalsPanelToggled = "order_form_totals_panel_toggled"
    case orderContactAction = "order_contact_action"
    case orderCustomerAdd = "order_customer_add"
    case orderEditButtonTapped = "order_edit_button_tapped"
    case orderEditButtonTappedWhileDisabledForCurrencyConflict = "order_edit_button_tapped_while_disabled_for_currency_conflict"
    case ordersListFilter = "orders_list_filter"
    case ordersListSearch = "orders_list_search"
    case ordersListLoaded = "orders_list_loaded"
    case ordersListLoadError = "orders_list_load_error"
    case ordersListAutomaticTimeoutRetry = "orders_list_automatic_timeout_retry"
    case ordersListTopBannerTroubleshootTapped = "orders_list_top_banner_troubleshoot_tapped"
    case orderProductAdd = "order_product_add"
    case orderProductQuantityChange = "order_product_quantity_change"
    case orderProductRemove = "order_product_remove"
    case orderStatusChange = "order_status_change"
    case orderStatusChangeSuccess = "order_status_change_success"
    case orderStatusChangeFailed = "order_status_change_failed"
    case orderStatusChangeUndo = "order_status_change_undo"
    case orderTrackingAdd = "order_tracking_add"
    case orderTrackingAddFailed = "order_tracking_add_failed"
    case orderTrackingLoaded = "order_tracking_loaded"
    case orderTrackingAddSuccess = "order_tracking_add_success"
    case orderTrackingDelete = "order_tracking_delete"
    case orderTrackingDeleteFailed = "order_tracking_delete_failed"
    case orderTrackingDeleteSuccess = "order_tracking_delete_success"
    case orderTrackingProvidersLoaded = "order_tracking_providers_loaded"
    case orderFeeAdd = "order_fee_add"
    case orderFeeUpdate = "order_fee_update"
    case orderFeeRemove = "order_fee_remove"
    case orderCouponAdd = "order_coupon_add"
    case orderCouponRemove = "order_coupon_remove"
    case orderGoToCouponsButtonTapped = "order_go_to_coupons_button_tapped"
    case orderTaxHelpButtonTapped = "order_taxes_help_button_tapped"
    case orderProductDiscountAdd = "order_product_discount_add"
    case orderProductDiscountRemove = "order_product_discount_remove"
    case orderProductDiscountAddButtonTapped = "order_product_discount_add_button_tapped"
    case orderProductDiscountEditButtonTapped = "order_product_discount_edit_button_tapped"
    case orderAddShippingTapped = "order_add_shipping_tapped"
    case orderShippingMethodSelected = "order_shipping_method_selected"
    case orderShippingMethodAdd = "order_shipping_method_add"
    case orderShippingMethodRemove = "order_shipping_method_remove"
    case orderSyncFailed = "order_sync_failed"
    case orderFormAddGiftCardCTAShown = "order_form_add_gift_card_cta_shown"
    case orderFormAddGiftCardCTATapped = "order_form_add_gift_card_cta_tapped"
    case orderFormGiftCardSet = "order_form_gift_card_set"
    case collectPaymentTapped = "payments_flow_order_collect_payment_tapped"
    case orderViewCustomFieldsTapped = "order_view_custom_fields_tapped"
    case orderDetailWaitingTimeLoaded = "order_detail_waiting_time_loaded"
    case orderDetailsSubscriptionsShown = "order_details_subscriptions_shown"
    case orderDetailsGiftCardShown = "order_details_gift_card_shown"
    case orderDetailsShippingMethodsShown = "order_details_shipping_methods_shown"
    case orderFormBundleProductConfigureCTAShown = "order_form_bundle_product_configure_cta_shown"
    case orderFormBundleProductConfigureCTATapped = "order_form_bundle_product_configure_cta_tapped"
    case orderFormBundleProductConfigurationChanged = "order_form_bundle_product_configuration_changed"
    case orderFormBundleProductConfigurationSaveTapped = "order_form_bundle_product_configuration_save_tapped"

    // MARK: Custom amounts
    case addCustomAmountDoneButtonTapped = "add_custom_amount_done_tapped"
    case addCustomAmountNameAdded = "add_custom_amount_name_added"
    case addCustomAmountPercentageAdded = "add_custom_amount_percentage_added"

    // MARK: Order Tax Educational Dialog
    //
    case taxEducationalDialogEditInAdminButtonTapped = "tax_educational_dialog_edit_in_admin_button_tapped"

    // MARK: Order List Sorting/Filtering
    //
    case orderListViewFilterOptionsTapped = "order_list_view_filter_options_tapped"

    // MARK: Filter History
    //
    case filterHistoryButtonTapped = "filter_history_button_tapped"
    case filterHistoryPastFilterApplied = "filter_history_past_filter_applied"
    case filterHistoryPastFilterRemoved = "filter_history_past_filter_removed"
    case filterHistoryCleared = "filter_history_cleared"

    // MARK: Barcode Scanning events
    //
    case orderCreationProductBarcodeScanningTapped = "order_creation_product_barcode_scanning_tapped"
    case orderListProductBarcodeScanningTapped = "order_list_product_barcode_scanning_tapped"
    case barcodeScanningSuccess = "barcode_scanning_success"
    case barcodeScanningFailure = "barcode_scanning_failure"
    case orderProductSearchViaSKUSuccess = "product_search_via_sku_success"
    case orderProductSearchViaGlobalUniqueIdentifierSuccess = "product_search_via_global_unique_identifier_success"
    case orderProductSearchViaSKUFailure = "product_search_via_sku_failure"

    // MARK: Tax Rate selector
    //
    case taxRateSelectorTaxRateTapped = "tax_rate_selector_tax_rate_tapped"
    case taxRateSelectorEditInAdminTapped = "tax_rate_selector_edit_in_admin_tapped"

    // MARK: Cash Payment Tender View Events
    //
    case cashPaymentTenderViewOnMarkOrderAsCompleteButtonTapped = "cash_payment_tender_view_on_mark_order_as_complete_button_tapped"

    // MARK: Shipping Labels Events
    //
    case shippingLabelRefundRequested = "shipping_label_refund_requested"
    case shippingLabelReprintRequested = "shipping_label_print_requested"
    case shipmentTrackingMenuAction = "shipment_tracking_menu_action"
    case shippingLabelsAPIRequest = "shipping_label_api_request"

    // MARK: Shipping Label Hazmat Events
    //
    case containsHazmatChecked = "contains_hazmat_checked"
    case hazmatCategorySelectorOpened = "hazmat_category_selector_opened"
    case hazmatCategorySelected = "hazmat_category_selected"

    // MARK: Shipping Labels Creation Events
    //
    case shippingLabelOrderIsEligible = "shipping_label_order_is_eligible"
    case shippingLabelPurchaseFlow = "shipping_label_purchase_flow"
    case shippingLabelOrderFulfillSucceeded = "shipping_label_order_fulfill_succeeded"
    case shippingLabelOrderFulfillFailed = "shipping_label_order_fulfill_failed"
    case shippingLabelDiscountInfoButtonTapped = "shipping_label_discount_info_button_tapped"
    case shippingLabelEditAddressOpenMapButtonTapped = "shipping_label_edit_address_open_map_button_tapped"
    case shippingLabelEditAddressDoneButtonTapped = "shipping_label_edit_address_done_button_tapped"
    case shippingLabelEditAddressUseAddressAsIsButtonTapped = "shipping_label_edit_address_use_address_as_is_button_tapped"
    case shippingLabelEditAddressContactCustomerButtonTapped = "shipping_label_edit_address_contact_customer_button_tapped"
    case shippingLabelAddressSuggestionsUseSelectedAddressButtonTapped = "shipping_label_address_suggestions_use_selected_address_button_tapped"
    case shippingLabelAddressSuggestionsEditSelectedAddressButtonTapped = "shipping_label_address_suggestions_edit_selected_address_button_tapped"
    case shippingLabelAddressValidationFailed = "shipping_label_address_validation_failed"
    case shippingLabelAddressValidationSucceeded = "shipping_label_address_validation_succeeded"
    case shippingLabelAddPackageTapped = "shipping_label_add_package_tapped"
    case shippingLabelPackageAddedSuccessfully = "shipping_label_package_added_successfully"
    case shippingLabelAddPackageFailed = "shipping_label_add_package_failed"
    case shippingLabelAddPaymentMethodTapped = "shipping_label_add_payment_method_tapped"
    case shippingLabelPaymentMethodAdded = "shipping_label_payment_method_added"
    case shippingLabelMoveItemTapped = "shipping_label_move_item_tapped"
    case shippingLabelItemMoved = "shipping_label_item_moved"
    case euShippingNoticeShown = "eu_shipping_notice_shown"
    case euShippingNoticeDismissed = "eu_shipping_notice_dismissed"
    case euShippingNoticeLearnMoreTapped = "eu_shipping_notice_learn_more_tapped"

    // MARK: Receipt Events
    //
    case receiptViewTapped = "receipt_view_tapped"
    case receiptEmailTapped = "receipt_email_tapped"
    case receiptEmailFailed = "receipt_email_failed"
    case receiptEmailCanceled = "receipt_email_canceled"
    case receiptEmailSuccess = "receipt_email_success"
    case receiptPrintTapped = "receipt_print_tapped"
    case receiptPrintFailed = "receipt_print_failed"
    case receiptPrintCanceled = "receipt_print_canceled"
    case receiptPrintSuccess = "receipt_print_success"
    case receiptFetchFailed = "receipt_url_fetching_fails"

    // MARK: Payment Events
    //
    case collectPaymentCanceled = "card_present_collect_payment_canceled"
    case collectPaymentFailed = "card_present_collect_payment_failed"
    case collectPaymentSuccess = "card_present_collect_payment_success"
    case collectInteracPaymentSuccess = "card_interac_collect_payment_success"
    case interacRefundSuccess = "interac_refund_success"
    case interacRefundFailed = "interac_refund_failed"
    case interacRefundCanceled = "interac_refund_cancelled"

    // MARK: Push Notifications Events
    case pushNotificationReceived = "push_notification_received"
    case pushNotificationAlertPressed = "push_notification_alert_pressed"
    case pushNotificationOSAlertAllowed = "push_notification_os_alert_allowed"
    case pushNotificationOSAlertDenied = "push_notification_os_alert_denied"
    case pushNotificationOSAlertShown = "push_notification_os_alert_shown"
    case viewInAppPushNotificationPressed = "view_in_app_push_notification_pressed"

    case wooPushTokenRegisterSuccess = "woo_push_token_register_success"
    case wooPushTokenRegisterError = "woo_push_token_register_error"
    case wpcomDeviceDisablePushNotificationsSuccess = "wpcom_device_disable_push_notifications_success"
    case wpcomDeviceDisablePushNotificationsError = "wpcom_device_disable_push_notifications_error"

    case pushNotificationsCardView = "push_notifications_card_view"
    case settingsPushNotificationsButtonTap = "settings_push_notifications_button_tap"
    case pushNotificationsSetupIntroductionView = "push_notifications_setup_introduction_view"
    case pushNotificationsSetupIntroductionButtonTap = "push_notifications_setup_introduction_button_tap"
    case pushNotificationsSetupIntroductionLinkTap = "push_notifications_setup_introduction_link_tap"
    case pushNotificationsSetupIntroductionClose = "push_notifications_setup_introduction_close"
    case pushNotificationsSetupIntroductionError = "push_notifications_setup_introduction_error"
    case pushNotificationsSetupFlowSuccess = "push_notifications_setup_flow_success"
    case pushNotificationsSetupFlowButtonTap = "push_notifications_setup_flow_button_tap"
    case pushNotificationsSetupFlowClose = "push_notifications_setup_flow_close"
    case pushNotificationsSetupFlowError = "push_notifications_setup_flow_error"

    // MARK: Notification View Events
    //
    case notificationOpened = "notification_open"
    case notificationsListPulledToRefresh = "notifications_list_pulled_to_refresh"
    case notificationsListReadAllTapped = "notifications_list_menu_mark_read_button_tapped"
    case notificationsListFilterTapped = "notifications_list_menu_filter_tapped"
    case filterNotificationsOptionSelected = "filter_notifications_by_status_dialog_option_selected"
    case notificationReviewApprovedTapped = "review_detail_approve_button_tapped"
    case notificationReviewTrashTapped = "review_detail_trash_button_tapped"
    case notificationReviewSpamTapped = "review_detail_spam_button_tapped"
    case notificationShareStoreButtonTapped = "notifications_share_your_store_button_tapped"

    // MARK: Review View Events
    //
    case reviewsListPulledToRefresh = "reviews_list_pulled_to_refresh"
    case reviewsListReadAllTapped = "reviews_list_menu_mark_read_button_tapped"
    case reviewsShareStoreButtonTapped = "reviews_share_your_store_button_tapped"

    // MARK: Notification Data/Action Events
    //
    case notificationListLoaded = "notifications_loaded"
    case notificationsLoadFailed = "notifications_load_failed"
    case notificationListFilter = "notifications_filter"
    case notificationReviewAction = "review_action"
    case notificationReviewActionSuccess = "review_action_success"
    case notificationReviewActionFailed = "review_action_failed"
    case notificationReviewActionUndo = "review_action_undo"

    // MARK: Review Data/Action Events
    //
    case reviewOpen = "review_open"
    case reviewLoaded = "review_loaded"
    case reviewLoadFailed = "review_load_failed"
    case reviewMarkRead = "review_mark_read"
    case reviewMarkReadSuccess = "review_mark_read_success"
    case reviewMarkReadFailed = "review_mark_read_failed"
    case reviewsListLoaded = "reviews_loaded"
    case reviewsListLoadFailed = "reviews_load_failed"
    case reviewsMarkAllRead = "reviews_mark_all_read"
    case reviewsMarkAllReadSuccess = "reviews_mark_all_read_success"
    case reviewsMarkAllReadFailed = "reviews_mark_all_read_failed"
    case reviewsProductsLoaded = "reviews_products_loaded"
    case reviewsProductsLoadFailed = "reviews_products_load_failed"
    case reviewReplySend = "review_reply_send"
    case reviewReplySendSuccess = "review_reply_send_success"
    case reviewReplySendFailed = "review_reply_send_failed"

    // MARK: Product List Events
    //
    case productListSelected = "main_tab_products_selected"
    case productListReselected = "main_tab_products_reselected"
    case productListLoaded = "product_list_loaded"
    case productListLoadError = "product_list_load_error"
    case productListProductTapped = "product_list_product_tapped"
    case productListPulledToRefresh = "product_list_pulled_to_refresh"
    case productListSearched = "product_list_searched"
    case productListMenuSearchTapped = "product_list_menu_search_tapped"
    case productListAddProductTapped = "product_list_add_product_button_tapped"
    case productListClearFiltersTapped = "product_list_clear_filters_button_tapped"
    case productListShareButtonTapped = "product_list_share_button_tapped"

    // MARK: Product List - Scan to Update Inventory
    //
    case productListProductBarcodeScanningTapped = "product_list_product_barcode_scanning_tapped"
    case inventoryUpdateIncrementQuantityTapped = "product_quick_inventory_update_increment_quantity_tapped"
    case inventoryUpdateManualQuantityTapped = "product_quick_inventory_update_manual_quantity_update_tapped"
    case inventoryUpdateDismissed = "product_quick_inventory_update_dismissed"
    case inventoryUpdateQuantityUpdateSuccess = "product_quick_inventory_quantity_update_success"
    case inventoryUpdateQuantityUpdateFailure = "product_quick_inventory_quantity_update_failure"
    case inventoryUpdateViewProductDetailsTapped = "product_quick_inventory_view_product_details_tapped"
    case inventoryUpdateEnableManageStockSuccess = "product_quick_inventory_enable_manage_stock_success"
    case inventoryUpdateEnableManageStockFailure = "product_quick_inventory_enable_manage_stock_failure"

    // MARK: Product List Bulk Editing Events
    //
    case productListBulkUpdateRequested = "product_list_bulk_update_requested"
    case productListBulkUpdateConfirmed = "product_list_bulk_update_confirmed"
    case productListBulkUpdateSuccess = "product_list_bulk_update_success"
    case productListBulkUpdateFailure = "product_list_bulk_update_failure"
    case productListBulkUpdateSelectAllTapped = "product_list_bulk_update_select_all_tapped"

    // MARK: Add Product Events
    //
    case addProductStarted = "add_product_started"
    case addProductCreationTypeSelected = "add_product_creation_type_selected"
    case addProductTypeSelected = "add_product_product_type_selected"
    case addProductPublishTapped = "add_product_publish_tapped"
    case addProductSaveAsDraftTapped = "add_product_save_as_draft_tapped"
    case addProductSuccess = "add_product_success"
    case addProductFailed = "add_product_failed"

    // MARK: Duplicate Product events
    case duplicateProductSuccess = "duplicate_product_success"
    case duplicateProductFailed = "duplicate_product_failed"

    // MARK: Edit Product Events
    //
    case productDetailLoaded = "product_detail_loaded"
    case productDetailUpdateButtonTapped = "product_detail_update_button_tapped"
    case productDetailUpdateSuccess = "product_detail_update_success"
    case productDetailUpdateError = "product_detail_update_error"
    case productDetailViewProductNameTapped = "product_detail_view_product_name_tapped"
    case productDetailViewProductDescriptionTapped = "product_detail_view_product_description_tapped"
    case productDetailViewPriceSettingsTapped = "product_detail_view_price_settings_tapped"
    case productDetailViewShippingSettingsTapped = "product_detail_view_shipping_settings_tapped"
    case productDetailViewInventorySettingsTapped = "product_detail_view_inventory_settings_tapped"
    case productDetailViewCategoriesTapped = "product_detail_view_categories_tapped"
    case productDetailViewTagsTapped = "product_detail_view_tags_tapped"
    case productDetailViewReviewsTapped = "product_detail_view_product_reviews_tapped"
    case productDetailViewProductTypeTapped = "product_detail_view_product_type_tapped"
    case productDetailViewGroupedProductsTapped = "product_detail_view_grouped_products_tapped"
    case productDetailViewExternalProductLinkTapped = "product_detail_view_external_product_link_tapped"
    case productDetailViewSKUTapped = "product_detail_view_sku_tapped"
    case productDetailViewVariationsTapped = "product_detail_view_product_variants_tapped"
    case productDescriptionDoneButtonTapped = "product_description_done_button_tapped"
    case productPriceSettingsDoneButtonTapped = "product_price_settings_done_button_tapped"
    case productShippingSettingsDoneButtonTapped = "product_shipping_settings_done_button_tapped"
    case productInventorySettingsDoneButtonTapped = "product_inventory_settings_done_button_tapped"
    case productDetailViewDownloadableFilesTapped = "product_detail_view_downloadable_files_tapped"
    case productDetailViewLinkedProductsTapped = "product_detail_view_linked_products_tapped"
    case productDetailProductDeleted = "product_detail_product_deleted"
    case productDetailViewProductAddOnsTapped = "product_detail_view_product_addons_tapped"
    case productInventorySettingsSKUScannerButtonTapped = "product_inventory_settings_sku_scanner_button_tapped"
    case productInventorySettingsSKUScanned = "product_inventory_settings_sku_scanned"
    case productInventorySettingsGlobalUniqueIDScannerButtonTapped = "product_inventory_settings_global_unique_id_scanner_button_tapped"
    case productInventorySettingsGlobalUniqueIDScanned = "product_inventory_settings_global_unique_id_scanned"
    case productInventorySettingsGlobalUniqueIDFieldEdited = "product_inventory_settings_global_unique_identifier_field_edited"
    case productDetailPreviewTapped = "product_detail_preview_tapped"
    case productDetailPreviewFailed = "product_detail_preview_failed"
    case productDetailViewBundledProductsTapped = "product_detail_view_bundled_products_tapped"
    case productDetailViewComponentsTapped = "product_details_view_components_tapped"
    case productDetailViewQuantityRulesTapped = "product_detail_view_quantity_rules_tapped"

    // MARK: Edit Product Variation Events
    //
    case productVariationDetailViewDescriptionTapped = "product_variation_view_variation_description_tapped"
    case productVariationDetailViewImageTapped = "product_variation_image_tapped"
    case productVariationDetailViewStatusSwitchTapped = "product_variation_view_variation_visibility_switch_tapped"
    case productVariationDetailViewPriceSettingsTapped = "product_variation_view_price_settings_tapped"
    case productVariationDetailViewInventorySettingsTapped = "product_variation_view_inventory_settings_tapped"
    case productVariationDetailViewShippingSettingsTapped = "product_variation_view_shipping_settings_tapped"
    case productVariationDetailUpdateButtonTapped = "product_variation_update_button_tapped"
    case productVariationDetailUpdateSuccess = "product_variation_update_success"
    case productVariationDetailUpdateError = "product_variation_update_error"
    case productVariationDetailViewQuantityRulesTapped = "product_variation_view_quantity_rules_tapped"

    case productVariationBulkUpdateSectionTapped = "product_variation_bulk_update_section_tapped"
    case productVariationBulkUpdateFieldTapped = "product_variation_bulk_update_field_tapped"
    case productVariationBulkUpdateFieldSuccess = "product_variation_bulk_update_field_success"
    case productVariationBulkUpdateFieldFail = "product_variation_bulk_update_field_fail"

    // MARK: Woo Subscriptions product Events
    //
    case productDetailsViewSubscriptionExpirationDateTapped = "product_details_view_subscription_expiration_date_tapped"
    case productDetailsViewSubscriptionFreeTrialTapped = "product_details_view_subscription_free_trial_tapped"
    case productVariationViewSubscriptionExpirationDateTapped = "product_variation_view_subscription_expiration_date_tapped"
    case productVariationViewSubscriptionFreeTrialTapped = "product_variation_view_subscription_free_trial_tapped"
    case productSubscriptionExpirationDoneButtonTapped = "product_subscription_expiration_done_button_tapped"
    case productSubscriptionFreeTrialDoneButtonTapped = "product_subscription_free_trial_done_button_tapped"

    // MARK: Quantity Rules product Events
    case productDetailsViewQuantityRulesDoneButtonTapped = "product_detail_quantity_rules_done_button_tapped"
    case productVariationDetailsViewQuantityRulesDoneButtonTapped = "product_variation_quantity_rules_done_button_tapped"


    // MARK: Product Images Events
    //
    case productImageSettingsDoneButtonTapped = "product_image_settings_done_button_tapped"
    case productDetailAddImageTapped = "product_detail_add_image_tapped"
    case productImageSettingsAddImagesButtonTapped = "product_image_settings_add_images_button_tapped"
    case productImageSettingsAddImagesSourceTapped = "product_image_settings_add_images_source_tapped"
    case productImageSettingsDeleteImageButtonTapped = "product_image_settings_delete_image_button_tapped"
    case productImageUploadFailed = "product_image_upload_failed"
    case productImageUploadRetryButtonTapped = "product_image_upload_retry_button_tapped"
    case savingProductAfterBackgroundImageUploadSuccess = "saving_product_after_background_image_upload_success"
    case savingProductAfterBackgroundImageUploadFailed = "saving_product_after_background_image_upload_failed"
    case failureSavingProductAfterImageUploadNoticeShown = "failure_saving_product_after_image_upload_notice_shown"
    case failureSavingProductAfterImageUploadNoticeTapped = "failure_saving_product_after_image_upload_notice_tapped"
    case failureUploadingImageNoticeShown = "failure_uploading_image_notice_shown"
    case failureUploadingImageNoticeTapped = "failure_uploading_image_notice_tapped"

    // Product Categories Events
    //
    case productCategoryListLoaded = "product_categories_loaded"
    case productCategoryListLoadFailed = "product_categories_load_failed"
    case productCategorySettingsDoneButtonTapped = "product_category_settings_done_button_tapped"
    case productCategorySettingsAddButtonTapped = "product_category_settings_add_button_tapped"
    case productCategorySettingsSaveNewCategoryTapped = "add_product_category_save_tapped"
    case productCategorySettingsDeleteButtonTapped = "product_category_settings_delete_button_tapped"
    case productCategorySettingsEditButtonTapped = "product_category_settings_edit_button_tapped"

    // Product Tags Events
    //
    case productTagListLoaded = "product_tags_loaded"
    case productTagListLoadFailed = "product_tags_load_failed"
    case productTagSettingsDoneButtonTapped = "product_tag_settings_done_button_tapped"

    // Product Reviews Events
    //
    case productReviewListLoaded = "product_reviews_loaded"
    case productReviewListLoadFailed = "product_reviews_load_failed"

    // Edit Linked and Grouped Products Events
    //
    case connectedProductsList = "connected_products_list"
    case linkedProducts = "linked_products"

    // Edit Downloadable Products Events
    case productDownloadableFilesSettingsChanged = "product_downloadable_files_settings_changed"
    case productsDownloadableFile = "products_downloadable_file"
    case productDownloadableOnDeviceMediaSelected = "product_downloadable_on_device_media_selected"
    case productDownloadableDocumentSelected = "product_downloadable_document_selected"
    case productDownloadableFileUploadingSuccess = "product_downloadable_file_uploading_success"
    case productDownloadableFileUploadingFailed = "product_downloadable_file_uploading_failed"

    // Edit External/Affiliate Product Event
    //
    case externalProductLinkSettingsDoneButtonTapped = "external_product_link_settings_done_button_tapped"

    // Edit Product SKU Events
    //
    case productSKUDoneButtonTapped = "product_sku_done_button_tapped"

    // Product Type Event
    //
    case productTypeChanged = "product_type_change_tapped"

    // Product More Menu
    //
    case productDetailViewProductButtonTapped = "product_detail_view_external_tapped"
    case productDetailShareButtonTapped = "product_detail_share_button_tapped"
    case productDetailMarkAsFavoriteButtonTapped = "product_detail_mark_as_favorite_tapped"
    case productDetailRemoveFromFavoriteButtonTapped = "product_detail_remove_from_favorite_tapped"

    // MARK: Product Settings
    //
    case productDetailViewSettingsButtonTapped = "product_detail_view_settings_button_tapped"
    case productDetailDuplicateButtonTapped = "product_detail_duplicate_button_tapped"
    case productSettingsDoneButtonTapped = "product_settings_done_button_tapped"
    case productSettingsStatusTapped = "product_settings_status_tapped"
    case productSettingsVisibilityTapped = "product_settings_visibility_tapped"
    case productSettingsCatalogVisibilityTapped = "product_settings_catalog_visibility_tapped"
    case productDetailViewShortDescriptionTapped = "product_detail_view_short_description_tapped"
    case productShortDescriptionDoneButtonTapped = "product_short_description_done_button_tapped"
    case productSettingsSlugTapped = "product_settings_slug_tapped"
    case productSettingsPurchaseNoteTapped = "product_settings_purchase_note_tapped"
    case productSettingsMenuOrderTapped = "product_settings_menu_order_tapped"
    case productSettingsVirtualToggled = "product_settings_virtual_toggled"
    case productSettingsReviewsToggled = "product_settings_reviews_toggled"

    // MARK: Product List Sorting/Filtering
    //
    case productListViewSortingOptionsTapped = "product_list_view_sorting_options_tapped"
    case productSortingListOptionSelected = "product_sorting_list_option_selected"
    case productListViewFilterOptionsTapped = "product_list_view_filter_options_tapped"
    case productFilterListShowProductsButtonTapped = "product_filter_list_show_products_button_tapped"
    case productFilterListClearMenuButtonTapped = "product_filter_list_clear_menu_button_tapped"
    case productFilterListDismissButtonTapped = "product_filter_list_dismiss_button_tapped"
    case productFilterListExploreButtonTapped = "product_filter_list_explore_button_tapped"

    // MARK: Readonly Product Variations Events
    //
    case productVariationListLoaded = "product_variants_loaded"
    case productVariationListLoadError = "product_variants_load_error"
    case productVariationListPulledToRefresh = "product_variants_pulled_to_refresh"
    case productVariationListVariationTapped = "product_variation_view_variation_detail_tapped"

    // MARK: Aztec editor
    //
    case aztecEditorDoneButtonTapped = "aztec_editor_done_button_tapped"

    // MARK: Product description AI
    //
    case productDescriptionAIButtonTapped = "product_description_ai_button_tapped"
    case productDescriptionAIGenerateButtonTapped = "product_description_ai_generate_button_tapped"
    case productDescriptionAIPauseButtonTapped = "product_description_ai_pause_button_tapped"
    case productDescriptionAIApplyButtonTapped = "product_description_ai_apply_button_tapped"
    case productDescriptionAICopyButtonTapped = "product_description_ai_copy_button_tapped"
    case productDescriptionAIGenerationSuccess = "product_description_ai_generation_success"
    case productDescriptionAIGenerationFailed = "product_description_ai_generation_failed"

    // MARK: First created product events
    case firstCreatedProductShown = "first_created_product_shown"
    case firstCreatedProductShareTapped = "first_created_product_share_tapped"

    // MARK: POS Promotion Modal
    case posPromoModalViewed = "pos_promo_modal_viewed"
    case posPromoModalSlideViewed = "pos_promo_modal_slide_viewed"
    case posPromoModalDismissed = "pos_promo_modal_dismissed"
    case posPromoModalExploreClicked = "pos_promo_modal_explore_clicked"

    // MARK: POS Promotion Banner
    case posPromotionBannerDisplayed = "pos_promotion_banner_displayed"
    case posPromotionBannerCtaTapped = "pos_promotion_banner_cta_tapped"
    case posPromotionBannerDismissed = "pos_promotion_banner_dismissed"

    // MARK: Product sharing AI
    //
    case productSharingAIDisplayed = "product_sharing_ai_displayed"
    case productSharingAIGenerateTapped = "product_sharing_ai_generate_tapped"
    case productSharingAIShareTapped = "product_sharing_ai_share_tapped"
    case productSharingAIDismissed = "product_sharing_ai_dismissed"
    case productSharingAIMessageGenerated = "product_sharing_ai_message_generated"
    case productSharingAIMessageGenerationFailed = "product_sharing_ai_message_generation_failed"

    // MARK: AI Identify Language
    //
    case identifyLanguageSuccess = "ai_identify_language_success"
    case identifyLanguageFailed = "ai_identify_language_failed"

    // MARK: Product AI Feedback
    //
    case productAIFeedback = "product_ai_feedback"

    // MARK: Product name AI
    //
    case productNameAIEntryPointTapped = "product_name_ai_entry_point_tapped"
    case productNameAIGenerateButtonTapped = "product_name_ai_generate_button_tapped"
    case productNameAICopyButtonTapped = "product_name_ai_copy_button_tapped"
    case productNameAIApplyButtonTapped = "product_name_ai_apply_button_tapped"
    case productNameAIGenerationSuccess = "product_name_ai_generation_success"
    case productNameAIGenerationFailed = "product_name_ai_generation_failed"

    // MARK: Product creation AI
    //
    case productCreationAIEntryPointDisplayed = "product_creation_ai_entry_point_displayed"
    case productCreationAIEntryPointTapped = "product_creation_ai_entry_point_tapped"
    case productCreationAIProductNameContinueTapped = "product_creation_ai_product_name_continue_button_tapped"
    case productCreationAIToneSelected = "product_creation_ai_tone_selected"
    case productCreationAIGenerateDetailsTapped = "product_creation_ai_generate_details_tapped"
    case productCreationAIGenerateProductDetailsSuccess = "product_creation_ai_generate_product_details_success"
    case productCreationAIGenerateProductDetailsFailed = "product_creation_ai_generate_product_details_failed"
    case productCreationAISaveAsDraftButtonTapped = "product_creation_ai_save_as_draft_button_tapped"
    case productCreationAISaveAsDraftSuccess = "product_creation_ai_save_as_draft_success"
    case productCreationAISaveAsDraftFailed = "product_creation_ai_save_as_draft_failed"
    case productCreationAISurveyConfirmationViewDisplayed = "product_creation_ai_survey_confirmation_view_displayed"
    case productCreationAISurveyStartSurveyButtonTapped = "product_creation_ai_survey_start_survey_button_tapped"
    case productCreationAISurveySkipButtonTapped = "product_creation_ai_survey_skip_button_tapped"

    // V2 events
    case productCreationAIStartedPackagePhotoSelectionFlow = "product_creation_ai_started_package_photo_selection_flow"
    case productCreationAITextDetected = "product_creation_ai_text_detected"
    case productCreationAITextDetectionFailed = "product_creation_ai_text_detection_failed"
    case productCreationAIGeneratedNameDescriptionOptions = "product_creation_ai_generated_name_description_options"
    case productCreationAIUndoEditTapped = "product_creation_ai_undo_edit_tapped"

    // MARK: Remote Request Events
    //
    case jetpackTunnelTimeout = "jetpack_tunnel_timeout"
    case apiJSONParsingError = "api_json_parsing_error"

    // MARK: In-app Feedback and Survey Events
    //
    // (https://git.io/JJpb2)
    //
    case appFeedbackPrompt = "app_feedback_prompt"
    case surveyScreen = "survey_screen"
    case featureFeedbackBanner = "feature_feedback_banner"

    // MARK: Issue Refund events
    //
    case refundCreate = "refund_create"
    case refundCreateFailed = "refund_create_failed"
    case refundCreateSuccess = "refund_create_success"
    case createOrderRefundSelectAllItemsButtonTapped = "create_order_refund_select_all_items_button_tapped"
    case createOrderRefundItemQuantityDialogOpened = "create_order_refund_item_quantity_dialog_opened"
    case createOrderRefundNextButtonTapped = "create_order_refund_next_button_tapped"
    case createOrderRefundSummaryRefundButtonTapped = "create_order_refund_summary_refund_button_tapped"
    case createOrderRefundShippingOptionTapped = "create_order_refund_shipping_option_tapped"

    // MARK: Add Variations events
    //
    case addFirstVariationButtonTapped = "add_first_variation_button_tapped"
    case addMoreVariationsButtonTapped = "add_more_variations_button_tapped"
    case createProductVariation = "create_product_variation"
    case createProductVariationSuccess = "create_product_variation_success"
    case createProductVariationFailed = "create_product_variation_fail"
    case removeProductVariationButtonTapped = "remove_product_variation_button_tapped"
    case editProductAttributesButtonTapped = "edit_product_attributes_button_tapped"
    case addProductAttributeButtonTapped = "add_product_attribute_button_tapped"
    case updateProductAttribute = "create_product_attribute"
    case updateProductAttributeSuccess = "update_product_attribute_success"
    case updateProductAttributeFail = "update_product_attribute_fail"
    case renameProductAttributeButtonTapped = "rename_product_attribute_button_tapped"
    case removeProductAttributeButtonTapped = "remove_product_attribute_button_tapped"
    case editProductVariationAttributeOptionsRowTapped = "edit_product_variation_attribute_options_row_tapped"
    case editProductVariationAttributeOptionsDoneButtonTapped = "edit_product_variation_attribute_options_done_button_tapped"

    case productVariationGenerationRequested = "product_variation_generation_requested"
    case productVariationGenerationLimitReached = "product_variation_generation_limit_reached"
    case productVariationGenerationConfirmed = "product_variation_generation_confirmed"
    case productVariationGenerationSuccess = "product_variation_generation_success"
    case productVariationGenerationFailure = "product_variation_generation_failure"

    // MARK: What's New Component events
    //
    case featureAnnouncementShown = "feature_announcement_shown"

    // MARK: Feature Card events
    case featureCardShown = "feature_card_shown"
    case featureCardDismissed = "feature_card_dismissed"
    case featureCardCtaTapped = "feature_card_cta_tapped"

    // MARK: In-Person Payments survey feedback events
    case inPersonPaymentsBannerShown = "survey_banner_shown"
    case inPersonPaymentsBannerTapped = "survey_banner_cta_tapped"
    case inPersonPaymentsBannerDismissed = "survey_banner_dismissed"

    // MARK: Just In Time Messages events
    case justInTimeMessageCallToActionTapped = "jitm_cta_tapped"
    case justInTimeMessageDismissTapped = "jitm_dismissed"
    case justInTimeMessageDismissSuccess = "jitm_dismiss_success"
    case justInTimeMessageDismissFailure = "jitm_dismiss_failure"
    case justInTimeMessageFetchSuccess = "jitm_fetch_success"
    case justInTimeMessageFetchFailure = "jitm_fetch_failure"
    case justInTimeMessageDisplayed = "jitm_displayed"

    // MARK: Simple Payments events
    //
    case simplePaymentsFlowNoteAdded = "simple_payments_flow_note_added"
    case simplePaymentsFlowTaxesToggled = "simple_payments_flow_taxes_toggled"
    case simplePaymentsMigrationSheetAddCustomAmount = "simple_payments_migration_sheet_add_custom_amount"
    case simplePaymentsMigrationSheetShown = "simple_payments_migration_sheet_shown"

    // MARK: Payment Methods events
    //
    case paymentsFlowCompleted = "payments_flow_completed"
    case paymentsFlowCanceled = "payments_flow_canceled"
    case paymentsFlowFailed = "payments_flow_failed"
    case paymentsFlowCollect = "payments_flow_collect"

    // MARK: Jetpack-the-plugin events
    //
    case jetpackBenefitsBanner = "feature_jetpack_benefits_banner"
    case jetpackInstallButtonTapped = "jetpack_install_button_tapped"
    case jetpackCPSitesFetched = "jetpack_cp_sites_fetched"
    case jetpackInstallGetStartedButtonTapped = "jetpack_install_get_started_button_tapped"
    case jetpackInstallSucceeded = "jetpack_install_succeeded"
    case jetpackInstallFailed = "jetpack_install_failed"
    case jetpackInstallInWPAdminButtonTapped = "jetpack_install_in_wpadmin_button_tapped"
    case jetpackInstallContactSupportButtonTapped = "jetpack_install_contact_support_button_tapped"
    case jetpackBenefitsModalWPAdminButtonTapped = "jetpack_benefits_modal_wpadmin_button_tapped"

    // MARK: - Bookings (error events only — other booking events use EventHorizon codegen)
    case bookingListFailedToFetchBookings = "booking_list_failed_to_fetch_bookings"
    case bookingListFailedToUpdateBookingDetails = "booking_list_failed_to_update_booking_details"

    // MARK: Hub Menu
    //
    case hubMenuTabSelected = "main_tab_hub_menu_selected"
    case hubMenuTabReselected = "main_tab_hub_menu_reselected"
    case hubMenuSwitchStoreTapped = "hub_menu_switch_store_tapped"
    case hubMenuOptionTapped = "hub_menu_option_tapped"
    case hubMenuSettingsTapped = "hub_menu_settings_tapped"

    // MARK: Coupons
    case couponsLoaded = "coupons_loaded"
    case couponsLoadedFailed = "coupons_loaded_failed"
    case couponsListSearchTapped = "coupons_list_search_tapped"
    case couponsListCreateTapped = "coupons_list_create_tapped"
    case couponDetails = "coupon_details"
    case couponSettingDisabled = "coupon_settings_disabled"
    case couponSettingEnabled = "coupon_settings_enabled"
    case couponDeleteSuccess = "coupon_delete_success"
    case couponDeleteFailed = "coupon_delete_failed"
    case couponUpdateInitiated = "coupon_update_initiated"
    case couponUpdateSuccess = "coupon_update_success"
    case couponUpdateFailed = "coupon_update_failed"
    case couponCreationInitiated = "coupon_creation_initiated"
    case couponCreationSuccess = "coupon_creation_success"
    case couponCreationFailed = "coupon_creation_failed"
    case couponCreationSuccessShareTapped = "coupon_creation_success_share_tapped"

    // MARK: Inbox Notes
    case inboxNotesLoaded = "inbox_notes_loaded"
    case inboxNotesLoadedFailed = "inbox_notes_load_failed"
    case inboxNoteAction = "inbox_note_action"

    // MARK: Customers
    case customerHubLoaded = "customers_hub_loaded"
    case customerHubLoadFailed = "customers_hub_load_failed"
    case customersHubSearch = "customers_hub_customer_search"
    case customersHubDetailOpen = "customers_hub_customer_detail_open"
    case customersHubDetailEmailMenuTapped = "customers_hub_customer_detail_email_menu_tapped"
    case customersHubDetailEmailOptionTapped = "customers_hub_customer_detail_email_option_tapped"
    case customersHubDetailCopyEmailOptionTapped = "customers_hub_customer_detail_email_copy_option_tapped"
    case customersHubDetailPhoneMenuTapped = "customers_hub_customer_detail_phone_menu_tapped"
    case customersHubDetailPhoneActionTapped = "customers_hub_customer_detail_phone_action_tapped"
    case customersHubDetailAddressCopied = "customers_hub_customer_detail_address_copied"
    case customersHubDetailNewOrderTapped = "customers_hub_customer_detail_new_order_tapped"

    // MARK: Close Account
    case closeAccountTapped = "close_account_tapped"
    case closeAccountSuccess = "close_account_success"
    case closeAccountFailed = "close_account_failed"

    // MARK: Login Jetpack setup
    case loginJetpackSetupButtonTapped = "login_jetpack_setup_button_tapped"
    case loginJetpackSetupDismissed = "login_jetpack_setup_dismissed"
    case loginJetpackSetupCompleted = "login_jetpack_setup_completed"
    case loginJetpackSetupFlow = "login_jetpack_setup_flow"

    // MARK: Login WooCommerce setup
    case loginWooCommerceErrorShown = "login_woocommerce_error_shown"
    case loginWooCommerceSetupButtonTapped = "login_woocommerce_setup_button_tapped"
    case loginWooCommerceSetupDismissed = "login_woocommerce_setup_dismissed"
    case loginWooCommerceSetupCompleted = "login_woocommerce_setup_completed"

    // MARK: Payments Menu
    case paymentsMenuOnboardingErrorTapped = "payments_hub_onboarding_error_tapped"
    case paymentsMenuOrderCardReaderTapped = "payments_hub_order_card_reader_tapped"
    case paymentsMenuCardReadersManualsTapped = "payments_hub_card_readers_manuals_tapped"
    case paymentsMenuManageCardReadersTapped = "payments_hub_manage_card_readers_tapped"
    case paymentsMenuPaymentProviderTapped = "settings_card_present_select_payment_gateway_tapped"
    case inPersonPaymentsLearnMoreTapped = "in_person_payments_learn_more_tapped"
    case setUpTryOutTapToPayOnIPhoneTapped = "payments_hub_tap_to_pay_tapped"
    case aboutTapToPayOnIPhoneTapped = "payments_hub_tap_to_pay_about_tapped"
    case paymentsMenuPayoutSummaryShown = "payments_hub_deposit_summary_shown"
    case paymentsMenuPayoutSummaryError = "payments_hub_deposit_summary_error"
    case paymentsMenuPayoutSummaryExpanded = "payments_hub_deposit_summary_expanded"
    case paymentsMenuPayoutSummaryLearnMoreTapped = "payments_hub_deposit_summary_learn_more_clicked"
    case paymentsMenuPayoutSummaryCurrencySelected = "payments_hub_deposit_summary_currency_selected"

    // MARK: Payments Menu
    case pluginsNotSyncedYet = "plugins_not_synced_yet"

    // MARK: Universal Links
    case universalLinkOpened = "universal_link_opened"
    case universalLinkFailed = "universal_link_failed"

    // MARK: Spotlight
    case spotlightActivityOpened = "spotlight_activity_opened"

    // MARK: App Intents
    case appIntentShortcutOpened = "shortcut_opened"

    // MARK: Login Jetpack Connection
    case loginJetpackConnectionErrorShown = "login_jetpack_connection_error_shown"
    case loginJetpackConnectButtonTapped = "login_jetpack_connect_button_tapped"
    case loginJetpackConnectCompleted = "login_jetpack_connect_completed"
    case loginJetpackConnectDismissed = "login_jetpack_connect_dismissed"
    case loginJetpackConnectionURLFetchFailed = "login_jetpack_connection_url_fetch_failed"
    case loginJetpackConnectionVerificationFailed = "login_jetpack_connection_verification_failed"

    // MARK: Widgets
    case widgetTapped = "widget_tapped"

    // MARK: Application password Events
    case applicationPasswordsNewPasswordCreated = "application_passwords_new_password_created"
    case applicationPasswordsGenerationFailed = "application_passwords_generation_failed"

    // MARK: Jetpack site performance improvements
    case jetpackSiteEligibleForAppPasswordSupport = "jetpack_site_eligible_for_app_password_support"
    case jetpackSiteFlaggedUnsupportedForAppPasswords = "jetpack_site_flagged_unsupported_for_app_passwords"

    // MARK: Free Trial
    case freeTrialUpgradeNowTapped = "free_trial_upgrade_now_tapped"
    case planUpgradeSuccess = "plan_upgrade_success"
    case planUpgradeAbandoned = "plan_upgrade_abandoned"

    // MARK: Application password authorization in web view
    case applicationPasswordAuthorizationButtonTapped = "application_password_authorization_button_tapped"
    case applicationPasswordAuthorizationWebViewShown = "application_password_authorization_web_view_shown"
    case applicationPasswordAuthorizationRejected = "application_password_authorization_rejected"
    case applicationPasswordAuthorizationApproved = "application_password_authorization_approved"
    case applicationPasswordAuthorizationURLNotAvailable = "application_password_authorization_url_not_available"
    case applicationPasswordAuthorizationURLFetchFailed = "application_password_authorization_url_fetch_failed"

    // MARK: Jetpack setup for non-Jetpack sites
    case jetpackSetupLoginButtonTapped = "jetpack_benefits_login_button_tapped"
    case jetpackSetupConnectionCheckCompleted = "jetpack_setup_connection_check_completed"
    case jetpackSetupConnectionCheckFailed = "jetpack_setup_connection_check_failed"
    case jetpackSetupLoginFlow = "jetpack_setup_login_flow"
    case jetpackSetupLoginCompleted = "jetpack_setup_login_completed"
    case jetpackSetupFlow = "jetpack_setup_flow"
    case jetpackSetupCompleted = "jetpack_setup_completed"
    case jetpackSetupSynchronizationCompleted = "jetpack_setup_synchronization_completed"

    // MARK: Privacy Banner
    case privacyChoicesBannerPresented = "privacy_choices_banner_presented"
    case privacyChoicesSettingsButtonTapped = "privacy_choices_banner_settings_button_tapped"
    case privacyChoicesSaveButtonTapped = "privacy_choices_banner_save_button_tapped"

    // MARK: Local Announcement
    case localAnnouncementDisplayed = "local_announcement_displayed"
    case localAnnouncementCallToActionTapped = "local_announcement_cta_tapped"
    case localAnnouncementDismissTapped = "local_announcement_dismissed"

    // MARK: Themes
    case themePickerScreenDisplayed = "theme_picker_screen_displayed"
    case themePickerThemeSelected = "theme_picker_theme_selected"
    case themePreviewScreenDisplayed = "theme_preview_screen_displayed"
    case themePreviewLayoutSelected = "theme_preview_layout_selected"
    case themePreviewPageSelected = "theme_preview_page_selected"
    case themePreviewStartWithThemeButtonTapped = "theme_preview_start_with_theme_button_tapped"
    case themeInstallationCompleted = "theme_installation_completed"
    case themeInstallationFailed = "theme_installation_failed"

    // MARK: Connectivity Tool
    case connectivityToolRequestResponse = "connectivity_tool_request_response"
    case connectivityToolReadMoreTapped = "connectivity_tool_read_more_tapped"
    case connectivityToolContactSupportTapped = "connectivity_tool_contact_support_tapped"
    case preLoginConnectivityToolRequestResponse = "pre_login_connectivity_tool_request_response"

    // MARK: Watch App
    case watchAppOpened = "watch_app_opened"
    case watchStoreDataSynced = "watch_store_data_synced"
    case watchConnectingOpened = "watch_connecting_opened"
    case watchSyncingFailed = "watch_syncing_failed"
    case watchMyStoreOpened = "watch_my_store_opened"
    case watchOrdersListOpened = "watch_orders_list_opened"
    case watchPushNotificationTapped = "watch_push_notification_tapped"
    case watchOrderDetailOpened = "watch_order_detail_opened"

    // MARK: Google ads campaign management
    case googleAdsEntryPointDisplayed = "googleads_entry_point_displayed"
    case googleAdsEntryPointTapped = "googleads_entry_point_tapped"
    case googleAdsFlowStarted = "googleads_flow_started"
    case googleAdsFlowCanceled = "googleads_flow_canceled"
    case googleAdsFlowError = "googleads_flow_error"
    case googleAdsCampaignCreationSuccess = "googleads_campaign_creation_success"

    // MARK: Background Data Updates
    case backgroundDataSynced = "background_data_synced"
    case backgroundDataSyncError = "background_data_sync_error"
    case pushNotificationOrderBackgroundSynced = "push_notification_order_background_synced"
    case pushNotificationOrderBackgroundSyncError = "push_notification_order_background_sync_error"
    case backgroundUpdatesDisabled = "background_updates_disabled"

    // MARK: Point of Sale events
    case pointOfSaleTabSelected = "main_tab_pos_selected"
    case pointOfSaleTabVisibilityChecked = "pos_tab_visibility_checked"
    case pointOfSaleIneligibleUIShown = "pos_ineligible_ui_shown"
    case pointOfSaleIneligibleUIRetryTapped = "pos_ineligible_ui_retry_tapped"
    case pointOfSaleIneligibleUILearnMoreTapped = "pos_ineligible_ui_learn_more_tapped"
    case pointOfSaleLoaded = "loaded"
    case pointOfSaleItemsFetched = "items_fetched"
    case pointOfSaleItemsPullToRefresh = "items_pull_to_refresh"
    case pointOfSaleAddItemToCart = "item_added_to_cart"
    case pointOfSaleItemRemovedFromCart = "item_removed_from_cart"
    case pointOfSaleCheckoutTapped = "checkout_tapped"
    case pointOfSaleBackToCartTapped = "back_to_cart_tapped"
    case pointOfSaleCheckoutCashPaymentTapped = "checkout_cash_payment_tapped"
    case pointOfSaleCashPaymentTapped = "cash_payment_tapped"
    case pointOfSaleCashPaymentFailed = "cash_payment_failed"
    case pointOfSaleBackToCheckoutFromCashTapped = "back_to_checkout_from_cash"
    case pointOfSaleClearCartTapped = "clear_cart_tapped"
    case pointOfSaleExitMenuItemTapped = "exit_menu_item_tapped"
    case pointOfSaleExitConfirmed = "exit_confirmed"
    case pointOfSaleGetSupportTapped = "get_support_tapped"
    case pointOfSaleSimpleProductsExplanationDialogShown = "simple_products_explanation_dialog_shown"
    case pointOfSaleCreateNewOrderTapped = "create_new_order_tapped"
    case pointOfSaleReceiptEmailSendTapped = "receipt_email_send_tapped"
    case pointOfSalePaymentsOnboardingShown = "payments_onboarding_shown"
    case pointOfSalePaymentsOnboardingDismissed = "payments_onboarding_dismissed"
    case pointOfSaleCardReaderConnectionTapped = "card_reader_connection_tapped"
    case pointOfSaleInteractionWithCustomerStarted = "interaction_with_customer_started"
    case pointOfSaleViewDocsTapped = "view_docs_tapped"
    case pointOfSaleReaderReadyForCardPayment = "reader_ready_for_card_payment"
    case pointOfSaleCashCollectPaymentSuccess = "cash_collect_payment_success"
    case pointOfSaleItemsHeaderTapped = "items_header_tapped"
    case pointOfSaleCouponsCreateTapped = "coupons_create_tapped"
    case pointOfSaleSearchButtonTapped = "search_button_tapped"
    case pointOfSalePreSearchRecentTermTapped = "pre_search_recent_term_tapped"
    case pointOfSaleKeyboardDismissedInSearch = "keyboard_dismissed_in_search"
    case pointOfSaleItemsNextPageLoaded = "items_next_page_loaded"
    case pointOfSaleSearchRemoteResultsFetched = "search_remote_results_fetched"
    case pointOfSaleSearchResultsFetched = "search_results_fetched"
    case pointOfSaleBarcodeScanningMenuItemTapped = "barcode_scanning_menu_item_tapped"
    case pointOfSaleBarcodeScanningExplanationDialogShown = "barcode_scanning_explanation_dialog_shown"
    case pointOfSaleBarcodeScannerSetupFlowShown = "barcode_scanner_setup_flow_shown"
    case pointOfSaleBarcodeScanningSuccess = "barcode_scanned"
    case pointOfSaleBarcodeScanningFailed = "barcode_scanning_failed"
    case pointOfSaleBarcodeScannerSetupScannerSelected = "barcode_scanner_setup_scanner_selected"
    case pointOfSaleBarcodeScannerSetupNextTapped = "barcode_scanner_setup_next_tapped"
    case pointOfSaleBarcodeScannerSetupBackTapped = "barcode_scanner_setup_back_tapped"
    case pointOfSaleBarcodeScannerSetupOpenSystemSettingsTapped = "barcode_scanner_setup_open_system_settings_tapped"
    case pointOfSaleBarcodeScannerSetupTestScanSuccess = "barcode_scanner_setup_test_scan_success"
    case pointOfSaleBarcodeScannerSetupTestScanFailed = "barcode_scanner_setup_test_scan_failed"
    case pointOfSaleBarcodeScannerSetupTestScanTimedOut = "barcode_scanner_setup_test_scan_timed_out"
    case pointOfSaleBarcodeScannerSetupDismissed = "barcode_scanner_setup_dismissed"
    case pointOfSaleBarcodeScannerSetupRetryTapped = "barcode_scanner_setup_retry_tapped"
    case pointOfSaleBarcodeScannerSetupScannerConnected = "barcode_scanner_setup_scanner_connected"
    case pointOfSaleSettingsMenuItemTapped = "settings_open"
    case pointOfSaleSettingsCloseButtonTapped = "settings_closed"
    case pointOfSaleSettingsStoreDetailsTapped = "settings_store_details_tapped"
    case pointOfSaleSettingsHardwareTapped = "settings_hardware_tapped"
    case pointOfSaleSettingsHelpTapped = "settings_help_tapped"
    case pointOfSaleEmptyCartSetupScannerTapped = "empty_cart_set_up_scanner_tapped"
    case pointOfSaleOrdersMenuItemTapped = "orders_menu_item_tapped"
    case pointOfSaleOrdersListPullToRefresh = "orders_list_pull_to_refresh"
    case pointOfSaleOrdersListFetched = "orders_list_fetched"
    case pointOfSaleOrdersListNextPageLoaded = "orders_list_next_page_loaded"
    case pointOfSaleOrdersListRowTapped = "orders_list_row_tapped"
    case pointOfSaleOrdersListSearchButtonTapped = "orders_list_search_button_tapped"
    case pointOfSaleOrdersListSearchResultsFetched = "orders_list_search_results_fetched"
    case pointOfSaleOrderDetailsLoaded = "order_details_loaded"
    case pointOfSaleOrderDetailsEmailReceiptTapped = "order_details_email_receipt_tapped"
    case pointOfSaleRefundFlowStarted = "refund_flow_started"
    case pointOfSaleRefundConfirmTapped = "refund_confirm_tapped"
    case pointOfSaleRefundProcessingStarted = "refund_processing_started"
    case pointOfSaleRefundProcessingSuccess = "refund_processing_success"
    case pointOfSaleRefundProcessingFailed = "refund_processing_failed"
    case pointOfSaleRefundFlowAborted = "refund_flow_aborted"
    case pointOfSaleRefundSelectAllTapped = "refund_select_all_tapped"
    case pointOfSaleLocalCatalogDownloadingScreenShown = "local_catalog_downloading_screen_shown"
    case pointOfSaleLocalCatalogDownloadingScreenExitPosTapped = "local_catalog_downloading_screen_exit_pos_tapped"
    case pointOfSaleSplashScreenErrorShown = "splash_screen_error_shown"
    case pointOfSaleSplashScreenRetryTapped = "splash_screen_retry_tapped"
    case pointOfSaleLocalCatalogStaleWarningShown = "local_catalog_stale_warning_shown"
    case pointOfSaleLocalCatalogStaleWarningDismissed = "local_catalog_stale_warning_dismissed"
    case pointOfSaleLocalCatalogSyncStarted = "local_catalog_sync_started"
    case pointOfSaleLocalCatalogSyncCompleted = "local_catalog_sync_completed"
    case pointOfSaleLocalCatalogSyncFailed = "local_catalog_sync_failed"
    case pointOfSaleLocalCatalogSyncSkipped = "local_catalog_sync_skipped"
    case pointOfSaleLocalCatalogSunsetWarningShown = "local_catalog_sunset_warning_shown"
    case pointOfSaleLocalCatalogSunsetWarningDismissed = "local_catalog_sunset_warning_dismissed"
    case pointOfSaleCheckoutOutdatedItemDetectedScreenShown = "checkout_outdated_item_detected_screen_shown"
    case pointOfSaleCheckoutOutdatedItemDetectedEditOrderTapped = "checkout_outdated_item_detected_edit_order_tapped"
    case pointOfSaleCheckoutOutdatedItemDetectedRemoveTapped = "checkout_outdated_item_detected_remove_tapped"

    // MARK: Point of Sale Bookings
    case pointOfSaleBookingsMenuItemTapped = "bookings_menu_item_tapped"
    case pointOfSaleBookingsListSearchButtonTapped = "bookings_list_search_button_tapped"
    case pointOfSaleBookingsListBookingTapped = "bookings_list_booking_tapped"
    case pointOfSaleBookingCancelled = "booking_cancelled"
    case pointOfSaleBookingAddNoteTapped = "booking_add_note_tapped"
    case pointOfSaleBookingIssueRefundTapped = "booking_issue_refund_tapped"
    case pointOfSaleBookingViewOrderTapped = "booking_view_order_tapped"
    case pointOfSaleBookingAttendanceChanged = "booking_attendance_changed"
    case pointOfSaleBookingNoteAdded = "booking_note_added"
    case pointOfSaleBookingCancelFailed = "booking_cancel_failed"
    case pointOfSaleBookingAttendanceChangeFailed = "booking_attendance_change_failed"
    case pointOfSaleBookingNoteAddFailed = "booking_note_add_failed"
    case pointOfSaleBookingRefundFailed = "booking_refund_failed"
    case pointOfSaleBookingDatePreviousTapped = "booking_date_previous_tapped"
    case pointOfSaleBookingDateNextTapped = "booking_date_next_tapped"
    case pointOfSaleBookingDateCalendarSelected = "booking_date_calendar_selected"

    // MARK: Custom Fields events
    case productDetailCustomFieldsTapped = "product_detail_custom_fields_tapped"

    // Custom Fields List
    case customFieldsListLoaded = "custom_fields_list_loaded"
    case customFieldTapped = "custom_field_tapped"
    case addCustomFieldTapped = "add_custom_field_tapped"
    case saveCustomFieldTapped = "save_custom_field_tapped"
    case customFieldsSavedSuccessfully = "custom_fields_saved_successfully"
    case customFieldsSavingFailed = "custom_fields_saving failed"

    // Custom Field Editor
    case customFieldEditorLoaded = "custom_field_editor_loaded"
    case customFieldEditorPickerTapped = "custom_field_editor_picker_tapped"
    case customFieldEditorDeleteTapped = "custom_field_editor_delete_tapped"
    case customFieldEditorDoneTapped = "custom_field_editor_done_tapped"

    // MARK: AI Support Chat events
    case supportChatOpened = "support_chat_opened"
    case supportChatMessageSent = "support_chat_message_sent"
    case supportChatMessageReceived = "support_chat_message_received"
    case supportChatMessageFailed = "support_chat_message_failed"
    case supportChatSourceTapped = "support_chat_source_tapped"
    case supportChatFeedbackSubmitted = "support_chat_feedback_submitted"
    case supportChatForwardToHumanTriggered = "support_chat_forward_to_human_triggered"
    case supportChatContactHumanTapped = "support_chat_contact_human_tapped"
    case supportChatClosed = "support_chat_closed"
    case supportChatHistoryOpened = "support_chat_history_opened"
    case supportChatHistoryResumed = "support_chat_history_resumed"
    case supportChatHistoryDeleted = "support_chat_history_deleted"

    // MARK: Woo Shipping events
    case wooShippingCreateShippingLabelFormShown = "wcs_create_shipping_label_form_shown"
    case wooShippingEditingAddressStep = "wcs_editing_address_step"
    case wooShippingPackageSelectionStep = "wcs_package_selection_step"
    case wooShippingRateSelectionStep = "wcs_rate_selection_step"
    case wooShippingPaymentStep = "wcs_payment_step"
    case wooShippingPurchaseStep = "wcs_purchase_step"
    case wooShippingRefundRequested = "wcs_refund_requested"
}

extension WooAnalyticsStat {


    /// Indicates if site information should be included with this event when it's sent to the tracks server.
    /// Returns `true` if it should be included, `false` otherwise.
    ///
    /// Note: Currently all authentication events will return false. If you wish
    /// to include additional no-site-info events, please add them here.
    ///
    public var shouldSendSiteProperties: Bool {
        switch self {
        // Authentication Events
        case .signedIn, .logout, .openedLogin, .loginFailed,
             .loginAutoFillCredentialsFilled, .loginAutoFillCredentialsUpdated, .loginEmailFormViewed, .loginMagicLinkOpenEmailClientViewed,
             .loginMagicLinkRequestFormViewed, .loginMagicLinkExited, .loginMagicLinkFailed, .loginMagicLinkOpened,
             .loginMagicLinkRequested, .loginMagicLinkSucceeded, .loginPasswordFormViewed, .loginURLFormViewed,
             .loginURLHelpScreenViewed, .loginUsernamePasswordFormViewed, .loginTwoFactorFormViewed, .loginEpilogueViewed,
             .loginProloguePaged, .loginPrologueViewed,
             .loginPrologueContinueTapped, .loginPrologueJetpackInstructions, .loginForgotPasswordClicked, .loginSocialButtonClick,
             .loginSocialButtonFailure, .loginSocialConnectSuccess, .loginSocialConnectFailure, .loginSocialSuccess,
             .loginSocialFailure, .loginSocial2faNeeded, .loginSocialAccountsNeedConnecting, .loginSocialErrorUnknownUser,
             .onePasswordFailed, .onePasswordLogin, .onePasswordSignup, .twoFactorCodeRequested, .twoFactorSentSMS,
             .loginJetpackRequiredScreenViewed, .loginJetpackRequiredViewInstructionsButtonTapped,
             .loginWhatIsJetpackHelpScreenViewed, .loginWhatIsJetpackHelpScreenOkButtonTapped,
             .loginWhatIsJetpackHelpScreenLearnMoreButtonTapped, .watchConnectingOpened, .watchStoreDataSynced:
            return false
        // Per-site push token registration events attribute properties to the target site via a factory,
        // so opt out of the default-site enrichment that would otherwise overwrite `blog_id` / `site_url`
        // with the currently selected site.
        case .wooPushTokenRegisterSuccess, .wooPushTokenRegisterError:
            return false
        default:
            return true
        }
    }
}
