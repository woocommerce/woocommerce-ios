import Foundation

struct POSLockScreenLayout {
    let keySize: CGFloat
    let verticalPadding: CGFloat
    let showsIllustration: Bool

    init(viewportSize: CGSize, preferredKeySize: CGFloat, titleHeight: CGFloat, illustrationHeight: CGFloat,
         statusHeight: CGFloat, isHorizontal: Bool, metrics: POSMetrics) {
        let contentWidth = viewportSize.width - metrics.padding.xxLarge * 2
        let keypadWidth = isHorizontal ? (contentWidth - metrics.spacing.xxLarge) / 2 : contentWidth
        let normalPadding = isHorizontal ? metrics.padding.small : metrics.padding.xxLarge
        let reducedPadding = isHorizontal ? metrics.padding.small : metrics.padding.medium
        let illustratedHeaderHeight = titleHeight + illustrationHeight + metrics.spacing.xLarge

        func contentHeight(keySize: CGFloat, headerHeight: CGFloat) -> CGFloat {
            let keypad = POSPINEntryViewHelper.lockScreenKeypadSize(keySize: keySize, metrics: metrics)
            let entryHeight = statusHeight + metrics.spacing.xLarge + keypad.height
            return isHorizontal ? max(headerHeight, entryHeight) : headerHeight + metrics.spacing.xLarge + entryHeight
        }

        let preferredHeight = contentHeight(keySize: preferredKeySize, headerHeight: illustratedHeaderHeight)
        verticalPadding = preferredHeight + normalPadding * 2 <= viewportSize.height ? normalPadding : reducedPadding
        let availableHeight = viewportSize.height - verticalPadding * 2

        func fittedKeySize(headerHeight: CGFloat) -> CGFloat {
            let headerSpace = isHorizontal ? 0 : headerHeight + metrics.spacing.xLarge
            return POSPINEntryViewHelper.lockScreenKeySize(
                fitting: CGSize(width: keypadWidth, height: availableHeight - headerSpace - statusHeight - metrics.spacing.xLarge),
                preferred: preferredKeySize, metrics: metrics
            )
        }

        let illustratedKeySize = fittedKeySize(headerHeight: illustratedHeaderHeight)
        showsIllustration = contentHeight(keySize: illustratedKeySize, headerHeight: illustratedHeaderHeight) <= availableHeight
        keySize = showsIllustration ? illustratedKeySize : fittedKeySize(headerHeight: titleHeight)
    }
}
