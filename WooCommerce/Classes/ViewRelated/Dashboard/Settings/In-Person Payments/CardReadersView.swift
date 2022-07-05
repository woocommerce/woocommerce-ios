import SwiftUI
import WebKit
import SafariServices

struct SafariView: UIViewControllerRepresentable {

    var choice: Manual
    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController,
                                context: UIViewControllerRepresentableContext<SafariView>) {

    }
}
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
        ScrollView {
            ForEach(manuals, id: \.name) { manual in
                NavigationLink(destination: SafariView(choice: manual, url: URL(string: manual.urlString)!)) {
                    Image(uiImage: manual.image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: Constants.iconSize * scale, height: Constants.iconSize * scale, alignment: .center)
                    Text(manual.name)
                }
            }
        }
        .navigationBarTitle(Localization.navigationTitle, displayMode: .inline)
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
    }
}
