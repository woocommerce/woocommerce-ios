import SwiftUI

struct ToolActivityPill: View {

    let toolName: String
    let status: ToolCallStatus

    var body: some View {
        HStack(spacing: AssistantSpacing.small) {
            icon
                .accessibilityHidden(true)
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.assistantMuted)
        }
        .padding(.horizontal, AssistantSpacing.small)
        .padding(.vertical, AssistantSpacing.xSmall)
        .background(Color(.listForeground(modal: false)))
        .clipShape(RoundedRectangle(cornerRadius: AssistantRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: AssistantRadius.medium)
                .stroke(Color.assistantSurfaceBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 1)
        // Re-key on iconName so status flips animate the chrome too, not just the icon.
        .animation(.easeInOut(duration: 0.22), value: title + iconName)
    }

    @ViewBuilder
    private var icon: some View {
        Image(systemName: iconName)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(iconColor)
            .symbolEffect(.pulse.byLayer, options: .repeating, isActive: isRunning)
            .contentTransition(.symbolEffect(.replace))
            // Fixed slot so the label does not shift when wider terminal glyphs replace ellipsis.
            .frame(width: 14, height: 14)
    }

    private var iconName: String {
        switch status {
        case .running: return "ellipsis"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }

    private var iconColor: Color {
        switch status {
        case .running: return Color(.accent)
        case .completed: return Color.assistantSuccess
        case .failed: return Color.assistantError
        }
    }

    private var isRunning: Bool {
        if case .running = status { return true }
        return false
    }

    private var title: String {
        let label = ToolActivityCopy.label(for: toolName)
        switch status {
        case .running, .completed:
            return label
        case .failed(let message):
            return String(format: Localization.failedFormat, label, message)
        }
    }

    private enum Localization {
        static let failedFormat = NSLocalizedString(
            "assistant.tool.activity.failedFormat",
            value: "%1$@ - %2$@",
            comment: "Tool call failed: %1$@ is the action label, %2$@ is the failure message"
        )
    }
}

enum ToolActivityCopy {

    static func label(for toolName: String) -> String {
        let family = ToolFamily.from(toolName: toolName)
        let access = ToolAccess.from(toolName: toolName)
        switch family {
        case .orders:
            return access == .write ? Localization.ordersWrite : Localization.ordersRead
        case .products:
            return access == .write ? Localization.productsWrite : Localization.productsRead
        case .productVariations:
            return access == .write ? Localization.productVariationsWrite : Localization.productVariationsRead
        case .customers:
            return access == .write ? Localization.customersWrite : Localization.customersRead
        case .analytics:
            return Localization.analyticsRead
        case .other:
            return access == .write ? Localization.otherWrite : Localization.otherRead
        }
    }

    private enum ToolFamily {
        case orders
        case products
        case productVariations
        case customers
        case analytics
        case other

        static func from(toolName: String) -> ToolFamily {
            if toolName.hasPrefix("product_variations_") { return .productVariations }
            if toolName.hasPrefix("orders_") { return .orders }
            if toolName.hasPrefix("products_") { return .products }
            if toolName.hasPrefix("customers_") { return .customers }
            if toolName.hasPrefix("analytics_") { return .analytics }
            return .other
        }
    }

    private enum ToolAccess {
        case read
        case write

        static func from(toolName: String) -> ToolAccess {
            let writeSuffixes = ["_update", "_create", "_delete", "_bulk_update"]
            for suffix in writeSuffixes where toolName.hasSuffix(suffix) {
                return .write
            }
            return .read
        }
    }

    private enum Localization {
        static let ordersRead = NSLocalizedString(
            "assistant.tool.activity.orders.read",
            value: "Checking orders",
            comment: "Tool activity label shown while the assistant fetches orders."
        )
        static let ordersWrite = NSLocalizedString(
            "assistant.tool.activity.orders.write",
            value: "Updating orders",
            comment: "Tool activity label shown while the assistant changes orders."
        )
        static let productsRead = NSLocalizedString(
            "assistant.tool.activity.products.read",
            value: "Checking products",
            comment: "Tool activity label shown while the assistant fetches products."
        )
        static let productsWrite = NSLocalizedString(
            "assistant.tool.activity.products.write",
            value: "Updating products",
            comment: "Tool activity label shown while the assistant changes products."
        )
        static let productVariationsRead = NSLocalizedString(
            "assistant.tool.activity.productVariations.read",
            value: "Checking product variations",
            comment: "Tool activity label shown while the assistant fetches product variations."
        )
        static let productVariationsWrite = NSLocalizedString(
            "assistant.tool.activity.productVariations.write",
            value: "Updating product variations",
            comment: "Tool activity label shown while the assistant changes product variations."
        )
        static let customersRead = NSLocalizedString(
            "assistant.tool.activity.customers.read",
            value: "Checking customers",
            comment: "Tool activity label shown while the assistant fetches customers."
        )
        static let customersWrite = NSLocalizedString(
            "assistant.tool.activity.customers.write",
            value: "Updating customers",
            comment: "Tool activity label shown while the assistant changes customers."
        )
        static let analyticsRead = NSLocalizedString(
            "assistant.tool.activity.analytics.read",
            value: "Checking analytics",
            comment: "Tool activity label shown while the assistant fetches analytics data."
        )
        static let otherRead = NSLocalizedString(
            "assistant.tool.activity.other.read",
            value: "Checking your store",
            comment: "Generic tool activity label shown while the assistant performs an unclassified read."
        )
        static let otherWrite = NSLocalizedString(
            "assistant.tool.activity.other.write",
            value: "Updating your store",
            comment: "Generic tool activity label shown while the assistant performs an unclassified write."
        )
    }
}

#if DEBUG
#Preview("In chat") {
    AssistantChatView.preview(.toolActivityPill)
}

#Preview("Running") {
    ToolActivityPill(toolName: "customers_list", status: .running)
        .padding()
}

#Preview("Completed") {
    ToolActivityPill(toolName: "orders_list",
                     status: .completed(summary: "[ {id: 3479}, {id: 3478} ]"))
        .padding()
}
#endif
