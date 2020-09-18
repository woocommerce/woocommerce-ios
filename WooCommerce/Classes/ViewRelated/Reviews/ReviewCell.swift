
#if canImport(SwiftUI) && DEBUG
import SwiftUI
import Gridicons

@available(iOS 13.0, *)
struct ReviewCell: View {


    var body: some View {
        HStack {
            Rectangle()
                .padding(.vertical, 0.0)
                .frame(width: 2)
                .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)

            Spacer().frame(width: 12)

            Text("\u{f300}")
                .frame(width: 25, height: 25)
                .padding(.top, 11.0)

            Spacer().frame(width: 16)

            VStack(alignment: .leading, spacing: 3.0) {
                Text("Subject Label")
                Text("Snippet Label")
                StarsRatingView(rating: 3.0,
                                starImage: Star.filledImage,
                                emptyStarImage: Star.emptyImage)
                    .frame(
                        width: 100,
                        height: 13,
                        alignment: .leading)
            }
            .padding(.top, 11.0)
            .padding(.bottom, 20.0)
        }
    }
}

@available(iOS 13.0, *)
struct ReviewCell_Previews: PreviewProvider {
    static var previews: some View {
        ReviewCell()
    }
}

@available(iOS 13.0, *)
private extension ReviewCell {
    enum Star {
        static let size = Double(13)
        static let filledImage = UIImage.starImage(size: Star.size)
        static let emptyImage = UIImage.starImage(size: Star.size).imageWithTintColor(.clear) ?? UIImage.starImage(size: Star.size)
    }
}

#endif
