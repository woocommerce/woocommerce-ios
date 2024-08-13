import SwiftUI

/// Shows an action sheet to pick a media source from the content view.
struct MediaSourceActionSheet: ViewModifier {
    private let showsActionSheet: Binding<Bool>
    private let sourceOptions: [MediaPickingSource]
    private let selectMedia: (MediaPickingSource) -> Void

    init(showsActionSheet: Binding<Bool>,
         sourceOptions: [MediaPickingSource],
         selectMedia: @escaping (MediaPickingSource) -> Void) {
        self.showsActionSheet = showsActionSheet
        self.sourceOptions = sourceOptions
        self.selectMedia = selectMedia
    }

    func body(content: Content) -> some View {
        content
            .confirmationDialog(Text(Localization.title), isPresented: showsActionSheet, actions: {
                ForEach(sourceOptions) { source in
                    switch source {
                    case .camera:
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            Button(Localization.camera) {
                                selectMedia(.camera)
                            }
                        }
                    case .photoLibrary:
                        Button(Localization.photoLibrary) {
                            selectMedia(.photoLibrary)
                        }
                    case .siteMediaLibrary:
                        Button(Localization.siteMediaLibrary) {
                            selectMedia(.siteMediaLibrary)
                        }
                    case .productMedia(let productID):
                        Button(Localization.productMedia) {
                            selectMedia(.productMedia(productID: productID))
                        }
                    }
                }
            })
    }
}

private extension MediaSourceActionSheet {
    enum Localization {
        static let title = NSLocalizedString(
            "mediaSourceActionSheet.title",
            value: "Select Media Source",
            comment: "Title of the media picker action sheet to select a source."
        )
        static let camera = NSLocalizedString(
            "mediaSourceActionSheet.camera",
            value: "Take a photo",
            comment: "Menu option for taking an image or video with the device's camera."
        )
        static let photoLibrary = NSLocalizedString(
            "mediaSourceActionSheet.photoLibrary",
            value: "Choose from device",
            comment: "Menu option for selecting media from the device's photo library."
        )
        static let productMedia = NSLocalizedString(
            "mediaSourceActionSheet.productMedia",
            value: "Choose an existing product photo",
            comment: "Menu option for selecting media attached to the given product ID."
        )
        static let siteMediaLibrary = NSLocalizedString(
            "mediaSourceActionSheet.siteMediaLibrary",
            value: "WordPress Media Library",
            comment: "Menu option for selecting media from the device's photo library."
        )
    }
}

extension View {
    /// Shows an action sheet to pick a media source from the content view.
    /// - Parameters:
    ///   - showsActionSheet: Whether the action sheet is shown.
    ///   - sourceOptions: Sources to pick Media from.
    ///   - selectMedia: Invoked when the user selects a media source.
    /// - Returns: The view of the action sheet.
    func mediaSourceActionSheet(showsActionSheet: Binding<Bool>,
                                sourceOptions: [MediaPickingSource] = [.camera, .photoLibrary, .siteMediaLibrary],
                                selectMedia: @escaping (MediaPickingSource) -> Void) -> some View {
        self.modifier(MediaSourceActionSheet(showsActionSheet: showsActionSheet,
                                             sourceOptions: sourceOptions,
                                             selectMedia: selectMedia))
    }
}

struct MediaPickerSourceActionSheet_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            Text("Content")
                .mediaSourceActionSheet(showsActionSheet: .constant(true),
                                        selectMedia: { _ in })
        }
    }
}
