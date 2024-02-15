import SwiftUI

/// Renders a button with the pencil system name image
///
struct PencilEditButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "pencil")
        }
    }
}
