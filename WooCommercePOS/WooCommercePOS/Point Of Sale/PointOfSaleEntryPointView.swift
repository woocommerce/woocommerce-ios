import SwiftUI

public struct PointOfSaleEntryPointView: View {
    @State private var showFullScreen = true

    @Environment(\.presentationMode) var presentationMode

    public init(showFullScreen: Bool = true) {
        self.showFullScreen = showFullScreen
    }

    public var body: some View {
        VStack {}
        .fullScreenCover(isPresented: $showFullScreen) {
            if UIDevice.current.userInterfaceIdiom == .pad {
                PointOfSaleDashboard()
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
