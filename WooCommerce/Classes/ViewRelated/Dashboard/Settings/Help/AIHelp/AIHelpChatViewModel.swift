import Foundation
import Yosemite
import Observation
import protocol WooFoundation.Analytics

/// Manages the state and logic for the AI Help chat conversation.
///
@MainActor
@Observable
final class AIHelpChatViewModel {

    // MARK: - Public State

    private(set) var messages: [AIHelpChatMessage] = []
    private(set) var phase: ConversationPhase = .selectTopic
    private(set) var isProcessing = false

    var userInput = ""

    let siteName: String
    let siteURL: String
    let siteID: Int64

    /// Navigation callbacks set by the hosting controller.
    var onFileZendeskTicket: (() -> Void)?
    var onOpenNotificationSettings: (() -> Void)?

    // MARK: - Dependencies

    private let stores: StoresManager
    private let analytics: Analytics
    private let diagnosticsService: AIHelpDiagnosticsService

    // MARK: - Initialization

    init(siteID: Int64,
         siteName: String,
         siteURL: String,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.siteName = siteName
        self.siteURL = siteURL
        self.stores = stores
        self.analytics = analytics
        self.diagnosticsService = AIHelpDiagnosticsService(stores: stores)

        addSystemMessage(Localization.welcomeMessage)
    }

    // MARK: - Conversation Phases

    enum ConversationPhase {
        case selectTopic
        case runningDiagnostics
        case collectingDetails(AIHelpTroubleshootingOption)
        case aiAnalyzing
        case offeringEscalation
    }

    // MARK: - User Actions

    func selectTopic(_ topic: AIHelpTroubleshootingOption) {
        addUserMessage(topic.title)

        if topic.requiresFreeText {
            addSystemMessage(Localization.enterMoreDetails)
            phase = .collectingDetails(topic)
        } else {
            Task {
                await runDiagnostics(for: topic)
            }
        }
    }

    func submitUserInput() {
        guard !userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let input = userInput
        userInput = ""

        guard case .collectingDetails(let topic) = phase else { return }

        addUserMessage(input)
        phase = .aiAnalyzing

        Task {
            await analyzeWithAI(input: input, topic: topic)
        }
    }

    func performAction(_ action: AIHelpChatMessage.MessageAction) {
        switch action.actionType {
        case .enableAnalytics:
            Task {
                await enableAnalytics()
            }
        case .fileZendeskTicket:
            onFileZendeskTicket?()
        case .openNotificationSettings:
            onOpenNotificationSettings?()
        }
    }

    func fileZendeskTicket() {
        onFileZendeskTicket?()
    }

    // MARK: - Diagnostics

    private func runDiagnostics(for topic: AIHelpTroubleshootingOption) async {
        phase = .runningDiagnostics
        isProcessing = true

        let loadingMessageID = addSystemMessage(Localization.runningDiagnostics, diagnosticStatus: .loading)

        switch topic {
        case .analytics:
            await runAnalyticsDiagnostics()
        case .loadingOrders:
            await runOrderDiagnostics()
        case .loadingProducts:
            await runProductDiagnostics()
        case .orderNotifications:
            await runNotificationDiagnostics()
        default:
            break
        }

        removeMessage(withID: loadingMessageID)
        isProcessing = false
    }

    private func runAnalyticsDiagnostics() async {
        do {
            let isEnabled = try await diagnosticsService.checkAnalyticsSetting(siteID: siteID)
            if isEnabled {
                addDiagnosticMessage(
                    Localization.analyticsEnabled,
                    status: .success,
                    actions: [.init(title: Localization.contactSupport, actionType: .fileZendeskTicket)]
                )
                addSystemMessage(Localization.analyticsEnabledButIssue)
                offerEscalation()
            } else {
                addDiagnosticMessage(
                    Localization.analyticsDisabled,
                    status: .warning,
                    actions: [.init(title: Localization.enableAnalytics, actionType: .enableAnalytics)]
                )
            }
        } catch {
            addDiagnosticMessage(
                String(format: Localization.analyticsCheckFailed, error.localizedDescription),
                status: .failure,
                actions: [.init(title: Localization.contactSupport, actionType: .fileZendeskTicket)]
            )
            offerEscalation()
        }
    }

    private func runOrderDiagnostics() async {
        do {
            _ = try await diagnosticsService.checkOrderSync(siteID: siteID)
            addDiagnosticMessage(Localization.orderSyncSuccess, status: .success)
            addSystemMessage(Localization.orderSyncSuccessHint)
            offerEscalation()
        } catch {
            addDiagnosticMessage(
                String(format: Localization.orderSyncFailed, error.localizedDescription),
                status: .failure
            )
            addSystemMessage(Localization.orderSyncFailedHint)
            offerEscalation()
        }
    }

    private func runProductDiagnostics() async {
        do {
            _ = try await diagnosticsService.checkProductSync(siteID: siteID)
            addDiagnosticMessage(Localization.productSyncSuccess, status: .success)
            addSystemMessage(Localization.productSyncSuccessHint)
            offerEscalation()
        } catch {
            addDiagnosticMessage(
                String(format: Localization.productSyncFailed, error.localizedDescription),
                status: .failure
            )
            addSystemMessage(Localization.productSyncFailedHint)
            offerEscalation()
        }
    }

    private func runNotificationDiagnostics() async {
        // Check WPCom auth
        let isWPComAuth = diagnosticsService.isAuthenticatedWithWPCom()
        if !isWPComAuth {
            addDiagnosticMessage(Localization.notWPComAuth, status: .failure)
            addSystemMessage(Localization.notWPComAuthHint)
            offerEscalation()
            return
        }
        addDiagnosticMessage(Localization.wpComAuthOK, status: .success)

        // Check Jetpack status
        let jetpackStatus = await diagnosticsService.checkJetpackStatus(siteID: siteID)
        let site = stores.sessionManager.defaultSite
        let jetpackOK = site?.isJetpackThePluginInstalled == true && site?.isJetpackConnected == true
        addDiagnosticMessage(jetpackStatus, status: jetpackOK ? .success : .failure)

        if !jetpackOK {
            addSystemMessage(Localization.jetpackRequiredHint)
            offerEscalation()
            return
        }

        // Check notification permissions
        let notificationsEnabled = await diagnosticsService.checkNotificationPermission()
        if notificationsEnabled {
            addDiagnosticMessage(Localization.notificationsEnabled, status: .success)
        } else {
            addDiagnosticMessage(
                Localization.notificationsDisabled,
                status: .warning,
                actions: [.init(title: Localization.openSettings, actionType: .openNotificationSettings)]
            )
        }

        addSystemMessage(Localization.notificationCheckComplete)
        offerEscalation()
    }

    private func enableAnalytics() async {
        isProcessing = true
        let loadingID = addSystemMessage(Localization.enablingAnalytics, diagnosticStatus: .loading)

        do {
            try await diagnosticsService.enableAnalyticsSetting(siteID: siteID)
            removeMessage(withID: loadingID)
            addDiagnosticMessage(Localization.analyticsNowEnabled, status: .success)
            addSystemMessage(Localization.relaunchApp)
        } catch {
            removeMessage(withID: loadingID)
            addDiagnosticMessage(
                String(format: Localization.enableAnalyticsFailed, error.localizedDescription),
                status: .failure,
                actions: [.init(title: Localization.contactSupport, actionType: .fileZendeskTicket)]
            )
        }

        isProcessing = false
        offerEscalation()
    }

    // MARK: - AI Analysis

    private func analyzeWithAI(input: String, topic: AIHelpTroubleshootingOption) async {
        isProcessing = true
        let loadingID = addSystemMessage(Localization.analyzingInput, diagnosticStatus: .loading)

        do {
            let suggestions = try await diagnosticsService.analyzeUserInput(siteID: siteID, input: input, topic: topic)
            removeMessage(withID: loadingID)
            addSystemMessage(suggestions)
        } catch {
            removeMessage(withID: loadingID)
            addSystemMessage(Localization.aiAnalysisFailed)
        }

        isProcessing = false
        offerEscalation()
    }

    // MARK: - Helpers

    @discardableResult
    private func addSystemMessage(_ content: String, diagnosticStatus: AIHelpChatMessage.DiagnosticStatus? = nil) -> UUID {
        let message = AIHelpChatMessage(role: .system, content: content, diagnosticStatus: diagnosticStatus)
        messages.append(message)
        return message.id
    }

    private func removeMessage(withID id: UUID) {
        messages.removeAll { $0.id == id }
    }

    private func addUserMessage(_ content: String) {
        messages.append(AIHelpChatMessage(role: .user, content: content))
    }

    private func addDiagnosticMessage(_ content: String,
                                      status: AIHelpChatMessage.DiagnosticStatus,
                                      actions: [AIHelpChatMessage.MessageAction] = []) {
        messages.append(AIHelpChatMessage(role: .diagnosticResult, content: content, diagnosticStatus: status, actions: actions))
    }

    private func offerEscalation() {
        phase = .offeringEscalation
    }
}

// MARK: - Localization
//
private extension AIHelpChatViewModel {
    enum Localization {
        static let welcomeMessage = NSLocalizedString(
            "aiHelp.chat.welcome",
            value: "Hi! What do you need help with? Select a topic below.",
            comment: "Welcome message in the AI Help chat"
        )
        static let enterMoreDetails = NSLocalizedString(
            "aiHelp.chat.enterDetails",
            value: "Please describe the issue you're experiencing.",
            comment: "Prompt asking user to enter more details about their issue"
        )
        static let runningDiagnostics = NSLocalizedString(
            "aiHelp.chat.runningDiagnostics",
            value: "Running diagnostics...",
            comment: "Message shown while diagnostics are running"
        )
        static let contactSupport = NSLocalizedString(
            "aiHelp.chat.contactSupport",
            value: "Contact Support",
            comment: "Button title to file a Zendesk support ticket"
        )

        // Analytics
        static let analyticsEnabled = NSLocalizedString(
            "aiHelp.chat.analyticsEnabled",
            value: "WooCommerce Analytics is enabled on your site.",
            comment: "Diagnostic result when analytics setting is enabled"
        )
        static let analyticsEnabledButIssue = NSLocalizedString(
            "aiHelp.chat.analyticsEnabledButIssue",
            value: "Analytics is enabled but you may still be experiencing issues. If the problem persists, please contact support.",
            comment: "Message after analytics is confirmed enabled but user still has issues"
        )
        static let analyticsDisabled = NSLocalizedString(
            "aiHelp.chat.analyticsDisabled",
            value: "WooCommerce Analytics is currently disabled on your site.",
            comment: "Diagnostic result when analytics setting is disabled"
        )
        static let enableAnalytics = NSLocalizedString(
            "aiHelp.chat.enableAnalytics",
            value: "Enable Analytics",
            comment: "Button title to enable WooCommerce Analytics"
        )
        static let analyticsCheckFailed = NSLocalizedString(
            "aiHelp.chat.analyticsCheckFailed",
            value: "Could not check analytics setting: %1$@",
            comment: "Diagnostic error when analytics check fails. %1$@ is the error description"
        )
        static let enablingAnalytics = NSLocalizedString(
            "aiHelp.chat.enablingAnalytics",
            value: "Enabling analytics...",
            comment: "Message shown while enabling analytics"
        )
        static let analyticsNowEnabled = NSLocalizedString(
            "aiHelp.chat.analyticsNowEnabled",
            value: "Analytics has been enabled successfully!",
            comment: "Message after analytics is enabled"
        )
        static let relaunchApp = NSLocalizedString(
            "aiHelp.chat.relaunchApp",
            value: "Please close and reopen the app for the changes to take effect.",
            comment: "Instruction to relaunch app after enabling analytics"
        )
        static let enableAnalyticsFailed = NSLocalizedString(
            "aiHelp.chat.enableAnalyticsFailed",
            value: "Failed to enable analytics: %1$@",
            comment: "Error message when enabling analytics fails. %1$@ is the error description"
        )

        // Orders
        static let orderSyncSuccess = NSLocalizedString(
            "aiHelp.chat.orderSyncSuccess",
            value: "Orders loaded successfully from your site.",
            comment: "Diagnostic result when order sync succeeds"
        )
        static let orderSyncSuccessHint = NSLocalizedString(
            "aiHelp.chat.orderSyncSuccessHint",
            value: "Order loading seems to be working. Try pulling to refresh on the Orders screen. If the issue persists, contact support.",
            comment: "Hint after successful order sync diagnostic"
        )
        static let orderSyncFailed = NSLocalizedString(
            "aiHelp.chat.orderSyncFailed",
            value: "Failed to load orders: %1$@",
            comment: "Diagnostic error when order sync fails. %1$@ is the error description"
        )
        static let orderSyncFailedHint = NSLocalizedString(
            "aiHelp.chat.orderSyncFailedHint",
            value: "Please check your internet connection and ensure your site is accessible. If the problem continues, contact support.",
            comment: "Hint after failed order sync diagnostic"
        )

        // Products
        static let productSyncSuccess = NSLocalizedString(
            "aiHelp.chat.productSyncSuccess",
            value: "Products loaded successfully from your site.",
            comment: "Diagnostic result when product sync succeeds"
        )
        static let productSyncSuccessHint = NSLocalizedString(
            "aiHelp.chat.productSyncSuccessHint",
            value: "Product loading seems to be working. Try pulling to refresh on the Products screen. If the issue persists, contact support.",
            comment: "Hint after successful product sync diagnostic"
        )
        static let productSyncFailed = NSLocalizedString(
            "aiHelp.chat.productSyncFailed",
            value: "Failed to load products: %1$@",
            comment: "Diagnostic error when product sync fails. %1$@ is the error description"
        )
        static let productSyncFailedHint = NSLocalizedString(
            "aiHelp.chat.productSyncFailedHint",
            value: "Please check your internet connection and ensure your site is accessible. If the problem continues, contact support.",
            comment: "Hint after failed product sync diagnostic"
        )

        // Notifications
        static let notWPComAuth = NSLocalizedString(
            "aiHelp.chat.notWPComAuth",
            value: "You are not signed in with a WordPress.com account.",
            comment: "Diagnostic result when user is not authenticated with WordPress.com"
        )
        static let notWPComAuthHint = NSLocalizedString(
            "aiHelp.chat.notWPComAuthHint",
            value: "Push notifications require a WordPress.com account. Please sign in with your WordPress.com credentials.",
            comment: "Hint when user is not authenticated with WordPress.com"
        )
        static let wpComAuthOK = NSLocalizedString(
            "aiHelp.chat.wpComAuthOK",
            value: "WordPress.com authentication is active.",
            comment: "Diagnostic result when WPCom auth is confirmed"
        )
        static let jetpackRequiredHint = NSLocalizedString(
            "aiHelp.chat.jetpackRequiredHint",
            value: "Jetpack must be installed and connected for push notifications to work. Please set up Jetpack on your site.",
            comment: "Hint when Jetpack is not properly configured for notifications"
        )
        static let notificationsEnabled = NSLocalizedString(
            "aiHelp.chat.notificationsEnabled",
            value: "Push notification permissions are granted.",
            comment: "Diagnostic result when notification permissions are enabled"
        )
        static let notificationsDisabled = NSLocalizedString(
            "aiHelp.chat.notificationsDisabled",
            value: "Push notifications are not enabled. Please enable them in Settings.",
            comment: "Diagnostic result when notification permissions are disabled"
        )
        static let openSettings = NSLocalizedString(
            "aiHelp.chat.openSettings",
            value: "Open Settings",
            comment: "Button title to open iOS notification settings"
        )
        static let notificationCheckComplete = NSLocalizedString(
            "aiHelp.chat.notificationCheckComplete",
            value: "Notification checks complete. If you're still not receiving notifications, try toggling them off and on in Settings, or contact support.",
            comment: "Message after all notification diagnostics complete"
        )

        // AI Analysis
        static let analyzingInput = NSLocalizedString(
            "aiHelp.chat.analyzingInput",
            value: "Analyzing your issue...",
            comment: "Message shown while AI analyzes user input"
        )
        static let aiAnalysisFailed = NSLocalizedString(
            "aiHelp.chat.aiAnalysisFailed",
            value: "I wasn't able to analyze your issue automatically. Please contact support for further assistance.",
            comment: "Message when AI analysis fails"
        )
    }
}
