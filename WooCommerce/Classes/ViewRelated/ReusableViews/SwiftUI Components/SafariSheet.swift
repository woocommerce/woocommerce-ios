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
}
