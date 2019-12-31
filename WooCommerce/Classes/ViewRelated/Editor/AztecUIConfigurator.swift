import Aztec
import UIKit
import WordPressEditor

/// Configures the Aztec UI components, like the styling and Auto Layout constraints.
struct AztecUIConfigurator {
    func configureEditorView(_ editorView: EditorView,
                             textViewDelegate: UITextViewDelegate,
                             textViewAttachmentDelegate: TextViewAttachmentDelegate) {
        editorView.clipsToBounds = false
        configureHTMLTextView(editorView.htmlTextView, textViewDelegate: textViewDelegate)
        configureRichTextView(editorView.richTextView,
                              textViewDelegate: textViewDelegate,
                              textViewAttachmentDelegate: textViewAttachmentDelegate)
    }

    func configureConstraints(editorView: EditorView, editorContainerView: UIView, placeholderView: UIView) {
        let richTextView = editorView.richTextView
        let htmlTextView = editorView.htmlTextView

        NSLayoutConstraint.activate([
            richTextView.leadingAnchor.constraint(equalTo: editorContainerView.readableContentGuide.leadingAnchor),
            richTextView.trailingAnchor.constraint(equalTo: editorContainerView.readableContentGuide.trailingAnchor),
            richTextView.topAnchor.constraint(equalTo: editorContainerView.topAnchor),
            richTextView.bottomAnchor.constraint(equalTo: editorContainerView.bottomAnchor)
            ])

        NSLayoutConstraint.activate([
            htmlTextView.leftAnchor.constraint(equalTo: richTextView.leftAnchor),
            htmlTextView.rightAnchor.constraint(equalTo: richTextView.rightAnchor),
            htmlTextView.topAnchor.constraint(equalTo: richTextView.topAnchor),
            htmlTextView.bottomAnchor.constraint(equalTo: richTextView.bottomAnchor)
            ])

        let insets = richTextView.textContainerInset

        NSLayoutConstraint.activate([
            placeholderView.leftAnchor.constraint(equalTo: richTextView.leftAnchor, constant: insets.left + richTextView.textContainer.lineFragmentPadding),
            placeholderView.rightAnchor.constraint(equalTo: richTextView.rightAnchor, constant: -insets.right - richTextView.textContainer.lineFragmentPadding),
            placeholderView.topAnchor.constraint(equalTo: richTextView.topAnchor, constant: insets.top),
            placeholderView.bottomAnchor.constraint(lessThanOrEqualTo: richTextView.bottomAnchor, constant: insets.bottom)
            ])
    }
}

private extension AztecUIConfigurator {
    func configureHTMLTextView(_ textView: UITextView, textViewDelegate: UITextViewDelegate) {
        let accessibilityLabel = NSLocalizedString("HTML Content", comment: "Post HTML content")
        configureDefaultProperties(for: textView, accessibilityLabel: accessibilityLabel)

        textView.isHidden = true
        textView.delegate = textViewDelegate
        textView.accessibilityIdentifier = "HTMLContentView"
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none

        // We need this false to be able to set negative `scrollInset` values.
        textView.clipsToBounds = false

        textView.adjustsFontForContentSizeCategory = true
        textView.smartDashesType = .no
        textView.smartQuotesType = .no
    }

    func configureRichTextView(_ textView: TextView,
                               textViewDelegate: UITextViewDelegate,
                               textViewAttachmentDelegate: TextViewAttachmentDelegate) {
        textView.load(WordPressPlugin())

        let accessibilityLabel = NSLocalizedString("Rich Content", comment: "Post Rich content")
        configureDefaultProperties(for: textView, accessibilityLabel: accessibilityLabel)

        let linkAttributes: [NSAttributedString.Key: Any] = [.underlineStyle: NSUnderlineStyle.single.rawValue,
                                                             .foregroundColor: UIColor.textLink]

        textView.delegate = textViewDelegate
        textView.textAttachmentDelegate = textViewAttachmentDelegate
        textView.backgroundColor = .basicBackground
        textView.textColor = .systemColor(.label)
        textView.linkTextAttributes = linkAttributes

        // We need this false to be able to set negative `scrollInset` values.
        textView.clipsToBounds = false

        textView.smartDashesType = .no
        textView.smartQuotesType = .no
    }

    func configureDefaultProperties(for textView: UITextView, accessibilityLabel: String) {
        textView.accessibilityLabel = accessibilityLabel
        textView.keyboardDismissMode = .interactive
        textView.textColor = UIColor.darkText
        textView.translatesAutoresizingMaskIntoConstraints = false
    }
}
