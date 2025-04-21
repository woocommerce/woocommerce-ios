import SwiftUI

enum POSCouponImageState {
    case success
    case error
    case normal
}

struct POSCouponImageView: View {
    private let size: CGFloat
    private let state: POSCouponImageState

    init(size: CGFloat, state: POSCouponImageState = .normal) {
        self.size = size
        self.state = state
    }

    private var foregroundColor: Color {
        switch state {
        case .success:
            return .posSuccess
        case .error:
            return .posError
        case .normal:
            return .posSurfaceDim
        }
    }

    private var tagColor: Color {
        switch state {
        case .success:
            return .posOnSuccess
        case .error:
            return .posOnError
        case .normal:
            return .posOnSurfaceVariantLowest
        }
    }

    var body: some View {
        Rectangle()
            .foregroundColor(foregroundColor)
            .overlay {
                Image(systemName: "tag")
                    .font(.posButtonSymbolMedium)
                    .foregroundColor(tagColor)
            }
            .frame(width: size)
            .frame(minHeight: size)
            .accessibilityHidden(true)
    }
}

#Preview {
    POSCouponImageView(size: 100)
}
