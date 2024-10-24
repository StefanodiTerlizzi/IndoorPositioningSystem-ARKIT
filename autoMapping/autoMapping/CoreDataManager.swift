import CoreData
import UIKit

class CoreDataManager {
    static let shared = CoreDataManager()
    
    let persistentContainer: NSPersistentContainer
    
    private init() {
        persistentContainer = NSPersistentContainer(name: "autoMapping")
        persistentContainer.loadPersistentStores{(description, error) in if let error = error {
            fatalError("Error in load Core Data stack: \(error)")
        }}
    }
    
    func saveItem(name: String, x_size: Float, y_size: Float, comment: String, image: UIImage){
        let context = persistentContainer.viewContext
        let newItem = Item(context: context)
        newItem.id = UUID()
        newItem.name = name
        newItem.x_size = x_size
        newItem.y_size = y_size
        newItem.comment = comment
        newItem.imageData = image.pngData()
        
        do {
            try context.save()
        } catch {
            print("Error, item not saved: \(error)")
        }
    }
    
    func fetchAllItem() -> [Item] {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error, data not retrieved: \(error)")
            return []
        }
    }
    
    func fetchItemByName(name: String) -> Item? {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        
        do {
            let result = try context.fetch(fetchRequest)
            return result.first
        } catch {
            print("Error, Item not retrieved: \(error)")
            return nil
        }
    }
    
    func fetchItemByImage(image: UIImage) -> Item? {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        
        let imageData = image.pngData()
        
        fetchRequest.predicate = NSPredicate(format: "imageData == %@", imageData! as NSData)
        
        do {
            let result = try context.fetch(fetchRequest)
            return result.first
        } catch {
            print("Error, Item not retrieved: \(error)")
            return nil
        }
    }
    
    func deleteItem(item: Item) {
        let context = persistentContainer.viewContext
        context.delete(item)
        
        do {
            try context.save()
        } catch {
            print("Error, Item not cancelled: \(error)")
        }
    }
    
    func deletAllItems() {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Item.fetchRequest()
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(batchDeleteRequest)
            try context.save()
        } catch {
            print("Error data not cancelled: \(error)")
        }
    }
}
