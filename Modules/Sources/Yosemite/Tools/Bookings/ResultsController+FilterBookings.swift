import CoreData
import Storage

extension NSPredicate {
    public static func createBookingPredicate(siteID: Int64, filters: BookingFilters) -> NSPredicate {
        let siteIDPredicate = NSPredicate(format: "siteID == %lld", siteID)

        let productIDsPredicate = filters.productIDs.isNotEmpty ? NSPredicate(format: "productID IN %@", filters.productIDs) : nil

        let customerIDsPredicate = filters.customerIDs.isNotEmpty ? NSPredicate(format: "customerID IN %@", filters.customerIDs) : nil

        let resourceIDsPredicate = filters.resourceIDs.isNotEmpty ? NSPredicate(format: "resourceID IN %@", filters.resourceIDs) : nil

        let startDateBeforePredicate = filters.startDateBefore.flatMap { dateString -> NSPredicate? in
            guard let date = ISO8601DateFormatter().date(from: dateString) else { return nil }
            return NSPredicate(format: "startDate < %@", date as NSDate)
        }

        let startDateAfterPredicate = filters.startDateAfter.flatMap { dateString -> NSPredicate? in
            guard let date = ISO8601DateFormatter().date(from: dateString) else { return nil }
            return NSPredicate(format: "startDate > %@", date as NSDate)
        }

        let bookingStatusesPredicate = filters.bookingStatuses.isNotEmpty ? NSPredicate(format: "statusKey IN %@", filters.bookingStatuses) : nil

        let attendanceStatusesPredicate = filters.attendanceStatuses.isNotEmpty ? NSPredicate(format: "attendanceStatusKey IN %@", filters.attendanceStatuses) : nil

        let subpredicates = [
            siteIDPredicate,
            productIDsPredicate,
            customerIDsPredicate,
            resourceIDsPredicate,
            startDateBeforePredicate,
            startDateAfterPredicate,
            bookingStatusesPredicate,
            attendanceStatusesPredicate
        ].compactMap({ $0 })

        return NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)
    }
}

extension ResultsController where T: StorageBooking {
    public func updatePredicate(siteID: Int64, filters: BookingFilters) {
        self.predicate = NSPredicate.createBookingPredicate(siteID: siteID, filters: filters)
    }
}
