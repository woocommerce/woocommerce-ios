// Generated using Sourcery 2.3.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// Enumerates the StoreDesignSystem tokens for the in-app Design System demo.
// After changing any token, regenerate with `rake generate` (see AGENTS.md).
#if DEBUG || ALPHA
// swiftlint:disable line_length
import SwiftUI
import StoreDesignSystem

// MARK: - Catalog entry types

struct StoreColorToken: Identifiable {
    let name: String
    let color: Color
    var id: String { name }
}

struct StoreIconToken: Identifiable {
    let variants: [StoreIconImage]
    var name: String { variants.first?.name ?? "" }
    var id: String { name }
}

struct StoreTextStyleToken: Identifiable {
    let name: String
    let style: StoreTextStyle
    var id: String { name }
}

// MARK: - Colors

extension Color {
    static let storeColorCatalog: [StoreColorToken] = [
        StoreColorToken(name: "storeSectionBackground", color: .storeSectionBackground),
        StoreColorToken(name: "storeOnSectionBackground", color: .storeOnSectionBackground),
        StoreColorToken(name: "storeSectionBackgroundVariant", color: .storeSectionBackgroundVariant),
        StoreColorToken(name: "storeOnSectionBackgroundVariant", color: .storeOnSectionBackgroundVariant),
        StoreColorToken(name: "storePrimary", color: .storePrimary),
        StoreColorToken(name: "storeOnPrimary", color: .storeOnPrimary),
        StoreColorToken(name: "storeSecondary", color: .storeSecondary),
        StoreColorToken(name: "storeOnSecondary", color: .storeOnSecondary),
        StoreColorToken(name: "storePrimaryContainer", color: .storePrimaryContainer),
        StoreColorToken(name: "storeOnPrimaryContainer", color: .storeOnPrimaryContainer),
        StoreColorToken(name: "storeSecondaryContainer", color: .storeSecondaryContainer),
        StoreColorToken(name: "storeOnSecondaryContainer", color: .storeOnSecondaryContainer),
        StoreColorToken(name: "storeErrorContainer", color: .storeErrorContainer),
        StoreColorToken(name: "storeOnErrorContainer", color: .storeOnErrorContainer),
        StoreColorToken(name: "storeWarningContainer", color: .storeWarningContainer),
        StoreColorToken(name: "storeOnWarningContainer", color: .storeOnWarningContainer),
        StoreColorToken(name: "storeCautionContainer", color: .storeCautionContainer),
        StoreColorToken(name: "storeOnCautionContainer", color: .storeOnCautionContainer),
        StoreColorToken(name: "storeSuccessContainer", color: .storeSuccessContainer),
        StoreColorToken(name: "storeOnSuccessContainer", color: .storeOnSuccessContainer),
        StoreColorToken(name: "storeInfoContainer", color: .storeInfoContainer),
        StoreColorToken(name: "storeOnInfoContainer", color: .storeOnInfoContainer),
        StoreColorToken(name: "storeNeutralContainer", color: .storeNeutralContainer),
        StoreColorToken(name: "storeOnNeutralContainer", color: .storeOnNeutralContainer),
        StoreColorToken(name: "storeAlertRed", color: .storeAlertRed),
        StoreColorToken(name: "storeOnAlertRed", color: .storeOnAlertRed),
        StoreColorToken(name: "storeAlertOrange", color: .storeAlertOrange),
        StoreColorToken(name: "storeOnAlertOrange", color: .storeOnAlertOrange),
        StoreColorToken(name: "storeAlertGreen", color: .storeAlertGreen),
        StoreColorToken(name: "storeOnAlertGreen", color: .storeOnAlertGreen),
        StoreColorToken(name: "storeAlertBlue", color: .storeAlertBlue),
        StoreColorToken(name: "storeOnAlertBlue", color: .storeOnAlertBlue),
        StoreColorToken(name: "storeOutline", color: .storeOutline),
        StoreColorToken(name: "storeOutlineVariant", color: .storeOutlineVariant),
        StoreColorToken(name: "storeSurfaceDim", color: .storeSurfaceDim),
        StoreColorToken(name: "storeSurfaceBright", color: .storeSurfaceBright),
        StoreColorToken(name: "storeSurface", color: .storeSurface),
        StoreColorToken(name: "storeSurfaceContainerHighest", color: .storeSurfaceContainerHighest),
        StoreColorToken(name: "storeOnSurface", color: .storeOnSurface),
        StoreColorToken(name: "storeOnSurfaceVariant", color: .storeOnSurfaceVariant),
        StoreColorToken(name: "storeOnSurfaceVariantLowest", color: .storeOnSurfaceVariantLowest),
        StoreColorToken(name: "storeInverseSurface", color: .storeInverseSurface),
        StoreColorToken(name: "storeOnInverseSurface", color: .storeOnInverseSurface),
        StoreColorToken(name: "storeOverlayOpacity20", color: .storeOverlayOpacity20),
        StoreColorToken(name: "storeOverlayOpacity50", color: .storeOverlayOpacity50),
        StoreColorToken(name: "storeStateLayerOnSurface08", color: .storeStateLayerOnSurface08),
        StoreColorToken(name: "storeStateLayerOnSurface10", color: .storeStateLayerOnSurface10),
        StoreColorToken(name: "storeStateLayerOnSurface24", color: .storeStateLayerOnSurface24),
        StoreColorToken(name: "storePaletteWooBlue20", color: .storePaletteWooBlue20),
        StoreColorToken(name: "storePaletteWooBlue40", color: .storePaletteWooBlue40),
        StoreColorToken(name: "storePaletteWooBlue60", color: .storePaletteWooBlue60),
        StoreColorToken(name: "storePaletteWooGreen20", color: .storePaletteWooGreen20),
        StoreColorToken(name: "storePaletteWooGreen40", color: .storePaletteWooGreen40),
        StoreColorToken(name: "storePaletteWooGreen60", color: .storePaletteWooGreen60),
        StoreColorToken(name: "storePaletteWooOrange20", color: .storePaletteWooOrange20),
        StoreColorToken(name: "storePaletteWooOrange40", color: .storePaletteWooOrange40),
        StoreColorToken(name: "storePaletteWooOrange60", color: .storePaletteWooOrange60),
        StoreColorToken(name: "storePaletteWooPink20", color: .storePaletteWooPink20),
        StoreColorToken(name: "storePaletteWooPink40", color: .storePaletteWooPink40),
        StoreColorToken(name: "storePaletteWooPink60", color: .storePaletteWooPink60),
        StoreColorToken(name: "storePaletteWooPurple0", color: .storePaletteWooPurple0),
        StoreColorToken(name: "storePaletteWooPurple5", color: .storePaletteWooPurple5),
        StoreColorToken(name: "storePaletteWooPurple10", color: .storePaletteWooPurple10),
        StoreColorToken(name: "storePaletteWooPurple20", color: .storePaletteWooPurple20),
        StoreColorToken(name: "storePaletteWooPurple30", color: .storePaletteWooPurple30),
        StoreColorToken(name: "storePaletteWooPurple40", color: .storePaletteWooPurple40),
        StoreColorToken(name: "storePaletteWooPurple50", color: .storePaletteWooPurple50),
        StoreColorToken(name: "storePaletteWooPurple60", color: .storePaletteWooPurple60),
        StoreColorToken(name: "storePaletteWooPurple70", color: .storePaletteWooPurple70),
        StoreColorToken(name: "storePaletteWooPurple80", color: .storePaletteWooPurple80),
        StoreColorToken(name: "storePaletteWooPurple90", color: .storePaletteWooPurple90),
        StoreColorToken(name: "storePaletteWooPurple100", color: .storePaletteWooPurple100),
        StoreColorToken(name: "storePaletteWooSandstone5", color: .storePaletteWooSandstone5),
        StoreColorToken(name: "storePaletteWooSandstone10", color: .storePaletteWooSandstone10),
        StoreColorToken(name: "storePaletteWooSandstone20", color: .storePaletteWooSandstone20),
        StoreColorToken(name: "storePaletteWooSandstone40", color: .storePaletteWooSandstone40),
        StoreColorToken(name: "storePaletteWooSandstone60", color: .storePaletteWooSandstone60),
        StoreColorToken(name: "storePaletteGray0", color: .storePaletteGray0),
        StoreColorToken(name: "storePaletteGray5", color: .storePaletteGray5),
        StoreColorToken(name: "storePaletteGray10", color: .storePaletteGray10),
        StoreColorToken(name: "storePaletteGray20", color: .storePaletteGray20),
        StoreColorToken(name: "storePaletteGray30", color: .storePaletteGray30),
        StoreColorToken(name: "storePaletteGray40", color: .storePaletteGray40),
        StoreColorToken(name: "storePaletteGray50", color: .storePaletteGray50),
        StoreColorToken(name: "storePaletteGray60", color: .storePaletteGray60),
        StoreColorToken(name: "storePaletteGray70", color: .storePaletteGray70),
        StoreColorToken(name: "storePaletteGray80", color: .storePaletteGray80),
        StoreColorToken(name: "storePaletteGray90", color: .storePaletteGray90),
        StoreColorToken(name: "storePaletteGray100", color: .storePaletteGray100),
    ]
}

// MARK: - Icons

extension StoreIcon {
    static let catalog: [StoreIconToken] = [
        StoreIconToken(variants: [StoreIcon.AngleDown.regular, StoreIcon.AngleDown.solid]),
        StoreIconToken(variants: [StoreIcon.AngleLeft.regular, StoreIcon.AngleLeft.solid]),
        StoreIconToken(variants: [StoreIcon.AngleRight.regular, StoreIcon.AngleRight.solid]),
        StoreIconToken(variants: [StoreIcon.AngleUp.regular, StoreIcon.AngleUp.solid]),
        StoreIconToken(variants: [StoreIcon.ArrowDown.light, StoreIcon.ArrowDown.regular, StoreIcon.ArrowDown.solid]),
        StoreIconToken(variants: [StoreIcon.ArrowDownArrowUp.light, StoreIcon.ArrowDownArrowUp.regular, StoreIcon.ArrowDownArrowUp.solid]),
        StoreIconToken(variants: [StoreIcon.ArrowRightFromBracket.regular]),
        StoreIconToken(variants: [StoreIcon.ArrowTrendUp.regular]),
        StoreIconToken(variants: [StoreIcon.ArrowUp.light, StoreIcon.ArrowUp.regular, StoreIcon.ArrowUp.solid]),
        StoreIconToken(variants: [StoreIcon.ArrowUpRight.regular, StoreIcon.ArrowUpRight.solid]),
        StoreIconToken(variants: [StoreIcon.ArrowsRotate.light, StoreIcon.ArrowsRotate.regular, StoreIcon.ArrowsRotate.solid]),
        StoreIconToken(variants: [StoreIcon.BadgePercent.regular, StoreIcon.BadgePercent.solid]),
        StoreIconToken(variants: [StoreIcon.Barcode.solid]),
        StoreIconToken(variants: [StoreIcon.BarcodeRead.regular, StoreIcon.BarcodeRead.solid]),
        StoreIconToken(variants: [StoreIcon.BarcodeScan.solid]),
        StoreIconToken(variants: [StoreIcon.Bars.light, StoreIcon.Bars.regular, StoreIcon.Bars.solid]),
        StoreIconToken(variants: [StoreIcon.BarsFilter.regular, StoreIcon.BarsFilter.solid]),
        StoreIconToken(variants: [StoreIcon.Bell.solid]),
        StoreIconToken(variants: [StoreIcon.Bolt.light, StoreIcon.Bolt.regular, StoreIcon.Bolt.solid]),
        StoreIconToken(variants: [StoreIcon.Bookmark.light, StoreIcon.Bookmark.regular, StoreIcon.Bookmark.solid]),
        StoreIconToken(variants: [StoreIcon.Box.light, StoreIcon.Box.regular, StoreIcon.Box.solid]),
        StoreIconToken(variants: [StoreIcon.BoxArchive.solid]),
        StoreIconToken(variants: [StoreIcon.BoxesStacked.regular]),
        StoreIconToken(variants: [StoreIcon.Calendar.light, StoreIcon.Calendar.regular, StoreIcon.Calendar.solid]),
        StoreIconToken(variants: [StoreIcon.CalendarDays.light, StoreIcon.CalendarDays.regular, StoreIcon.CalendarDays.solid]),
        StoreIconToken(variants: [StoreIcon.CaretDown.solid]),
        StoreIconToken(variants: [StoreIcon.CaretLargeRight.regular]),
        StoreIconToken(variants: [StoreIcon.CaretRight.solid]),
        StoreIconToken(variants: [StoreIcon.ChartLineUp.light, StoreIcon.ChartLineUp.regular, StoreIcon.ChartLineUp.solid]),
        StoreIconToken(variants: [StoreIcon.ChartSimple.regular, StoreIcon.ChartSimple.solid]),
        StoreIconToken(variants: [StoreIcon.ChevronDown.regular]),
        StoreIconToken(variants: [StoreIcon.CircleFull.light, StoreIcon.CircleFull.regular, StoreIcon.CircleFull.solid]),
        StoreIconToken(variants: [StoreIcon.CircleInfo.regular]),
        StoreIconToken(variants: [StoreIcon.CirclePlus.solid]),
        StoreIconToken(variants: [StoreIcon.Clock.light, StoreIcon.Clock.regular, StoreIcon.Clock.solid]),
        StoreIconToken(variants: [StoreIcon.Cloud.regular, StoreIcon.Cloud.solid]),
        StoreIconToken(variants: [StoreIcon.CommentQuestion.regular]),
        StoreIconToken(variants: [StoreIcon.CreditCard.regular, StoreIcon.CreditCard.solid]),
        StoreIconToken(variants: [StoreIcon.Ellipsis.regular, StoreIcon.Ellipsis.solid]),
        StoreIconToken(variants: [StoreIcon.File.light, StoreIcon.File.regular, StoreIcon.File.solid]),
        StoreIconToken(variants: [StoreIcon.Flask.regular]),
        StoreIconToken(variants: [StoreIcon.Gauge.regular]),
        StoreIconToken(variants: [StoreIcon.Gear.regular, StoreIcon.Gear.solid]),
        StoreIconToken(variants: [StoreIcon.Gears.solid]),
        StoreIconToken(variants: [StoreIcon.Gift.light, StoreIcon.Gift.regular, StoreIcon.Gift.solid]),
        StoreIconToken(variants: [StoreIcon.Globe.regular, StoreIcon.Globe.solid]),
        StoreIconToken(variants: [StoreIcon.Grid.light, StoreIcon.Grid.regular, StoreIcon.Grid.solid]),
        StoreIconToken(variants: [StoreIcon.GridPlus.regular, StoreIcon.GridPlus.solid]),
        StoreIconToken(variants: [StoreIcon.HandHoldingHeart.regular]),
        StoreIconToken(variants: [StoreIcon.House.light, StoreIcon.House.regular, StoreIcon.House.solid]),
        StoreIconToken(variants: [StoreIcon.Inbox.regular, StoreIcon.Inbox.solid]),
        StoreIconToken(variants: [StoreIcon.LayerGroup.regular, StoreIcon.LayerGroup.solid]),
        StoreIconToken(variants: [StoreIcon.LifeRing.regular, StoreIcon.LifeRing.solid]),
        StoreIconToken(variants: [StoreIcon.List.light, StoreIcon.List.regular, StoreIcon.List.solid]),
        StoreIconToken(variants: [StoreIcon.MagnifyingGlass.regular, StoreIcon.MagnifyingGlass.solid]),
        StoreIconToken(variants: [StoreIcon.MessageLines.solid]),
        StoreIconToken(variants: [StoreIcon.Mobile.regular]),
        StoreIconToken(variants: [StoreIcon.MoneyCheckDollar.regular]),
        StoreIconToken(variants: [StoreIcon.ObjectExclude.solid]),
        StoreIconToken(variants: [StoreIcon.ObjectUnion.regular]),
        StoreIconToken(variants: [StoreIcon.Pen.regular, StoreIcon.Pen.solid]),
        StoreIconToken(variants: [StoreIcon.Plug.regular]),
        StoreIconToken(variants: [StoreIcon.Plus.regular, StoreIcon.Plus.solid]),
        StoreIconToken(variants: [StoreIcon.PointOfSale.light, StoreIcon.PointOfSale.regular, StoreIcon.PointOfSale.solid]),
        StoreIconToken(variants: [StoreIcon.QRCode.light, StoreIcon.QRCode.regular, StoreIcon.QRCode.solid]),
        StoreIconToken(variants: [StoreIcon.Retweet.regular, StoreIcon.Retweet.solid]),
        StoreIconToken(variants: [StoreIcon.SackDollar.regular]),
        StoreIconToken(variants: [StoreIcon.ScrewdriverWrench.regular, StoreIcon.ScrewdriverWrench.solid]),
        StoreIconToken(variants: [StoreIcon.Share.light, StoreIcon.Share.regular, StoreIcon.Share.solid]),
        StoreIconToken(variants: [StoreIcon.Shield.regular]),
        StoreIconToken(variants: [StoreIcon.Sliders.light, StoreIcon.Sliders.regular, StoreIcon.Sliders.solid]),
        StoreIconToken(variants: [StoreIcon.Sparkles.light, StoreIcon.Sparkles.regular, StoreIcon.Sparkles.solid]),
        StoreIconToken(variants: [StoreIcon.SquareDollar.regular]),
        StoreIconToken(variants: [StoreIcon.SquarePlus.solid]),
        StoreIconToken(variants: [StoreIcon.Star.regular, StoreIcon.Star.solid]),
        StoreIconToken(variants: [StoreIcon.Store.light, StoreIcon.Store.regular, StoreIcon.Store.solid]),
        StoreIconToken(variants: [StoreIcon.Tag.light, StoreIcon.Tag.regular, StoreIcon.Tag.solid]),
        StoreIconToken(variants: [StoreIcon.ThumbsUp.regular]),
        StoreIconToken(variants: [StoreIcon.Ticket.regular]),
        StoreIconToken(variants: [StoreIcon.TicketPerforated.light, StoreIcon.TicketPerforated.regular, StoreIcon.TicketPerforated.solid]),
        StoreIconToken(variants: [StoreIcon.UseShield.regular]),
        StoreIconToken(variants: [StoreIcon.User.solid]),
        StoreIconToken(variants: [StoreIcon.UserGroup.regular, StoreIcon.UserGroup.solid]),
        StoreIconToken(variants: [StoreIcon.Wallet.light, StoreIcon.Wallet.regular, StoreIcon.Wallet.solid]),
        StoreIconToken(variants: [StoreIcon.Xmark.regular]),
    ]
}

// MARK: - Typography

extension StoreTextStyle {
    static let catalog: [StoreTextStyleToken] = [
        StoreTextStyleToken(name: "displayLarge", style: .displayLarge),
        StoreTextStyleToken(name: "displayMedium", style: .displayMedium),
        StoreTextStyleToken(name: "displaySmall", style: .displaySmall),
        StoreTextStyleToken(name: "headlineLarge", style: .headlineLarge),
        StoreTextStyleToken(name: "headlineMedium", style: .headlineMedium),
        StoreTextStyleToken(name: "headlineSmall", style: .headlineSmall),
        StoreTextStyleToken(name: "titleLarge", style: .titleLarge),
        StoreTextStyleToken(name: "titleMedium", style: .titleMedium),
        StoreTextStyleToken(name: "titleSmall", style: .titleSmall),
        StoreTextStyleToken(name: "labelLarge", style: .labelLarge),
        StoreTextStyleToken(name: "labelMedium", style: .labelMedium),
        StoreTextStyleToken(name: "labelSmall", style: .labelSmall),
        StoreTextStyleToken(name: "bodyLarge", style: .bodyLarge),
        StoreTextStyleToken(name: "bodyMedium", style: .bodyMedium),
        StoreTextStyleToken(name: "bodySmall", style: .bodySmall),
    ]
}
#endif
