import SwiftUI

enum POSCouponImageState {
    case success
    case applied
    case error
    case normal
    case expired
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
        case .success, .applied:
            return .posSuccess
        case .error:
            return .posError
        case .normal, .expired:
            return .posSurfaceDim
        }
    }

    private var tagColor: Color {
        switch state {
        case .success, .applied:
            return .posOnSuccess
        case .error:
            return .posOnError
        case .normal:
            return .posOnSurfaceVariantLowest
        case .expired:
            return Constants.disabledTitleColor
        }
    }

    private var systemImageName: String {
        switch state {
        case .applied:
            return "checkmark"
        case .success, .error, .normal, .expired:
            return "tag"
        }
    }

    var body: some View {
        Rectangle()
            .foregroundColor(foregroundColor)
            .overlay {
                Image(systemName: systemImageName)
                    .font(.posBodyXLargeRegular)
                    .foregroundColor(tagColor)
            }
            .frame(width: size)
            .frame(minHeight: size)
            .accessibilityHidden(true)
    }
}

private extension POSCouponImageView {
    typealias Constants = PointOfSaleItemListCardConstants
}

#Preview("ImageView states") {
    VStack(spacing: 16) {
        VStack(alignment: .leading) {
            Text("Normal")
                .font(.caption)
                .foregroundStyle(.secondary)
            POSCouponImageView(size: 100)
        }

        VStack(alignment: .leading) {
            Text("Success")
                .font(.caption)
                .foregroundStyle(.secondary)
            POSCouponImageView(size: 100, state: .success)
        }

        VStack(alignment: .leading) {
            Text("Applied")
                .font(.caption)
                .foregroundStyle(.secondary)
            POSCouponImageView(size: 100, state: .applied)
        }

        VStack(alignment: .leading) {
            Text("Error")
                .font(.caption)
                .foregroundStyle(.secondary)
            POSCouponImageView(size: 100, state: .error)
        }

        VStack(alignment: .leading) {
            Text("Expired")
                .font(.caption)
                .foregroundStyle(.secondary)
            POSCouponImageView(size: 100, state: .expired)
        }
    }
    .padding()
}
