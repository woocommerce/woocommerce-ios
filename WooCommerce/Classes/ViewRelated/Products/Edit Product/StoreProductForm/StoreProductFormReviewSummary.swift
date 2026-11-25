import StoreDesignSystem
import SwiftUI

struct StoreProductFormReviewSummary: View {
    let review: StoreProductFormSettingsRow.Review

    var body: some View {
        if let average = review.average {
            let rating = min(max(average, 0), Double(Self.starCount))
            ViewThatFits(in: .horizontal) {
                HStack(spacing: StoreSpacing.s2) {
                    stars(for: rating)
                    reviewCount.fixedSize(horizontal: true, vertical: false)
                }
                VStack(alignment: .leading, spacing: StoreSpacing.s1) {
                    stars(for: rating)
                    reviewCount
                }
            }
        } else {
            reviewCount
        }
    }

    private var reviewCount: some View {
        Text(review.countDescription)
            .storeTextStyle(.bodyMedium)
    }

    private func stars(for rating: Double) -> some View {
        HStack(spacing: StoreSpacing.s0) {
            ForEach(0..<5) { index in
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

    private static let starCount = 5
}
