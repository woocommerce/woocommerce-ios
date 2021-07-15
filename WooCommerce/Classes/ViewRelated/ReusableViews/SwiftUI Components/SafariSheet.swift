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
    func safariSheet(isPresented: Binding<Bool>, url: URL) -> some View {
        sheet(isPresented: isPresented) {
            SafariSheetView(url: url)
        }
    }

    func safariSheet(url: Binding<URL?>) -> some View {
        sheet(isPresented: url.notNil()) {
            if let url = url.wrappedValue {
                SafariSheetView(url: url)
            }
        }
    }
}

private extension Binding {
    func notNil<V>() -> Binding<Bool> where Value == V? {
        Binding<Bool>(
            get: { self.wrappedValue != nil },
            set: { self.wrappedValue = $0 ? self.wrappedValue : nil }
        )
    }
}
