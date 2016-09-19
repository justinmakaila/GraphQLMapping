import CoreData


final class User: NSManagedObject {
    @NSManaged
    fileprivate var addressValue: Data
    var address: [String: String] {
        get {
            guard let address = NSKeyedUnarchiver.unarchiveObject(with: addressValue) as? [String: String]
            else {
                return [:]
            }
            
            return address
        }
        set {
            addressValue = NSKeyedArchiver.archivedData(withRootObject: newValue)
        }
    }
}
