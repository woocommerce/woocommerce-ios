import SwiftUI
import Combine
import struct Yosemite.ProductReviewFromNoteParcel

/// SwiftUI view for the review list screen.
///
struct ReviewsView: View {
    let siteID: Int64
    let navigationPublisher: AnyPublisher<Void, Never>
    let productReviewFromNoteParcel: ProductReviewFromNoteParcel?

    @Binding var showingReviewDetail: Bool

    var body: some View {
        ReviewsWrapperView(siteID: siteID, navigationPublisher: navigationPublisher)
            .navigationTitle(Localization.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showingReviewDetail) {
                if let parcel = productReviewFromNoteParcel {
                    ReviewDetailView(productReview: parcel.review,
                                     product: parcel.product,
                                     notification: parcel.note)
                }
            }
    }
}

private extension ReviewsView {
    enum Localization {
        static let navigationTitle = NSLocalizedString(
            "reviewsView.navigationTitle",
            value: "Reviews",
            comment: "Navigation title for the review list screen"
        )
    }
}

/// SwiftUI wrapper for `ReviewsViewController`
///
private struct ReviewsWrapperView: UIViewControllerRepresentable {
    let siteID: Int64
    let navigationPublisher: AnyPublisher<Void, Never>

    func makeUIViewController(context: Self.Context) -> ReviewsViewController {
        let viewController = ReviewsViewController(siteID: siteID, navigationPublisher: navigationPublisher)
        return viewController
    }

    func updateUIViewController(_ uiViewController: ReviewsViewController, context: Context) {
        // nothing to do here
    }
}
