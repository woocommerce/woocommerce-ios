import enum Yosemite.OrderStatusEnum

extension Array where Element == Yosemite.OrderStatusEnum {
    var analyticsDescription: String? {
        map { $0.rawValue }.joined(separator: ",")
    }
}
