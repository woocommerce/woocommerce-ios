import SwiftUI

public struct PointOfSaleEntryPointView: View {
    @State private var showFullScreen = true

    @Environment(\.presentationMode) var presentationMode

    public init(showFullScreen: Bool = true) {
        self.showFullScreen = showFullScreen
    }

    public var body: some View {
        VStack {}
        // TODO: Remove the full screen modal
        // TODO: Move iPhone logic outside and do not render the entry point.
        .fullScreenCover(isPresented: $showFullScreen) {
            if UIDevice.current.userInterfaceIdiom == .pad {
                // TODO: Pass proper product models once we have data layer
                let products = ProductFactory.makeFakeProducts()
                let viewModel = PointOfSaleDashboardViewModel(products: products)

                PointOfSaleDashboardView(viewModel: viewModel)
            } else {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("Please use iPad")
                })
            }
        }
        .onAppear {
            showFullScreen = true
        }
    }
}
