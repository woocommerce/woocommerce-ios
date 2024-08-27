import SwiftUI

struct ViewPackagePhoto: View {
    let image: UIImage
    @Binding var isShowing: Bool

    var body: some View {
        NavigationStack {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(Localization.done) {
                            isShowing = false
                        }
                    }
                }
                .navigationTitle(Localization.packagePhoto)
                .wooNavigationBarStyle()
                .navigationBarTitleDisplayMode(.inline)
        }
    }

    enum Localization {
        static let packagePhoto = NSLocalizedString(
            "viewPackagePhoto.packagePhoto",
            value: "Package photo",
            comment: "Title of the view package photo screen."
        )
        static let done = NSLocalizedString(
            "viewPackagePhoto.done",
            value: "Done",
            comment: "Title of the button to dismiss the view package photo screen."
        )
    }
}
