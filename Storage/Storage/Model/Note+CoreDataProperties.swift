import Foundation
import CoreData


extension Note {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Note> {
        return NSFetchRequest<Note>(entityName: "Note")
    }

    @NSManaged public var noteID: Int64
    @NSManaged public var noteHash: Int64
    @NSManaged public var read: Bool
    @NSManaged public var icon: String?
    @NSManaged public var noticon: String?
    @NSManaged public var timestamp: String?
    @NSManaged public var type: String?
    @NSManaged public var url: String?
    @NSManaged public var title: String?
    @NSManaged public var subject: Data?
    @NSManaged public var header: Data?
    @NSManaged public var body: Data?
    @NSManaged public var meta: Data?
}
