import Aztec
import Gridicons
import WordPressEditor

/// Creates Aztec format bar & action handling coordinator for the format bar.
struct AztecFormatBarFactory {
    func formatBar(onAction: @escaping (_ formatBarItem: FormatBarItem, _ formatBar: FormatBar) -> Void) -> FormatBar {
        let toolbar = Aztec.FormatBar()

        toolbar.tintColor = StyleManager.wooCommerceBrandColor
        toolbar.highlightedTintColor = StyleManager.wooCommerceBrandColor.withAlphaComponent(0.5)
        toolbar.selectedTintColor = StyleManager.wooSecondary
        toolbar.disabledTintColor = StyleManager.buttonDisabledColor
        toolbar.dividerTintColor = StyleManager.cellSeparatorColor
        toolbar.overflowToggleIcon = Gridicon.iconOfType(.ellipsis)

        updateToolbar(toolbar)

        toolbar.barItemHandler = { barItem in
            onAction(barItem, toolbar)
        }

        return toolbar
    }

    func formatBarCommandCoordinator(optionsTablePresenter: OptionsTablePresenter) -> AztecFormatBarCommandCoordinator {
        return AztecFormatBarCommandCoordinator(commands: [
            AztecBoldFormatBarCommand(),
            AztecItalicFormatBarCommand(),
            AztecUnderlineFormatBarCommand(),
            AztecStrikethroughFormatBarCommand(),
            AztecBlockquoteFormatBarCommand(),
            AztecHorizontalRulerFormatBarCommand(),
            AztecInsertMoreFormatBarCommand(),
            AztecSourceCodeFormatBarCommand(),
            AztecHeaderFormatBarCommand(optionsTablePresenter: optionsTablePresenter),
            AztecUnorderedListFormatBarCommand(optionsTablePresenter: optionsTablePresenter)
        ])
    }
}

private extension AztecFormatBarFactory {
    private var scrollableItemsForToolbar: [FormatBarItem] {
        let headerButton = makeToolbarButton(identifier: .p)

        var alternativeIcons = [String: UIImage]()
        let headings = Constants.headers.suffix(from: 1) // Remove paragraph style
        for heading in headings {
            alternativeIcons[heading.formattingIdentifier.rawValue] = heading.iconImage
        }

        headerButton.alternativeIcons = alternativeIcons


        let listButton = makeToolbarButton(identifier: .unorderedlist)
        var listIcons = [String: UIImage]()
        for list in Constants.lists {
            listIcons[list.formattingIdentifier.rawValue] = list.iconImage
        }

        listButton.alternativeIcons = listIcons

        return [
            headerButton,
            listButton,
            makeToolbarButton(identifier: .blockquote),
            makeToolbarButton(identifier: .bold),
            makeToolbarButton(identifier: .italic),
            makeToolbarButton(identifier: .link)
        ]
    }

    private var overflowItemsForToolbar: [FormatBarItem] {
        return [
            makeToolbarButton(identifier: .underline),
            makeToolbarButton(identifier: .strikethrough),
            makeToolbarButton(identifier: .horizontalruler),
            makeToolbarButton(identifier: .more),
            makeToolbarButton(identifier: .sourcecode)
        ]
    }
}

private extension AztecFormatBarFactory {
    func updateToolbar(_ toolbar: Aztec.FormatBar) {
        toolbar.trailingItem = nil

        toolbar.setDefaultItems(scrollableItemsForToolbar,
                                overflowItems: overflowItemsForToolbar)
    }

    func makeToolbarButton(identifier: FormattingIdentifier) -> FormatBarItem {
        return makeToolbarButton(identifier: identifier.rawValue, viewProperties: identifier)
    }

    func makeToolbarButton(identifier: String, viewProperties: FormatBarItemViewProperties) -> FormatBarItem {
        let button = FormatBarItem(image: viewProperties.iconImage, identifier: identifier)
        button.accessibilityLabel = viewProperties.accessibilityLabel
        button.accessibilityHint = viewProperties.accessibilityHint
        return button
    }
}

// MARK: - Constants
//
private extension AztecFormatBarFactory {
    enum Constants {
        static let headers = [Header.HeaderType.none, .h1, .h2, .h3, .h4, .h5, .h6]
        static let lists = [TextList.Style.unordered, .ordered]
    }
}
