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
            analytics.track(AiAssistantConversationStartedEvent(
                conversationId: context.conversationID,
                requestId: context.requestID,
                messageId: context.messageID
            ))

        case .turnStarted(let context, let isRetry, let stack, let prompt, let catalog):
            analytics.track(AiAssistantTurnStartedEvent(
                conversationId: context.conversationID,
                requestId: context.requestID,
                messageId: context.messageID,
                isRetry: isRetry,
                completionStack: stack,
                promptVersion: prompt,
                toolCatalogVersion: catalog
            ))

        case .toolCallCompleted(let context, let toolName, let status, let errorKind, let durationMs):
            analytics.track(AiAssistantToolCallCompletedEvent(
                conversationId: context.conversationID,
                requestId: context.requestID,
                messageId: context.messageID,
                toolName: toolName,
                status: toShim(status),
                errorKind: errorKind.map(toShim),
                durationMs: durationMs.map(Int.init)
            ))

        case .showCardsProcessed(let context, let requested, let rendered, let missing, let rejected):
            analytics.track(AiAssistantShowCardsProcessedEvent(
                conversationId: context.conversationID,
                requestId: context.requestID,
                messageId: context.messageID,
                requestedCount: requested,
                renderedCount: rendered,
                missingCount: missing,
                rejectedCount: rejected
            ))

        case .cardTapped(let context, let cardFamily, let actionFamily):
            analytics.track(AiAssistantCardTappedEvent(
                conversationId: context.conversationID,
                requestId: context.requestID,
                messageId: context.messageID,
                cardFamily: toShim(cardFamily),
                actionFamily: toShim(actionFamily)
            ))

        case .turnCompleted(let context,
                            let outcome,
                            let durationMs,
                            let errorKind,
                            let isRetry,
                            let stack,
                            let prompt,
                            let catalog):
            analytics.track(AiAssistantTurnCompletedEvent(
                conversationId: context.conversationID,
                requestId: context.requestID,
                messageId: context.messageID,
                outcome: toShim(outcome),
                durationMs: Int(durationMs),
                errorKind: errorKind.map(toShim),
                isRetry: isRetry,
                completionStack: stack,
                promptVersion: prompt,
                toolCatalogVersion: catalog
            ))
        }
    }

    private func toShim(_ status: AssistantTelemetryToolStatus) -> AiAssistantToolStatusValue {
        switch status {
        case .success: return .success
        case .failure: return .failure
        }
    }

    private func toShim(_ outcome: AssistantTelemetryOutcome) -> AiAssistantTurnOutcomeValue {
        switch outcome {
        case .success: return .success
        case .failed: return .failed
        case .cancelledByUser: return .cancelledByUser
        case .maxIterations: return .maxIterations
        }
    }

    private func toShim(_ errorKind: AssistantTelemetryErrorKind) -> AiAssistantErrorKindValue {
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

    private func toShim(_ cardFamily: AssistantTelemetryCardFamily) -> AiAssistantCardFamilyValue {
        switch cardFamily {
        case .order: return .order
        case .product: return .product
        case .variation: return .variation
        case .customer: return .customer
        case .analyticsStats: return .analyticsStats
        case .unknown: return .unknown
        }
    }

    private func toShim(_ actionFamily: AssistantTelemetryActionFamily) -> AiAssistantActionFamilyValue {
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
