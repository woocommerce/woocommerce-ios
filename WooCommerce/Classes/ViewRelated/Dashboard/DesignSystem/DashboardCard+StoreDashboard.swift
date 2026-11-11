import struct Yosemite.DashboardCard

extension Collection where Element == DashboardCard {
    /// Android gives Share Store precedence over the new-sections notice when both are eligible.
    var cardsForStoreDashboard: [DashboardCard] {
        guard contains(where: { $0.type == .shareStore }) else {
            return Array(self)
        }
        return filter { $0.type != .newCardsNotice }
    }
}
