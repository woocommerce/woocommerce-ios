import SwiftUI

/// Modifier to display a tooltip as a popover or overlay, depending on the available support.
///
struct TooltipView: ViewModifier {
    /// Indicates if the tooltip should be shown or not.
    ///
    @Binding var isPresented: Bool

    let toolTipTitle: String
    let toolTipDescription: String
    let offset: CGSize?
    let safeAreaInsets: EdgeInsets

    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content
                .popover(isPresented: $isPresented, attachmentAnchor: .point(.trailing)) {
                    TooltipPopover(toolTipTitle: toolTipTitle, toolTipDescription: toolTipDescription)
                        .padding()
                }
        } else {
            content
                .overlay {
                    TooltipOverlay(toolTipTitle: toolTipTitle,
                                   toolTipDescription: toolTipDescription,
                                   offset: offset,
                                   safeAreaInsets: safeAreaInsets)
                    .padding()
                    .renderedIf(isPresented)
                }
        }
    }
}

extension View {
    /// Displays a tooltip when `isPresented` is `true`.
    func tooltip(isPresented: Binding<Bool>,
                 toolTipTitle: String,
                 toolTipDescription: String,
                 offset: CGSize? = nil,
                 safeAreaInsets: EdgeInsets = .zero) -> some View {
        self.modifier(TooltipView(isPresented: isPresented,
                                  toolTipTitle: toolTipTitle,
                                  toolTipDescription: toolTipDescription,
                                  offset: offset,
                                  safeAreaInsets: safeAreaInsets))
    }
}

/// Tooltip view that can be displayed as a popover
@available(iOS 16.4, *)
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

/// Tooltip view that can be used as an overlay.
/// Can be used in iOS <16.4 for tooltips.
private struct TooltipOverlay: View {

    private let toolTipTitle: String
    private let toolTipDescription: String
    private var offset: CGSize? = nil
    private let safeAreaInsets: EdgeInsets

    init(toolTipTitle: String, toolTipDescription: String, offset: CGSize?, safeAreaInsets: EdgeInsets = .zero) {
        self.toolTipTitle = toolTipTitle
        self.toolTipDescription = toolTipDescription
        self.offset = offset
        self.safeAreaInsets = safeAreaInsets
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: Layout.frameCornerRadius )
                .fill(Color.black)

            TooltipPointerView()
                .fill(Color.black)
                .frame(width: Layout.tooltipPointerSize, height: Layout.tooltipPointerSize)
                .offset(x: Layout.tooltipPointerOffset, y: Layout.tooltipPointerOffset)

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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
        .shadow(color: Color.secondary, radius: Layout.toolTipShadowCornerRadius)
        .offset(offset ?? CGSize(width: 0, height: 0))
        .padding(insets: safeAreaInsets)
    }

    private struct TooltipPointerView: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxY, y: rect.maxY))
            path.closeSubpath()
            return path
        }
    }

    private enum Layout {
        static let frameCornerRadius: CGFloat = 4
        static let toolTipShadowCornerRadius: CGFloat = 26
        static let tooltipPointerSize: CGFloat = 20
        static let tooltipPointerOffset: CGFloat = -10
    }
}
