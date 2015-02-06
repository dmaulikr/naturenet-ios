//
//  SwiftCoreDataHelper.swift
//  naturenet
//
//  Created by Jinyue Xia on 1/27/15.
//  Copyright (c) 2015 Jinyue Xia. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class SwiftCoreDataHelper {
    class var nsManagedObjectContext: NSManagedObjectContext {
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let context: NSManagedObjectContext = appDelegate.managedObjectContext!
        return context
    }
    
    class func insertManagedObject(className:NSString, managedObjectConect:NSManagedObjectContext) -> AnyObject {
        let managedObject:NSManagedObject = NSEntityDescription.insertNewObjectForEntityForName(className, inManagedObjectContext: managedObjectConect) as NSManagedObject
        
        return managedObject
        
    }
    
    class func getEntityByModelName(className:NSString, managedObjectContext:NSManagedObjectContext) -> AnyObject {
        let fetchRequest:NSFetchRequest = NSFetchRequest()
        let entetyDescription:NSEntityDescription = NSEntityDescription.entityForName(className, inManagedObjectContext: managedObjectContext)!
        let entity = NSManagedObject(entity: entetyDescription, insertIntoManagedObjectContext: managedObjectContext)
        return entity
    }
    
    
    class func saveManagedObjectContext (managedObjectContext:NSManagedObjectContext) -> Bool {
        if managedObjectContext.save(nil){
            return true
        }else{
            return false
        }
    }
    
    class func fetchEntities(className:NSString, withPredicate predicate:NSPredicate?, managedObjectContext:NSManagedObjectContext)->NSArray{
        let fetchRequest:NSFetchRequest = NSFetchRequest()
        let entetyDescription:NSEntityDescription = NSEntityDescription.entityForName(className, inManagedObjectContext: managedObjectContext)!
        
        fetchRequest.entity = entetyDescription
        if predicate != nil {
            fetchRequest.predicate = predicate!
        }
        
        fetchRequest.returnsObjectsAsFaults = false
        let items:NSArray = managedObjectContext.executeFetchRequest(fetchRequest, error: nil)!
        
        return items
    }
    

}