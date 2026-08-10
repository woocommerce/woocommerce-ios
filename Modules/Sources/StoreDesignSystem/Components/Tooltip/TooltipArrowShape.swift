import SwiftUI

/// The tooltip's triangular arrow. The apex points away from the bubble along `edge`, the base sits
/// flush against the bubble, and only the tip is rounded.
struct TooltipArrowShape: Shape {
    /// Triangle base width, along the edge.
    static let base: CGFloat = 22
    /// Triangle protrusion, perpendicular to the edge.
    static let depth: CGFloat = 10

    let edge: Edge
    var tipRadius: CGFloat = 1.5

    func path(in rect: CGRect) -> Path {
        let base1: CGPoint
        let base2: CGPoint
        let apex: CGPoint

        switch edge {
        case .top:
            base1 = CGPoint(x: rect.minX, y: rect.maxY)
            base2 = CGPoint(x: rect.maxX, y: rect.maxY)
            apex = CGPoint(x: rect.midX, y: rect.minY)
        case .bottom:
            base1 = CGPoint(x: rect.minX, y: rect.minY)
            base2 = CGPoint(x: rect.maxX, y: rect.minY)
            apex = CGPoint(x: rect.midX, y: rect.maxY)
        case .leading:
            base1 = CGPoint(x: rect.maxX, y: rect.minY)
            base2 = CGPoint(x: rect.maxX, y: rect.maxY)
            apex = CGPoint(x: rect.minX, y: rect.midY)
        case .trailing:
            base1 = CGPoint(x: rect.minX, y: rect.minY)
            base2 = CGPoint(x: rect.minX, y: rect.maxY)
            apex = CGPoint(x: rect.maxX, y: rect.midY)
        }

        var path = Path()
        path.move(to: base1)
        path.addArc(tangent1End: apex, tangent2End: base2, radius: tipRadius)
        path.addLine(to: base2)
        path.closeSubpath()
        return path
    }
}
