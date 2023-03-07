import Foundation
import SwiftUI
import SafariServices
import UIKit

struct SafariSheetView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // nothing to do here
    }
}

extension View {
    /// Presents a sheet with a browser when a binding to a Boolean value that you provide is true.
    /// Does nothing if the input URL is nil.
    ///
    @ViewBuilder
    func safariSheet(isPresented: Binding<Bool>, url: URL?, onDismiss: (() -> Void)? = nil) -> some View {
        if let url = url {
            sheet(isPresented: isPresented, onDismiss: onDismiss) {
                SafariSheetView(url: url)
                    .ignoresSafeArea()
            }
        }
    }

    /// Presents a sheet with a browser when a binding to an optional URL that you provide has a value
    ///
    /// When the sheet is dismissed, the binding's value will be set to nil.
    ///
    func safariSheet(url: Binding<URL?>, onDismiss: (() -> Void)? = nil) -> some View {
        sheet(isPresented: url.notNil(), onDismiss: onDismiss) {
            if let url = url.wrappedValue {
                SafariSheetView(url: url)
                    .ignoresSafeArea()
            }
        }
    }
}

private extension Binding {
    /// Returns a new binding that has a Boolean value indicating whether the underlying optional has a value
    ///
    /// Note that setting a true value will do nothing since we can't infer a value if there isn't a previous one,
    /// but setting a false value will set the underlying value to nil.
    ///
    /// Because of that, this is a private helper to make the sheet presentation logic more concise and readable,
    /// but it wasn't a good candidate for a more general public operator.
    func notNil<V>() -> Binding<Bool> where Value == V? {
        Binding<Bool>(
            get: { self.wrappedValue != nil },
            set: { self.wrappedValue = $0 ? self.wrappedValue : nil }
        )
    }
}
