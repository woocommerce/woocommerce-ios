
#if canImport(SwiftUI) && DEBUG
import SwiftUI
import Gridicons

@available(iOS 13.0, *)
struct StarsRatingView: UIViewRepresentable {
   // typealias UIViewType = RatingView

    var rating: Double = 0.0
    var starImage: UIImage
    var emptyStarImage: UIImage

    var configuration = { (view: RatingView) in }

    func makeUIView(context: Context) -> RatingView {
        return RatingView(frame: .zero)
    }

    func updateUIView(_ uiView: RatingView, context: Context) {
        uiView.rating = CGFloat(rating)
        uiView.starImage = starImage
        uiView.emptyStarImage = emptyStarImage
    }
}

@available(iOS 13.0, *)
struct StarRatingView_Previews: PreviewProvider {
    static var previews: some View {
        StarsRatingView(starImage: UIImage.starImage(size: 30.0), emptyStarImage: UIImage.starImage(size: 30.0).withTintColor(.red)) {
            $0.rating = 3.0
        }
    }
}

#endif
