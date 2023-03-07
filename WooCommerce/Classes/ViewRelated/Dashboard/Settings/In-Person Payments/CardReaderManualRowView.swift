import SwiftUI

struct CardReaderManualRowView: View {
    // Environment safe areas
    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    // Tracks the scale of the view due to accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    @State var webViewPresented = false

    let manual: Manual

    var body: some View {
        NavigationRow(content: {
            HStack {
                Image(uiImage: manual.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Constants.imageSize * scale, height: Constants.imageSize * scale, alignment: .center)
                Text(manual.name)
                .font(.body)
            }
            .sheet(isPresented: $webViewPresented, onDismiss: {
                webViewPresented = false
            }, content: {
                SafariSheetView(url: URL(string: manual.urlString)!)
            })
        }, action: {
            webViewPresented.toggle()
        })
            .buttonStyle(PlainButtonStyle())
    }
}

struct CardReaderManualRowView_Previews: PreviewProvider {
    static var previews: some View {
        CardReaderManualRowView(manual: Manual(id: 0, image: .cardReaderManualIcon, name: "", urlString: ""))
    }
}

private extension CardReaderManualRowView {
    enum Constants {
        static let imageSize: CGFloat = 64
    }
}
