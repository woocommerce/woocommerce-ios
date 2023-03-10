import SwiftUI
import QuickLook

struct AugmentedRealityMenu: View {
    private let cameraViewModel = CameraViewModel()
    @State var showCameraView = false
    @State var showingCreateUSDz = false
    @State var showDocumentPicker = false
    @State var showingPreview = false


    @State var selectedPreviewFileURL: URL? = nil
#if targetEnvironment(macCatalyst)
    @State var disableImageCapture = true
    @State var disableModelGeneration = false
#else
    @State var disableImageCapture = false
    @State var disableModelGeneration = true
#endif

    var body: some View {
        VStack {
            VStack {
                HStack {
                    Text("1")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .padding(.all, 16)
                        .background(Color(UIColor.wooCommercePurple(.shade40)))
                        .clipShape(Circle())
                    Spacer()
                    HubMenuElement(image: .init(systemName: "camera")!,
                                   imageColor: .systemGreen,
                                   text: "Capture images",
                                   badge: .number(number: 0),
                                   isDisabled: $disableImageCapture) {
                        showCameraView = true
                    }
                                   .background(Color(.listForeground(modal: false)))
                                   .cornerRadius(Constants.cornerRadius)
                                   .padding([.bottom], Constants.padding)
                    Spacer()
                    Image(systemName: "iphone")
                        .font(.largeTitle)
                        .padding(16)
                }
            }
            .padding(16)

            VStack {
                HStack {
                    Text("2")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .padding(.all, 16)
                        .background(Color(UIColor.wooCommercePurple(.shade40)))
                        .clipShape(Circle())
                    Spacer()
                    HubMenuElement(image: .init(systemName: "move.3d")!,
                                   imageColor: .systemOrange,
                                   text: "Generate model",
                                   badge: .number(number: 0),
                                   isDisabled: $disableModelGeneration) {
                        showingCreateUSDz = true
                    }
                                   .background(Color(.listForeground(modal: false)))
                                   .cornerRadius(Constants.cornerRadius)
                                   .padding([.bottom], Constants.padding)
                    Spacer()
                    Image(systemName: "laptopcomputer")
                        .font(.largeTitle)
                        .padding(4)
                }
            }
            .padding(16)

            VStack {
                HStack {
                    Text("3")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .padding(.all, 16)
                        .background(Color(UIColor.wooCommercePurple(.shade40)))
                        .clipShape(Circle())
                    Spacer()
                    HubMenuElement(image: .init(systemName: "iphone.badge.play")!,
                                   imageColor: .wooBlue,
                                   text: "Preview model",
                                   badge: .number(number: 0),
                                   isDisabled: $disableImageCapture) {
                        selectedPreviewFileURL = nil
                        showDocumentPicker = true
                    }
                                   .background(Color(.listForeground(modal: false)))
                                   .cornerRadius(Constants.cornerRadius)
                                   .padding([.bottom], Constants.padding)
                    Spacer()
                    Image(systemName: "iphone")
                        .font(.largeTitle)
                        .padding(16)
                }
            }
            .padding(16)

            NavigationLink(destination:
                            AugmentedRealityCreateUSDZ()
                            .navigationTitle("Create USDZ files"),
                           isActive: $showingCreateUSDz) {
                EmptyView()
            }.hidden()
        }
        .padding(Constants.padding)
        .background(Color(.listBackground))
        .sheet(isPresented: $showCameraView, content: {
            ContentView(model: cameraViewModel)
        })
        .fileImporter(isPresented: $showDocumentPicker,
                      allowedContentTypes: [.usdz],
                      allowsMultipleSelection: false,
                      onCompletion: { result in
            guard case let .success(urls) = result,
                let url = urls.first else {
                return
            }
            selectedPreviewFileURL = url
            showingPreview = true
            showDocumentPicker = false
        })
//        .sheet(isPresented: $showingPreview) {
//            if let url = selectedPreviewFileURL {
//                PreviewController(url: url)
//            } else {
//                EmptyView()
//            }
//        }
        .quickLookPreview($selectedPreviewFileURL)
    }
}

struct Previews_AugmentedRealityMenu_Previews: PreviewProvider {
    static var previews: some View {
        AugmentedRealityMenu()
    }
}

private enum Constants {
    static let cornerRadius: CGFloat = 10
    static let itemSpacing: CGFloat = 12
    static let itemSize: CGFloat = 140
    static let padding: CGFloat = 16
    static let topBarSpacing: CGFloat = 2
    static let avatarSize: CGFloat = 40
    static let trackingOptionKey = "option"
    static let trackingBadgeVisibleKey = "badge_visible"

    static let paddingBetweenElements: CGFloat = 8
    static let minimumBottomPadding: CGFloat = 2
}
