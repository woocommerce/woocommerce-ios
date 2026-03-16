import CoreData

extension NSPredicate {
    public static func createBookingPredicate(siteID: Int64, filters: BookingFilters) -> NSPredicate {
        let siteIDPredicate = NSPredicate(format: "siteID == %lld", siteID)

        let productIDsPredicate = filters.productIDs.isNotEmpty ? NSPredicate(format: "productID IN %@", filters.productIDs) : nil

        let customerIDsPredicate = filters.customerIDs.isNotEmpty ? NSPredicate(format: "userID IN %@", filters.customerIDs) : nil

        let resourceIDsPredicate = filters.resourceIDs.isNotEmpty ? NSPredicate(format: "resourceID IN %@", filters.resourceIDs) : nil

        let startDateBeforePredicate = filters.startDateBefore.flatMap { dateString -> NSPredicate? in
            guard let date = ISO8601DateFormatter().date(from: dateString) else { return nil }
            return NSPredicate(format: "startDate <= %@", date as NSDate)
        }

        let startDateAfterPredicate = filters.startDateAfter.flatMap { dateString -> NSPredicate? in
            guard let date = ISO8601DateFormatter().date(from: dateString) else { return nil }
            return NSPredicate(format: "startDate >= %@", date as NSDate)
        }

        // TODO: update `statusKey` to paymentStatusKey once available
        let paymentStatusesPredicate = filters.paymentStatuses.isNotEmpty ? NSPredicate(format: "statusKey IN %@", filters.paymentStatuses) : nil

        let attendanceStatusPredicate = filters.attendanceStatus.map {
            NSPredicate(format: "attendanceStatusKey == %@", $0)
        }

        let bookingStatusExcludePredicate = filters.bookingStatusExclude.isNotEmpty ?
        NSPredicate(format: "NOT (statusKey IN %@)", filters.bookingStatusExclude) : nil

        let subpredicates = [
            siteIDPredicate,
            productIDsPredicate,
            customerIDsPredicate,
            resourceIDsPredicate,
            startDateBeforePredicate,
            startDateAfterPredicate,
            paymentStatusesPredicate,
            attendanceStatusPredicate,
            bookingStatusExcludePredicate
        ].compactMap({ $0 })

        return NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)
    }
}

extension ResultsController where T: StorageBooking {
    public func updatePredicate(siteID: Int64, filters: BookingFilters) {
        self.predicate = NSPredicate.createBookingPredicate(siteID: siteID, filters: filters)
    }
}
