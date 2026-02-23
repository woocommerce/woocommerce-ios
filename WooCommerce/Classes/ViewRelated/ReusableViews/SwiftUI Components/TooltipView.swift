import SwiftUI

/// Modifier to display a tooltip as a popover.
///
struct TooltipView: ViewModifier {
    /// Indicates if the tooltip should be shown or not.
    ///
    @Binding var isPresented: Bool

    let toolTipTitle: String
    let toolTipDescription: String

    func body(content: Content) -> some View {
        content
            .popover(isPresented: $isPresented, attachmentAnchor: .point(.trailing)) {
                TooltipPopover(toolTipTitle: toolTipTitle, toolTipDescription: toolTipDescription)
                    .padding()
            }
    }
}

extension View {
    /// Displays a tooltip when `isPresented` is `true`.
    func tooltip(isPresented: Binding<Bool>,
                 toolTipTitle: String,
                 toolTipDescription: String) -> some View {
        self.modifier(TooltipView(isPresented: isPresented,
                                  toolTipTitle: toolTipTitle,
                                  toolTipDescription: toolTipDescription))
    }
}

/// Tooltip view that can be displayed as a popover
private struct TooltipPopover: View {
    let toolTipTitle: String
    let toolTipDescription: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(toolTipTitle)
                .font(.body)
                .foregroundColor(.white)
                .fontWeight(.bold)
            Text(toolTipDescription)
                .font(.body)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(.gray)
        }
        .padding()
        .presentationBackground(Color(.systemGray5.color(for: UITraitCollection(userInterfaceStyle: .dark))))
        .presentationCompactAdaptation(.popover)
    }
}
