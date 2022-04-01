import Foundation

protocol ReviewsDataSourceDelegate: AnyObject {
    var shouldShowProductTitle: Bool { get }

    func reviewsFilterPredicate(with sitePredicate: NSPredicate) -> NSPredicate
}
