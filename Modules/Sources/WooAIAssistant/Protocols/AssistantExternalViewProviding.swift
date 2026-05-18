import SwiftUI

public protocol AssistantExternalViewProviding: Sendable {
    @MainActor func orderRow(payload: OrderCardPayload,
                             showDivider: Bool,
                             onTap: @escaping @MainActor () -> Void) -> AnyView?
    @MainActor func productRow(payload: ProductCardPayload,
                               showDivider: Bool,
                               onTap: @escaping @MainActor () -> Void) -> AnyView?
    @MainActor func productVariationRow(payload: ProductVariationCardPayload,
                                        showDivider: Bool,
                                        onTap: @escaping @MainActor () -> Void) -> AnyView?
    @MainActor func customerRow(payload: CustomerCardPayload,
                                showDivider: Bool,
                                onTap: @escaping @MainActor () -> Void) -> AnyView?
    @MainActor func statsCardView(toolName: String, payload: AnyCodableJSON) -> AnyView?
}

public extension AssistantExternalViewProviding {
    @MainActor func orderRow(payload: OrderCardPayload,
                             showDivider: Bool,
                             onTap: @escaping @MainActor () -> Void) -> AnyView? { nil }
    @MainActor func productRow(payload: ProductCardPayload,
                               showDivider: Bool,
                               onTap: @escaping @MainActor () -> Void) -> AnyView? { nil }
    @MainActor func productVariationRow(payload: ProductVariationCardPayload,
                                        showDivider: Bool,
                                        onTap: @escaping @MainActor () -> Void) -> AnyView? { nil }
    @MainActor func customerRow(payload: CustomerCardPayload,
                                showDivider: Bool,
                                onTap: @escaping @MainActor () -> Void) -> AnyView? { nil }
    @MainActor func statsCardView(toolName: String, payload: AnyCodableJSON) -> AnyView? { nil }
}
