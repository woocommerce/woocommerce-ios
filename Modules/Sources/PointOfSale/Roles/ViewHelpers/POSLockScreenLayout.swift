import Foundation

struct POSLockScreenLayout {
    let keySize: CGFloat
    let verticalPadding: CGFloat
    let sectionSpacing: CGFloat
    let showsIllustration: Bool

    /// Compact height keeps one centered column with the title on top and no illustration, so the keypad stays as large as possible.
    init(viewportSize: CGSize, preferredKeySize: CGFloat, titleHeight: CGFloat, illustrationHeight: CGFloat,
         statusHeight: CGFloat, isCompactHeight: Bool, metrics: POSMetrics) {
        let keypadWidth = viewportSize.width - metrics.padding.xxLarge * 2
        let normalPadding = isCompactHeight ? metrics.padding.small : metrics.padding.xxLarge
        let reducedPadding = isCompactHeight ? metrics.padding.small : metrics.padding.medium
        let sectionSpacing = isCompactHeight ? metrics.spacing.medium : metrics.spacing.xLarge
        let illustratedHeaderHeight = titleHeight + illustrationHeight + metrics.spacing.xLarge

        func contentHeight(keySize: CGFloat, headerHeight: CGFloat) -> CGFloat {
            let keypad = POSPINEntryViewHelper.lockScreenKeypadSize(keySize: keySize, metrics: metrics)
            return headerHeight + sectionSpacing + statusHeight + metrics.spacing.xLarge + keypad.height
        }

        let preferredHeaderHeight = isCompactHeight ? titleHeight : illustratedHeaderHeight
        let preferredHeight = contentHeight(keySize: preferredKeySize, headerHeight: preferredHeaderHeight)
        verticalPadding = preferredHeight + normalPadding * 2 <= viewportSize.height ? normalPadding : reducedPadding
        let availableHeight = viewportSize.height - verticalPadding * 2

        func fittedKeySize(headerHeight: CGFloat) -> CGFloat {
            POSPINEntryViewHelper.lockScreenKeySize(
                fitting: CGSize(width: keypadWidth,
                                height: availableHeight - headerHeight - sectionSpacing - statusHeight - metrics.spacing.xLarge),
                preferred: preferredKeySize, metrics: metrics
            )
        }

        let illustratedKeySize = fittedKeySize(headerHeight: illustratedHeaderHeight)
        showsIllustration = !isCompactHeight
            && contentHeight(keySize: illustratedKeySize, headerHeight: illustratedHeaderHeight) <= availableHeight
        keySize = showsIllustration ? illustratedKeySize : fittedKeySize(headerHeight: titleHeight)
        self.sectionSpacing = sectionSpacing
    }
}
