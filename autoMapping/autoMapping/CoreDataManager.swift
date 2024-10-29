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
    
    func saveItem(names: String, authors: String, mapNames: String, x_sizes: Float, y_sizes: Float, comments: String, images: UIImage, itemColors: UIColor){
        let context = persistentContainer.viewContext
        let newItem = Item(context: context)
        newItem.id = UUID()
        newItem.name = names
        newItem.author = authors
        newItem.mapName = mapNames
        newItem.x_size = x_sizes
        newItem.y_size = y_sizes
        newItem.comment = comments
        newItem.imageData = images.pngData()
        newItem.itemColor = itemColors.accessibilityName
        newItem.isDetected = false
        
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
    
    func fetchItemByMapName(mapName: String) -> [Item] {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        
        fetchRequest.predicate = NSPredicate(format: "mapName == %@", mapName)
        
        do {
            let result = try context.fetch(fetchRequest)
            return result
        } catch {
            print("Error, Item not retrieved: \(error)")
            return []
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
    
    func fetchAllItemNames() -> [String] {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.propertiesToFetch = ["name"]
        fetchRequest.resultType = .dictionaryResultType
        
        do {
            let result = try context.fetch(fetchRequest) as! [[String: Any]]
            let names = result.compactMap { $0["name"] as? String}
            return names
        } catch {
            print("Error, names not retrived: \(error)")
            return []
        }
    }
    
    func setIsDetected(forName name: String) {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        
        do {
            let item = try context.fetch(fetchRequest).first
            item?.isDetected = true
            
            try context.save()
        } catch {
            print("Error, item not setted: \(error)")
        }
    }
    
    func isPresent(name: String, author: String , image: UIImage) -> Bool{
        let items : [Item] = fetchAllItem()
        for item in items {
            if item.name == name && item.author == author && item.imageData == image.pngData() {
                return true
            }
        }
        return false
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
