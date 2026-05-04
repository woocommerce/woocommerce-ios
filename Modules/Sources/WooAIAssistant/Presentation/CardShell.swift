import SwiftUI

struct CardShell<Content: View>: View {

    let label: String
    var accent: Bool = false
    var trailingChevron: Bool = false
    let content: () -> Content

    init(label: String,
         accent: Bool = false,
         trailingChevron: Bool = false,
         @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self.accent = accent
        self.trailingChevron = trailingChevron
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AssistantSpacing.small) {
            HStack {
                Text(label)
                    .font(.assistantMonospaced)
                    .textCase(.uppercase)
                    .foregroundStyle(accent ? Color(.accent) : Color.assistantTextFaint)
                Spacer(minLength: 0)
                if trailingChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.assistantTextFaint)
                        .accessibilityHidden(true)
                }
            }
            content()
        }
        .padding(AssistantSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.assistantSurfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: AssistantRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AssistantRadius.card)
                .stroke(accent ? Color(.accent).opacity(0.4) : Color.assistantSurfaceBorder,
                        lineWidth: 1)
        )
    }
}

#if DEBUG
#Preview("Default") {
    CardShell(label: "Order #3479") {
        Text("Sample content")
            .font(.assistantBody)
    }
    .padding()
}

#Preview("Accent + chevron") {
    CardShell(label: "2 orders", accent: true, trailingChevron: true) {
        Text("Tap to drill in")
            .font(.assistantBody)
            .foregroundStyle(Color.assistantMuted)
    }
    .padding()
}
#endif
