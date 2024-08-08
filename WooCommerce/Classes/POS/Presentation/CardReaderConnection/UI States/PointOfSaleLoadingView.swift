import SwiftUI

struct PoinfOfSaleErrorView: View {

    private var viewModel: any ItemListViewModelProtocol

    init(viewModel: any ItemListViewModelProtocol) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            POSErrorExclamationMark()
            Text("Error loading products")
            Text("Give it another go")
            Button(action: {
                Task {
                    await viewModel.reload()
                }
            }, label: {
                Text("Retry")
            })
        }
    }
}

struct PointOfSaleLoadingView: View {
    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            VStack(alignment: .center) {
                Spacer()
                ProgressView()
                    .progressViewStyle(POSProgressViewStyle())
                Spacer().frame(height: Layout.progressViewSpacing)
                Text(Localization.title)
                    .font(.posBody)
                Spacer().frame(height: Layout.textSpacing)
                Text(Localization.subtitle)
                    .font(.posTitle)
                    .bold()
                Spacer()
            }
            .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

private extension PointOfSaleLoadingView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.itemlistview.loading.title",
            value: "Starting up",
            comment: "Title of the Point of Sale entry point loading"
        )

        static let subtitle = NSLocalizedString(
            "pos.itemlistview.loading.subtitle",
            value: "Let’s serve some customers",
            comment: "Subtitle of the Point of Sale entry point loading"
        )
    }

    enum Layout {
        static let textSpacing: CGFloat = 16
        static let progressViewSpacing: CGFloat = 72
    }
}

#Preview {
    PointOfSaleLoadingView()
}
