import CoreData


final class User: NSManagedObject {
    @NSManaged
    private var addressValue: NSData
    var address: [String: String] {
        get {
            guard let address = NSKeyedUnarchiver.unarchiveObjectWithData(addressValue) as? [String: String]
            else {
                return [:]
            }
            
            return address
        }
        set {
            addressValue = NSKeyedArchiver.archivedDataWithRootObject(newValue)
        }
    }
}