import SwiftUI

struct TooltipView: View {

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
