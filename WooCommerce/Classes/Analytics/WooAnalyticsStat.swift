import WordPressShared


/// This enum contains all of the events we track in the app. Please reference the "Woo Mobile Events Draft i2"
/// spreadsheet for more details.
///
/// Note: If you would like to exclude site properties (e.g. `blog_id`) for a given event, please
/// add the event to the `WooAnalyticsStat.shouldSendSiteProperties` var.
///
public enum WooAnalyticsStat: String {

    // Application Events
    //
    case applicationInstalled                   = "application_installed"
    case applicationUpgraded                    = "application_upgraded"
    case applicationOpened                      = "application_opened"
    case applicationClosed                      = "application_closed"

    // Authentication Events
    //
    case signedIn                               = "signed_in"
    case logout                                 = "account_logout"
    case openedLogin                            = "login_accessed"
    case loginFailed                            = "login_failed_to_login"
    case loginAutoFillCredentialsFilled         = "login_autofill_credentials_filled"
    case loginAutoFillCredentialsUpdated        = "login_autofill_credentials_updated"
    case loginEmailFormViewed                   = "login_email_form_viewed"
    case loginMagicLinkOpenEmailClientViewed    = "login_magic_link_open_email_client_viewed"
    case loginMagicLinkRequestFormViewed        = "login_magic_link_request_form_viewed"
    case loginMagicLinkExited                   = "login_magic_link_exited"
    case loginMagicLinkFailed                   = "login_magic_link_failed"
    case loginMagicLinkOpened                   = "login_magic_link_opened"
    case loginMagicLinkRequested                = "login_magic_link_requested"
    case loginMagicLinkSucceeded                = "login_magic_link_succeeded"
    case loginPasswordFormViewed                = "login_password_form_viewed"
    case loginURLFormViewed                     = "login_url_form_viewed"
    case loginURLHelpScreenViewed               = "login_url_help_screen_viewed"
    case loginUsernamePasswordFormViewed        = "login_username_password_form_viewed"
    case loginTwoFactorFormViewed               = "login_two_factor_form_viewed"
    case loginEpilogueViewed                    = "login_epilogue_viewed"
    case loginEpilogueStoresShown               = "login_epilogue_stores_shown"
    case loginEpilogueContinueTapped            = "login_epilogue_store_picker_continue_tapped"
    case loginProloguePaged                     = "login_prologue_paged"
    case loginPrologueViewed                    = "login_prologue_viewed"
    case loginPrologueContinueTapped            = "login_prologue_jetpack_login_button_tapped"
    case loginPrologueJetpackInstructions       = "login_prologue_jetpack_configuration_instructions_link_tapped"
    case loginForgotPasswordClicked             = "login_forgot_password_clicked"
    case loginSocialButtonClick                 = "login_social_button_click"
    case loginSocialButtonFailure               = "login_social_button_failure"
    case loginSocialConnectSuccess              = "login_social_connect_success"
    case loginSocialConnectFailure              = "login_social_connect_failure"
    case loginSocialSuccess                     = "login_social_login_success"
    case loginSocialFailure                     = "login_social_login_failure"
    case loginSocial2faNeeded                   = "login_social_2fa_needed"
    case loginSocialAccountsNeedConnecting      = "login_social_accounts_need_connecting"
    case loginSocialErrorUnknownUser            = "login_social_error_unknown_user"
    case onePasswordFailed                      = "one_password_failed"
    case onePasswordLogin                       = "one_password_login"
    case onePasswordSignup                      = "one_password_signup"
    case twoFactorCodeRequested                 = "two_factor_code_requested"
    case twoFactorSentSMS                       = "two_factor_sent_sms"

    // Dashboard View Events
    //
    case dashboardSelected                      = "main_tab_dashboard_selected"
    case dashboardReselected                    = "main_tab_dashboard_reselected"
    case dashboardPulledToRefresh               = "dashboard_pulled_to_refresh"
    case dashboardNewOrdersButtonTapped         = "dashboard_unfulfilled_orders_button_tapped"

    // Dashboard Data/Action Events
    //
    case dashboardMainStatsDate                 = "dashboard_main_stats_date"
    case dashboardMainStatsLoaded               = "dashboard_main_stats_loaded"
    case dashboardTopPerformersDate             = "dashboard_top_performers_date"
    case dashboardTopPerformersLoaded           = "dashboard_top_performers_loaded"
    case dashboardUnfulfilledOrdersLoaded       = "dashboard_unfulfilled_orders_loaded"

    // Help & Support Events
    //
    case supportBrowseOurFaqTapped              = "support_browse_our_faq_tapped"
    case supportNewRequestViewed                = "support_new_request_viewed"
    case supportNewRequestCreated               = "support_new_request_created"
    case supportNewRequestFailed                = "support_new_request_failed"
    case supportNewRequestFileAttached          = "support_new_request_file_attached"
    case supportNewRequestFileAttachmentFailed  = "support_new_request_file_attachment_failed"
    case supportTicketUserReplied               = "support_ticket_user_replied"
    case supportTicketUserReplyFailed           = "support_ticket_user_reply_failed"
    case supportTicketListViewed                = "support_ticket_list_viewed"
    case supportTicketListViewFailed            = "support_ticket_list_view_failed"
    case supportTicketUserViewed                = "support_ticket_user_viewed"
    case supportTicketViewFailed                = "support_ticket_view_failed"
    case supportHelpCenterUserSearched          = "support_help_center_user_searched"
    case supportIdentityFormViewed              = "support_identity_form_viewed"
    case supportIdentitySet                     = "support_identity_set"



    // Settings View Events
    //
    case settingsTapped                         = "main_menu_settings_tapped"
    case settingsContactSupportTapped           = "main_menu_contact_support_tapped"

    case settingsPrivacySettingsTapped          = "settings_privacy_settings_tapped"
    case settingsCollectInfoToggled             = "settings_privacy_settings_collect_info_toggled"
    case settingsReportCrashesToggled           = "settings_privacy_settings_report_crashes_toggled"
    case settingsPrivacyPolicyTapped            = "settings_privacy_settings_privacy_policy_link_tapped"
    case settingsShareInfoLearnMoreTapped       = "settings_privacy_settings_share_info_link_tapped"
    case settingsThirdPartyLearnMoreTapped      = "settings_privacy_settings_third_party_tracking_info_link_tapped"
    case settingsLicensesLinkTapped             = "settings_about_open_source_licenses_link_tapped"
    case settingsAboutLinkTapped                = "settings_about_woocommerce_link_tapped"

    case settingsLogoutTapped                   = "settings_logout_button_tapped"
    case settingsLogoutConfirmation             = "settings_logout_confirmation_dialog_result"

    // Order View Events
    //
    case ordersSelected                         = "main_tab_orders_selected"
    case ordersReselected                       = "main_tab_orders_reselected"
    case ordersListPulledToRefresh              = "orders_list_pulled_to_refresh"
    case ordersListFilterTapped                 = "orders_list_menu_filter_tapped"
    case filterOrdersOptionSelected             = "filter_orders_by_status_dialog_option_selected"
    case orderDetailAddNoteButtonTapped         = "order_detail_add_note_button_tapped"
    case orderDetailPulledToRefresh             = "order_detail_pulled_to_refresh"
    case orderNoteAddButtonTapped               = "add_order_note_add_button_tapped"
    case orderNoteEmailCustomerToggled          = "add_order_note_email_note_to_customer_toggled"
    case orderDetailShowBillingTapped           = "order_detail_customer_info_show_billing_tapped"
    case orderDetailHideBillingTapped           = "order_detail_customer_info_hide_billing_tapped"
    case orderDetailFulfillButtonTapped         = "order_detail_fulfill_order_button_tapped"
    case orderDetailCustomerEmailTapped         = "order_detail_customer_info_email_menu_email_tapped"
    case orderDetailCustomerPhoneMenuTapped     = "order_detail_customer_info_phone_menu_tapped"
    case orderDetailCustomerPhoneOptionTapped   = "order_detail_customer_info_phone_menu_phone_tapped"
    case orderDetailCustomerSMSOptionTapped     = "order_detail_customer_info_phone_menu_sms_tapped"
    case orderDetailProductDetailTapped         = "order_detail_product_detail_button_tapped"
    case orderFulfillmentCompleteButtonTapped   = "order_fulfillment_mark_order_complete_button_tapped"
    case orderMarkedCompleteUndoButtonTapped    = "snack_order_marked_complete_undo_button_tapped"

    // Order Data/Action Events
    //
    case orderOpen                              = "order_open"
    case orderNotesLoaded                       = "order_notes_loaded"
    case orderNoteAdd                           = "order_note_add"
    case orderNoteAddSuccess                    = "order_note_add_success"
    case orderNoteAddFailed                     = "order_note_add_failed"
    case orderContactAction                     = "order_contact_action"
    case ordersListFilterOrSearch               = "orders_list_filter"
    case ordersListLoaded                       = "orders_list_loaded"
    case orderStatusChange                      = "order_status_change"
    case orderStatusChangeSuccess               = "order_status_change_success"
    case orderStatusChangeFailed                = "order_status_change_failed"
    case orderStatusChangeUndo                  = "order_status_change_undo"

    // Push Notifications Events
    //
    case pushNotificationReceived               = "push_notification_received"
    case pushNotificationAlertPressed           = "push_notification_alert_pressed"
    case pushNotificationOSAlertAllowed         = "push_notification_os_alert_allowed"
    case pushNotificationOSAlertDenied          = "push_notification_os_alert_denied"
    case pushNotificationOSAlertShown           = "push_notification_os_alert_shown"

    // Notification View Events
    //
    case notificationsSelected                  = "main_tab_notifications_selected"
    case notificationsReselected                = "main_tab_notifications_reselected"
    case notificationOpened                     = "notification_open"
    case notificationsListPulledToRefresh       = "notifications_list_pulled_to_refresh"
    case notificationsListReadAllTapped         = "notifications_list_menu_mark_read_button_tapped"
    case notificationsListFilterTapped          = "notifications_list_menu_filter_tapped"
    case filterNotificationsOptionSelected      = "filter_notifications_by_status_dialog_option_selected"
    case notificationReviewApprovedTapped       = "review_detail_approve_button_tapped"
    case notificationReviewTrashTapped          = "review_detail_trash_button_tapped"
    case notificationReviewSpamTapped           = "review_detail_spam_button_tapped"

    // Notification Data/Action Events
    //
    case notificationListLoaded                 = "notifications_loaded"
    case notificationListFilter                 = "notifications_filter"
    case notificationReviewAction               = "review_action"
    case notificationReviewActionSuccess        = "review_action_success"
    case notificationReviewActionFailed         = "review_action_failed"
    case notificationReviewActionUndo           = "review_action_undo"

    // Jetpack Tunnel Events
    //
    case jetpackTunnelTimeout                   = "jetpack_tunnel_timeout"
}

public extension WooAnalyticsStat {


    /// Indicates if site information should be included with this event when it's sent to the tracks server.
    /// Returns `true` if it should be included, `false` otherwise.
    ///
    /// Note: Currently all application-level and authentication events will return false. If you wish
    /// to include additional no-site-info events, please add them here.
    ///
    var shouldSendSiteProperties: Bool {
        switch self {
        // Application events
        case .applicationClosed, .applicationOpened, .applicationUpgraded, .applicationInstalled:
            return false
        // Authentication Events
        case .signedIn, .logout, .openedLogin, .loginFailed,
             .loginAutoFillCredentialsFilled, .loginAutoFillCredentialsUpdated, .loginEmailFormViewed, .loginMagicLinkOpenEmailClientViewed,
             .loginMagicLinkRequestFormViewed, .loginMagicLinkExited, .loginMagicLinkFailed, .loginMagicLinkOpened,
             .loginMagicLinkRequested, .loginMagicLinkSucceeded, .loginPasswordFormViewed, .loginURLFormViewed,
             .loginURLHelpScreenViewed, .loginUsernamePasswordFormViewed, .loginTwoFactorFormViewed, .loginEpilogueViewed,
             .loginEpilogueStoresShown, .loginEpilogueContinueTapped, .loginProloguePaged, .loginPrologueViewed,
             .loginPrologueContinueTapped, .loginPrologueJetpackInstructions, .loginForgotPasswordClicked, .loginSocialButtonClick,
             .loginSocialButtonFailure, .loginSocialConnectSuccess, .loginSocialConnectFailure, .loginSocialSuccess,
             .loginSocialFailure, .loginSocial2faNeeded, .loginSocialAccountsNeedConnecting, .loginSocialErrorUnknownUser,
             .onePasswordFailed, .onePasswordLogin, .onePasswordSignup, .twoFactorCodeRequested, .twoFactorSentSMS:
            return false
        default:
            return true
        }
    }

    /// Converts the provided WPAnalyticsStat into a WooAnalyticsStat.
    /// This whole process kinda stinks, but we need this for the `WordPressAuthenticatorDelegate`
    /// implementation. ☹️ Feel free to refactor later on!
    ///
    /// - Parameter stat: The WPAnalyticsStat to convert
    /// - Returns: The corresponding WooAnalyticsStat or nil if it cannot be converted
    ///
    static func valueOf(stat: WPAnalyticsStat) -> WooAnalyticsStat? {
        var wooEvent: WooAnalyticsStat? = nil

        switch stat {
        case .signedIn:
            wooEvent = WooAnalyticsStat.signedIn
        case .signedInToJetpack:
            wooEvent = WooAnalyticsStat.signedIn
        case .logout:
            wooEvent = WooAnalyticsStat.logout
        case .openedLogin:
            wooEvent = WooAnalyticsStat.openedLogin
        case .loginFailed:
            wooEvent = WooAnalyticsStat.loginFailed
        case .loginAutoFillCredentialsFilled:
            wooEvent = WooAnalyticsStat.loginAutoFillCredentialsFilled
        case .loginAutoFillCredentialsUpdated:
            wooEvent = WooAnalyticsStat.loginAutoFillCredentialsUpdated
        case .loginProloguePaged:
            wooEvent = WooAnalyticsStat.loginProloguePaged
        case .loginPrologueViewed:
            wooEvent = WooAnalyticsStat.loginPrologueViewed
        case .loginEmailFormViewed:
            wooEvent = WooAnalyticsStat.loginEmailFormViewed
        case .loginMagicLinkOpenEmailClientViewed:
            wooEvent = WooAnalyticsStat.loginMagicLinkOpenEmailClientViewed
        case .loginMagicLinkRequestFormViewed:
            wooEvent = WooAnalyticsStat.loginMagicLinkRequestFormViewed
        case .loginMagicLinkExited:
            wooEvent = WooAnalyticsStat.loginMagicLinkExited
        case .loginMagicLinkFailed:
            wooEvent = WooAnalyticsStat.loginMagicLinkFailed
        case .loginMagicLinkOpened:
            wooEvent = WooAnalyticsStat.loginMagicLinkOpened
        case .loginMagicLinkRequested:
            wooEvent = WooAnalyticsStat.loginMagicLinkRequested
        case .loginMagicLinkSucceeded:
            wooEvent = WooAnalyticsStat.loginMagicLinkSucceeded
        case .loginPasswordFormViewed:
             wooEvent = WooAnalyticsStat.loginPasswordFormViewed
        case .loginURLFormViewed:
            wooEvent = WooAnalyticsStat.loginURLFormViewed
        case .loginURLHelpScreenViewed:
            wooEvent = WooAnalyticsStat.loginURLHelpScreenViewed
        case .loginUsernamePasswordFormViewed:
            wooEvent = WooAnalyticsStat.loginUsernamePasswordFormViewed
        case .loginTwoFactorFormViewed:
            wooEvent = WooAnalyticsStat.loginTwoFactorFormViewed
        case .loginEpilogueViewed:
            wooEvent = WooAnalyticsStat.loginEpilogueViewed
        case .loginForgotPasswordClicked:
            wooEvent = WooAnalyticsStat.loginForgotPasswordClicked
        case .loginSocialButtonClick:
            wooEvent = WooAnalyticsStat.loginSocialButtonClick
        case .loginSocialButtonFailure:
            wooEvent = WooAnalyticsStat.loginSocialButtonFailure
        case .loginSocialConnectSuccess:
            wooEvent = WooAnalyticsStat.loginSocialConnectSuccess
        case .loginSocialConnectFailure:
            wooEvent = WooAnalyticsStat.loginSocialConnectFailure
        case .loginSocialSuccess:
            wooEvent = WooAnalyticsStat.loginSocialSuccess
        case .loginSocialFailure:
            wooEvent = WooAnalyticsStat.loginSocialFailure
        case .loginSocial2faNeeded:
            wooEvent = WooAnalyticsStat.loginSocial2faNeeded
        case .loginSocialAccountsNeedConnecting:
            wooEvent = WooAnalyticsStat.loginSocialAccountsNeedConnecting
        case .loginSocialErrorUnknownUser:
            wooEvent = WooAnalyticsStat.loginSocialErrorUnknownUser
        case .onePasswordFailed:
            wooEvent = WooAnalyticsStat.onePasswordFailed
        case .onePasswordLogin:
            wooEvent = WooAnalyticsStat.onePasswordLogin
        case .onePasswordSignup:
            wooEvent = WooAnalyticsStat.onePasswordSignup
        case .twoFactorCodeRequested:
            wooEvent = WooAnalyticsStat.twoFactorCodeRequested
        case .twoFactorSentSMS:
            wooEvent = WooAnalyticsStat.twoFactorSentSMS
        default:
            wooEvent = nil
        }

        return wooEvent
    }
}
