import SwiftUI

struct PointOfSaleEntryPoint: View {
    @State private var showFullScreen = true

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {}
        .fullScreenCover(isPresented: $showFullScreen) {
            if UIDevice.isPad() {
                // Not injecting any data into the View at this point
                // since we want to keep this separated
                PointOfSaleDashboardView()
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
