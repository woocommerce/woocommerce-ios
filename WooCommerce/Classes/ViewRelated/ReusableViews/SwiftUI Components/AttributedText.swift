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

private extension GeometryProxy {
    var maxWidth: CGFloat {
        size.width - safeAreaInsets.leading - safeAreaInsets.trailing
    }
}

final class TextViewStore: ObservableObject {
    @Published var intrinsicContentSize: CGSize?

    func didUpdateTextView(_ textView: TextViewWrapper.View) {
        intrinsicContentSize = textView.intrinsicContentSize
    }
}

struct TextViewWrapper: UIViewRepresentable {
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
        uiView.attributedText = attributedText
        uiView.maxLayoutWidth = maxLayoutWidth

        uiView.textContainer.maximumNumberOfLines = context.environment.lineLimit ?? 0

        context.coordinator.openURL = context.environment.customOpenURL ?? context.environment.openURL.callAsFunction(_:)

        textViewStore.didUpdateTextView(uiView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}

struct CustomOpenURL: EnvironmentKey {
    static let defaultValue: ((URL) -> Void)? = nil
}

public extension EnvironmentValues {
    var customOpenURL: ((URL) -> Void)? {
        get { self[CustomOpenURL.self] }
        set { self[CustomOpenURL.self] = newValue }
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
}
