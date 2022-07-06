import SwiftUI

/// A view to be displayed on Card Reader Manuals screen
///
struct CardReadersView: View {
    // Tracks the scale of the view due to accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    let viewModel = CardReadersViewViewModel()
    var manuals: [Manual] {
        viewModel.manuals
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(manuals, id: \.name) { manual in
                        Divider()
                        NavigationLink(destination: SafariView(url: URL(string: manual.urlString)!)) {
                                Image(uiImage: manual.image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: Constants.imageSize * scale, height: Constants.imageSize * scale, alignment: .center)
                                    .frame(width: geometry.size.width * Constants.imageSizeMultiplier)
                                Text(manual.name)
                                .frame(width: geometry.size.width * Constants.textSizeMultiplier, alignment: .leading)
                                .font(.body)
                                DisclosureIndicator()
                                .frame(width: geometry.size.width * Constants.imageSizeMultiplier)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    Divider()
                }
            }
            .navigationBarTitle(Localization.navigationTitle, displayMode: .inline)
        }
    }
}

struct CardReadersView_Previews: PreviewProvider {
    static var previews: some View {
        CardReadersView()
    }
}

private extension CardReadersView {
    enum Localization {
        static let navigationTitle = NSLocalizedString( "Card reader manuals",
                                                        comment: "Navigation title at the top of the Card reader manuals screen")
    }
}

private extension CardReadersView {
    enum Constants {
        static let iconSize: CGFloat = 16
        static let imageSize: CGFloat = 64
        static let imageSizeMultiplier: CGFloat = 0.2
        static let textSizeMultiplier: CGFloat = 0.6
    }
}
