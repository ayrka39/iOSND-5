//
//  CoreDataStack.swift
//  Mom's Weather
//
//  Created by David on 10/31/16.
//  Copyright © 2016 David. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack {
	
	static let shared = CoreDataStack()
	
	// MARK: - Core Data stack
	
	var context: NSManagedObjectContext {
		return CoreDataStack.shared.persistentContainer.viewContext
	}
	
	lazy var persistentContainer: NSPersistentContainer = {
		
		let container = NSPersistentContainer(name: "weatherForMom")
		container.loadPersistentStores(completionHandler: { (storeDescription, error) in
			if let error = error as NSError? {
				fatalError("Unresolved error \(error), \(error.userInfo)")
			}
		})
		return container
	}()
	
	// MARK: - Core Data Saving support
	
	func saveContext () {
		let context = persistentContainer.viewContext
		if context.hasChanges {
			do {
				try context.save()
			} catch {
				let nserror = error as NSError
				fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
			}
		}
	}

}
