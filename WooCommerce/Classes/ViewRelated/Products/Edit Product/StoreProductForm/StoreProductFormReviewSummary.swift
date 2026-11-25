import StoreDesignSystem
import SwiftUI

struct StoreProductFormReviewSummary: View {
    let review: StoreProductFormSettingsRow.Review

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: StoreSpacing.s2) {
                stars
                reviewCount.fixedSize(horizontal: true, vertical: false)
            }
            VStack(alignment: .leading, spacing: StoreSpacing.s1) {
                stars
                reviewCount
            }
        }
    }

    private var reviewCount: some View {
        Text(review.countDescription)
            .storeTextStyle(.bodyMedium)
    }

    private var stars: some View {
        HStack(spacing: StoreSpacing.s0) {
            ForEach(0..<Self.starCount) { index in
                let fill = CGFloat(min(max(rating - Double(index), 0), 1))
                StoreIcon.Star.regular.image(size: .medium)
                    .overlay {
                        StoreIcon.Star.solid.image(size: .medium)
                            .mask {
                                GeometryReader { geometry in
                                    Rectangle()
                                        .frame(width: geometry.size.width * fill)
                                }
                            }
                    }
            }
        }
        .foregroundStyle(Color.storeAlertOrange)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rating.formatted())
    }

    private var rating: Double {
        review.average.isFinite ? min(max(review.average, 0), Double(Self.starCount)) : 0
    }

    private static let starCount = 5
}
