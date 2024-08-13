import Foundation
import SwiftUI
import WebKit

struct SVGAnimationView: View {
    let svgName: String

    var body: some View {
        SwiftUIWebView(svgFileName: svgName)
            .edgesIgnoringSafeArea(.all)
    }
}

private struct SwiftUIWebView: UIViewRepresentable {
    let svgFileName: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if let svgPath = Bundle.main.path(forResource: svgFileName, ofType: "svg") {
            do {
                let svgString = try String(contentsOfFile: svgPath, encoding: .utf8)
                let wrappedSVGString = wrapSVGContent(svgString: svgString)
                webView.loadHTMLString(wrappedSVGString, baseURL: nil)
            } catch {
                print("Error loading SVG from file: \(error)")
            }
        }
    }

      private func wrapSVGContent(svgString: String) -> String {
          return """
          <!DOCTYPE html>
          <html lang="en">
          <head>
              <meta charset="UTF-8">
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
              <style>
                  body, html {
                      margin: 0;
                      padding: 0;
                      width: 100%;
                      height: 100%;
                      overflow: hidden;
                      background-color: transparent; /* Ensure background is transparent */
                  }
                  svg {
                      width: 100%;
                      height: 100%;
                  }
              </style>
          </head>
          <body>
              \(svgString)
          </body>
          </html>
          """
      }
}
