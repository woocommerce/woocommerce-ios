import SwiftUI

/// Shows an action sheet to pick a media source from the content view.
struct MediaSourceActionSheet: ViewModifier {
    private let showsActionSheet: Binding<Bool>
    private let selectMedia: (MediaPickingSource) -> Void

    init(showsActionSheet: Binding<Bool>,
         selectMedia: @escaping (MediaPickingSource) -> Void) {
        self.showsActionSheet = showsActionSheet
        self.selectMedia = selectMedia
    }

    func body(content: Content) -> some View {
        content
            .confirmationDialog(Text(Localization.title), isPresented: showsActionSheet, actions: {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button(Localization.camera) {
                        selectMedia(.camera)
                    }
                }

                Button(Localization.photoLibrary) {
                    selectMedia(.photoLibrary)
                }

                Button(Localization.siteMediaLibrary) {
                    selectMedia(.siteMediaLibrary)
                }
            })
    }
}

private extension MediaSourceActionSheet {
    enum Localization {
        static let title = NSLocalizedString(
            "Select Media Source",
            comment: "Title of the media picker action sheet to select a source."
        )
        static let camera = NSLocalizedString(
            "Take a photo",
            comment: "Menu option for taking an image or video with the device's camera."
        )
        static let photoLibrary = NSLocalizedString(
            "Choose from device",
            comment: "Menu option for selecting media from the device's photo library."
        )
        static let siteMediaLibrary = NSLocalizedString(
            "WordPress Media Library",
            comment: "Menu option for selecting media from the device's photo library."
        )
    }
}

extension View {
    /// Shows an action sheet to pick a media source from the content view.
    /// - Parameters:
    ///   - showsActionSheet: Whether the action sheet is shown.
    ///   - selectMedia: Invoked when the user selects a media source.
    /// - Returns: The view of the action sheet.
    func mediaSourceActionSheet(showsActionSheet: Binding<Bool>,
                                selectMedia: @escaping (MediaPickingSource) -> Void) -> some View {
        self.modifier(MediaSourceActionSheet(showsActionSheet: showsActionSheet,
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
