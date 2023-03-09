import SwiftUI

struct AugmentedRealityMenu: View {
    private let cameraViewModel = CameraViewModel()
    @State var showCameraView = false
    var body: some View {
        List {
            Button {
                showCameraView = true
            } label: {
                Text("Capture images")
            }


            if #available(macCatalyst 16.0, *) {
                NavigationLink(destination: AugmentedRealityCreateUSDZ()) {
                    Text("Create USDZ files")
                }
            }
        }
        .sheet(isPresented: $showCameraView, content: {
            ContentView(model: cameraViewModel)
        })
    }
}

struct Previews_AugmentedRealityMenu_Previews: PreviewProvider {
    static var previews: some View {
        AugmentedRealityMenu()
    }
}
