import SwiftUI

/// A view to be displayed on Card Reader Manuals screen
///
struct CardReaderManualsView: View {

    let viewModel = CardReaderManualsViewModel()
    var manuals: [Manual] {
        viewModel.manuals
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(manuals, id: \.name) { manual in
                    Divider()
                    CardReaderManualRowView(manual: manual)
                }
                Divider()
            }
        }
        .navigationBarTitle(Localization.navigationTitle, displayMode: .inline)
    }
}

struct CardReadersView_Previews: PreviewProvider {
    static var previews: some View {
        CardReaderManualsView()
    }
}

private extension CardReaderManualsView {
    enum Localization {
        static let navigationTitle = NSLocalizedString( "Card reader manuals",
                                                        comment: "Navigation title at the top of the Card reader manuals screen")
    }
}

private extension CardReaderManualsView {
    enum Constants {
        static let iconSize: CGFloat = 16
        static let imageSize: CGFloat = 64
        static let imageSizeMultiplier: CGFloat = 0.2
        static let textSizeMultiplier: CGFloat = 0.6
    }
}
