import Foundation

public enum AssistantTelemetryEvent: Equatable, Sendable {
    case conversationStarted(context: AssistantTelemetryContext)

    case turnStarted(context: AssistantTelemetryContext,
                     isRetry: Bool,
                     completionStack: String,
                     promptVersion: String,
                     toolCatalogVersion: String)

    case toolCallCompleted(context: AssistantTelemetryContext,
                           toolName: String,
                           status: AssistantTelemetryToolStatus,
                           errorKind: AssistantTelemetryErrorKind?,
                           durationMs: Int64?)

    case showCardsProcessed(context: AssistantTelemetryContext,
                            requestedCount: Int,
                            renderedCount: Int,
                            missingCount: Int,
                            rejectedCount: Int)

    case cardTapped(context: AssistantTelemetryContext,
                    cardFamily: AssistantTelemetryCardFamily,
                    actionFamily: AssistantTelemetryActionFamily)

    case turnCompleted(context: AssistantTelemetryContext,
                       outcome: AssistantTelemetryOutcome,
                       durationMs: Int64,
                       errorKind: AssistantTelemetryErrorKind?,
                       isRetry: Bool,
                       completionStack: String,
                       promptVersion: String,
                       toolCatalogVersion: String)
}

public enum AssistantTelemetryToolStatus: String, Sendable, Equatable {
    case success
    case failure
}

public enum AssistantTelemetryOutcome: String, Sendable, Equatable {
    case success
    case failed
    case cancelledByUser = "cancelled_by_user"
    case maxIterations = "max_iterations"
}

public enum AssistantTelemetryErrorKind: String, Sendable, Equatable {
    case network
    case auth
    case rateLimited = "rate_limited"
    case timeout
    case serverError = "server_error"
    case validationError = "validation_error"
    case cancelled
    case unknown
}

public enum AssistantTelemetryCardFamily: String, Sendable, Equatable {
    case order
    case product
    case variation
    case customer
    case analyticsStats = "analytics_stats"
    case unknown
}

public enum AssistantTelemetryActionFamily: String, Sendable, Equatable {
    case openOrder = "open_order"
    case openProduct = "open_product"
    case openProductVariation = "open_product_variation"
    case openCustomer = "open_customer"
    case openAnalytics = "open_analytics"
    case unknown
}

extension AssistantTelemetryEvent {
    public var requestID: String {
        switch self {
        case .conversationStarted(let context),
             .turnStarted(let context, _, _, _, _),
             .toolCallCompleted(let context, _, _, _, _),
             .showCardsProcessed(let context, _, _, _, _),
             .cardTapped(let context, _, _),
             .turnCompleted(let context, _, _, _, _, _, _, _):
            return context.requestID
        }
    }
}
