import SwiftUI
import WooFoundation

public struct AssistantDashboardCardColumnHeaders {
    let leading: String
    let trailing: String

    public init(leading: String, trailing: String) {
        self.leading = leading
        self.trailing = trailing
    }
}

public struct AssistantDashboardCardShell<Body: View>: View {

    private let title: String?
    private let iconSystemName: String?
    private let subtitle: String?
    private let columnHeaders: AssistantDashboardCardColumnHeaders?
    private let padBody: Bool
    private let bodyContent: () -> Body

    public init(title: String?,
                iconSystemName: String? = nil,
                subtitle: String? = nil,
                columnHeaders: AssistantDashboardCardColumnHeaders? = nil,
                padBody: Bool = true,
                @ViewBuilder bodyContent: @escaping () -> Body) {
        self.title = title
        self.iconSystemName = iconSystemName
        self.subtitle = subtitle
        self.columnHeaders = columnHeaders
        self.padBody = padBody
        self.bodyContent = bodyContent
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: padBody ? Layout.titleToBodySpacing : 0) {
            if let title {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Layout.titleIconSpacing) {
                        if let iconSystemName {
                            Image(systemName: iconSystemName)
                                .font(.headline)
                                .foregroundStyle(Color.assistantBubbleAssistantText)
                                .accessibilityHidden(true)
                        }
                        Text(title)
                            .headlineStyle()
                    }
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(Color.assistantMuted)
                    }
                }
                .padding(.horizontal, Layout.padding)
                .padding(.top, Layout.padding)
            }

            if let columnHeaders {
                HStack {
                    Text(columnHeaders.leading)
                        .subheadlineStyle()
                        .fontWeight(.semibold)
                    Spacer()
                    Text(columnHeaders.trailing)
                        .subheadlineStyle()
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, Layout.padding)
            }

            bodyContent()
                .padding(.bottom, padBody ? Layout.padding : 0)
        }
        .background(Color(.listForeground(modal: false)))
        .clipShape(RoundedRectangle(cornerRadius: AssistantRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AssistantRadius.card)
                .stroke(Color.assistantSurfaceBorder, lineWidth: Layout.borderWidth)
        )
        .shadow(color: Color.black.opacity(Layout.shadowOpacity),
                radius: Layout.shadowRadius,
                x: 0,
                y: Layout.shadowYOffset)
    }
}

private enum Layout {
    static let padding: CGFloat = 16
    static let titleToBodySpacing: CGFloat = 12
    static let titleIconSpacing: CGFloat = 8
    static let borderWidth: CGFloat = 1
    static let shadowOpacity: Double = 0.06
    static let shadowRadius: CGFloat = 4
    static let shadowYOffset: CGFloat = 1
}

#if DEBUG
#Preview("Single body") {
    AssistantDashboardCardShell(
        title: "Order #3479",
        bodyContent: {
            Text("One reused row would render here.")
                .padding(.horizontal, 16)
        }
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("List body with column headers") {
    AssistantDashboardCardShell(
        title: "Products",
        columnHeaders: .init(leading: "Products", trailing: "Stock levels"),
        bodyContent: {
            VStack(spacing: 0) {
                ForEach(0..<4) { index in
                    HStack {
                        Text("Product \(index + 1)")
                        Spacer()
                        Text("In stock")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    Divider()
                }
            }
        }
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
#endif
