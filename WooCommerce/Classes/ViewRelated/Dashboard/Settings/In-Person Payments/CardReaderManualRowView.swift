import SwiftUI

struct CardReaderManualRowView: View {
    // Tracks the scale of the view due to accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    /// Environment safe areas
    ///
    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    let manual: Manual

    var body: some View {
        NavigationLink(destination: SafariView(url: URL(string: manual.urlString)!)) {
            HStack {
                Image(uiImage: manual.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Constants.imageSize * scale, height: Constants.imageSize * scale, alignment: .center)
                Text(manual.name)
                .font(.body)
                Spacer()
                DisclosureIndicator()
            }
            .padding()
            .padding(.horizontal, insets: safeAreaInsets)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CardReaderManualRowView_Previews: PreviewProvider {
    static var previews: some View {
        CardReaderManualRowView(manual: Manual(id: 0, image: .cardReaderManualIcon, name: "empty", urlString: "empty"))
    }
}

private extension CardReaderManualRowView {
    enum Constants {
        static let imageSize: CGFloat = 64
    }
}
