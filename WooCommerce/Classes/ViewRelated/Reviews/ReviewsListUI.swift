
#if canImport(SwiftUI) && DEBUG
import SwiftUI

@available(iOS 13.0, *)
struct ReviewsListUI: View {
    var body: some View {
        NavigationView {
            ScrollView {
                Spacer()
                HStack() {
                    VStack(alignment: .leading) {
                        ReviewCell()
                        Divider()
                        ReviewCell()
                        ReviewCell()
                        ReviewCell()
                        ReviewCell()
                        ReviewCell()
                        ReviewCell()
                        ReviewCell()
                        ReviewCell()
                    }
                }.navigationBarTitle("Reviews")
            }
        }
    }
}

@available(iOS 13.0, *)
struct ReviewsListUI_Previews: PreviewProvider {
    static var previews: some View {
        ReviewsListUI()
    }
}
#endif
