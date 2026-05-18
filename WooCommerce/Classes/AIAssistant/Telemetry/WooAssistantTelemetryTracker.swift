import EventHorizonSDK
import Foundation
import protocol WooFoundation.Analytics
import WooAIAssistant

struct WooAssistantTelemetryTracker: AssistantTelemetryTracker {

    private let analytics: Analytics

    init(analytics: Analytics) {
        self.analytics = analytics
    }

    func track(_ event: AssistantTelemetryEvent) {
        switch event {
        case .conversationStarted(let context):
            analytics.track(Event.aiAssistantConversationStarted(
                conversationId: context.conversationID,
                requestId: context.requestID,
                messageId: context.messageID
            ))

        case .turnStarted(let context, let isRetry, let stack, let prompt, let catalog):
            analytics.track(Event.aiAssistantTurnStarted(
                conversationId: context.conversationID,
                requestId: context.requestID,
                messageId: context.messageID,
                isRetry: isRetry,
                completionStack: stack,
                promptVersion: prompt,
                toolCatalogVersion: catalog
            ))

        case .toolCallCompleted(let context, let toolName, let status, let errorKind, let durationMs):
            analytics.track(Event.aiAssistantToolCallCompleted(
                conversationId: context.conversationID,
                requestId: context.requestID,
                messageId: context.messageID,
                toolName: toolName,
                status: toSDK(status),
                errorKind: errorKind.map(toSDK),
                durationMs: durationMs.map(Int.init)
            ))

        case .showCardsProcessed(let context, let requested, let rendered, let missing, let rejected):
            analytics.track(Event.aiAssistantShowCardsProcessed(
                conversationId: context.conversationID,
                requestId: context.requestID,
                messageId: context.messageID,
                requestedCount: requested,
                renderedCount: rendered,
                missingCount: missing,
                rejectedCount: rejected
            ))

        case .cardTapped(let context, let cardFamily, let actionFamily):
            analytics.track(Event.aiAssistantCardTapped(
                conversationId: context.conversationID,
                requestId: context.requestID,
                messageId: context.messageID,
                cardFamily: toSDK(cardFamily),
                actionFamily: toSDK(actionFamily)
            ))

        case .turnCompleted(let context,
                            let outcome,
                            let durationMs,
                            let errorKind,
                            let isRetry,
                            let stack,
                            let prompt,
                            let catalog):
            analytics.track(Event.aiAssistantTurnCompleted(
                conversationId: context.conversationID,
                requestId: context.requestID,
                messageId: context.messageID,
                outcome: toSDK(outcome),
                durationMs: Int(durationMs),
                errorKind: errorKind.map(toSDK),
                isRetry: isRetry,
                completionStack: stack,
                promptVersion: prompt,
                toolCatalogVersion: catalog
            ))
        }
    }

    private func toSDK(_ status: AssistantTelemetryToolStatus) -> AiAssistantToolStatusValue {
        switch status {
        case .success: return .success
        case .failure: return .failure
        }
    }

    private func toSDK(_ outcome: AssistantTelemetryOutcome) -> AiAssistantTurnOutcomeValue {
        switch outcome {
        case .success: return .success
        case .failed: return .failed
        case .cancelledByUser: return .cancelledByUser
        case .maxIterations: return .maxIterations
        }
    }

    private func toSDK(_ errorKind: AssistantTelemetryErrorKind) -> AiAssistantErrorKindValue {
        switch errorKind {
        case .network: return .network
        case .auth: return .auth
        case .rateLimited: return .rateLimited
        case .timeout: return .timeout
        case .serverError: return .serverError
        case .validationError: return .validationError
        case .cancelled: return .cancelled
        case .unknown: return .unknown
        }
    }

    private func toSDK(_ cardFamily: AssistantTelemetryCardFamily) -> AiAssistantCardFamilyValue {
        switch cardFamily {
        case .order: return .order
        case .product: return .product
        case .variation: return .variation
        case .customer: return .customer
        case .analyticsStats: return .analyticsStats
        case .unknown: return .unknown
        }
    }

    private func toSDK(_ actionFamily: AssistantTelemetryActionFamily) -> AiAssistantActionFamilyValue {
        switch actionFamily {
        case .openOrder: return .openOrder
        case .openProduct: return .openProduct
        case .openProductVariation: return .openProductVariation
        case .openCustomer: return .openCustomer
        case .openAnalytics: return .openAnalytics
        case .unknown: return .unknown
        }
    }
}
