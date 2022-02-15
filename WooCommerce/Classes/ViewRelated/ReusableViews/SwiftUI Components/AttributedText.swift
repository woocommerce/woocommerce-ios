import SwiftUI

/*
 This class was based on the [AttributedText](https://github.com/gonzalezreal/AttributedText) library
 by [Guille Gonzalez](https://github.com/gonzalezreal). It has then been adapted to fit our requirements.

 Copyright (c) 2020 Guille Gonzalez

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

/// Note: the font and foreground color of the text have to be set in `NSAttributedString`'s attributes.
/// `font` and `attributedTextForegroundColor` functions do not take effect.
/// The link color can be set with `attributedTextLinkColor`.
struct AttributedText: View {
    @StateObject private var textViewStore = TextViewStore()

    let attributedText: NSAttributedString

    init(_ attributedText: NSAttributedString) {
        self.attributedText = attributedText
    }

    var body: some View {
        GeometryReader { geometry in
            TextViewWrapper(
                attributedText: attributedText,
                maxLayoutWidth: geometry.maxWidth,
                textViewStore: textViewStore
            )
        }
        .frame(
            idealWidth: textViewStore.intrinsicContentSize?.width,
            idealHeight: textViewStore.intrinsicContentSize?.height
        )
        .fixedSize(horizontal: false, vertical: true)
    }
}


extension View {
    func customOpenURL(action: @escaping (URL) -> Void) -> some View {
        environment(\.customOpenURL, action)
    }

    func customOpenURL(binding: Binding<URL?>) -> some View {
        customOpenURL { url in
            binding.wrappedValue = url
        }
    }

    func attributedTextForegroundColor(_ color: Color?) -> some View {
        environment(\.foregroundColor, color)
    }

    func attributedTextLinkColor(_ color: Color?) -> some View {
        environment(\.linkColor, color)
    }
}

private extension GeometryProxy {
    var maxWidth: CGFloat {
        size.width - safeAreaInsets.leading - safeAreaInsets.trailing
    }
}

private final class TextViewStore: ObservableObject {
    @Published var intrinsicContentSize: CGSize?

    func didUpdateTextView(_ textView: TextViewWrapper.View) {
        intrinsicContentSize = textView.intrinsicContentSize
    }
}

private struct TextViewWrapper: UIViewRepresentable {
    final class View: UITextView {
        var maxLayoutWidth: CGFloat = 0 {
            didSet {
                guard maxLayoutWidth != oldValue else { return }
                invalidateIntrinsicContentSize()
            }
        }

        override var intrinsicContentSize: CGSize {
            guard maxLayoutWidth > 0 else {
                return super.intrinsicContentSize
            }

            return sizeThatFits(
                CGSize(width: maxLayoutWidth, height: .greatestFiniteMagnitude)
            )
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var openURL: ((URL) -> Void)?

        func textView(_: UITextView, shouldInteractWith URL: URL, in _: NSRange, interaction _: UITextItemInteraction) -> Bool {
            openURL?(URL)
            return false
        }
    }

    let attributedText: NSAttributedString
    let maxLayoutWidth: CGFloat
    let textViewStore: TextViewStore

    func makeUIView(context: Context) -> View {
        let uiView = View()

        uiView.backgroundColor = .clear
        uiView.textContainerInset = .zero
        uiView.isEditable = false
        uiView.isScrollEnabled = false
        uiView.textContainer.lineFragmentPadding = 0
        uiView.delegate = context.coordinator

        return uiView
    }

    func updateUIView(_ uiView: View, context: Context) {
        uiView.maxLayoutWidth = maxLayoutWidth
        uiView.font = context.environment.font?.uiFont ?? UIFont.preferredFont(forTextStyle: .body)
        uiView.textColor = context.environment.foregroundColor.map(UIColor.init)
        uiView.attributedText = attributedText

        var linkTextAttributes = uiView.linkTextAttributes ?? [:]
        linkTextAttributes[.underlineColor] = UIColor.clear
        if let linkColor = context.environment.linkColor.map(UIColor.init) {
            linkTextAttributes[.foregroundColor] = linkColor
        }
        uiView.linkTextAttributes = linkTextAttributes

        uiView.textContainer.maximumNumberOfLines = context.environment.lineLimit ?? 0

        context.coordinator.openURL = context.environment.customOpenURL ?? context.environment.openURL.callAsFunction(_:)

        textViewStore.didUpdateTextView(uiView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}

private extension Font {
    var uiFont: UIFont? {
        switch self {
        case .largeTitle:   return .preferredFont(forTextStyle: .largeTitle)
        case .title:        return .preferredFont(forTextStyle: .title1)
        case .title2:       return .preferredFont(forTextStyle: .title2)
        case .title3:       return .preferredFont(forTextStyle: .title3)
        case .headline:     return .preferredFont(forTextStyle: .headline)
        case .subheadline:  return .preferredFont(forTextStyle: .subheadline)
        case .body:         return .preferredFont(forTextStyle: .body)
        case .callout:      return .preferredFont(forTextStyle: .callout)
        case .footnote:     return .preferredFont(forTextStyle: .footnote)
        case .caption:      return .preferredFont(forTextStyle: .caption1)
        case .caption2:     return .preferredFont(forTextStyle: .caption2)

        default:            return nil
        }
    }
}

private struct CustomOpenURL: EnvironmentKey {
    static let defaultValue: ((URL) -> Void)? = nil
}

private struct ForegroundColorKey: EnvironmentKey {
    static var defaultValue: Color? = nil
}

private struct LinkColorKey: EnvironmentKey {
    static var defaultValue: Color? = nil
}

extension EnvironmentValues {
    var customOpenURL: ((URL) -> Void)? {
        get { self[CustomOpenURL.self] }
        set { self[CustomOpenURL.self] = newValue }
    }
}

private extension EnvironmentValues {
    var foregroundColor: Color? {
        get { self[ForegroundColorKey.self] }
        set { self[ForegroundColorKey.self] = newValue }
    }

    var linkColor: Color? {
        get { self[LinkColorKey.self] }
        set { self[LinkColorKey.self] = newValue }
    }
}


struct AttributedText_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Link("Default Link", destination: URL(string: "https://woocommerce.com/")!)
            Text("Default Text")
            AttributedText("AttributedText <a href=\"https://woocommerce.com/\">with a link</a>".htmlToAttributedString)
            AttributedText("Custom AttributedText <a href=\"https://woocommerce.com/\">with a link</a>".htmlToAttributedString)
                .font(.footnote)
                .attributedTextForegroundColor(.gray)
                .attributedTextLinkColor(.pink)
        }
    }
}
