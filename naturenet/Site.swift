//
//  Site.swift
//  naturenet
//
//  Created by Jinyue Xia on 1/26/15.
//  Copyright (c) 2015 Jinyue Xia. All rights reserved.
//

import Foundation
import CoreData

@objc(Site)
class Site: NNModel {
    @NSManaged var site_description: String
    @NSManaged var image_url: String
    @NSManaged var name: String
    @NSManaged var kind: String
    @NSManaged var contexts: NSArray
    
    // pull info from remote server
    class func doPullByNameFromServer(parseService: APIService, name: String) {
        var accountUrl = APIAdapter.api.getSiteLink(name)
        parseService.getResponse(accountUrl)
    }
    
    // pull information from coredata
    class func doPullByNameFromCoreData(name: String) -> Site? {
        var site: Site?
        let context: NSManagedObjectContext = ManagedObjectContext.context
        let request = NSFetchRequest(entityName: "Site")
        request.returnsDistinctResults = false
        request.predicate = NSPredicate(format: "name = %@", name)
        var results: NSArray = context.executeFetchRequest(request, error: nil)!
        if results.count > 0 {
            for res in results {
                if let tSite = res as? Site {
                    // println(tUser.toString())
                    site = tSite
                }
            }
        } else {
            println("no site matched in site's doPullByNameFromCoreData")
        }
        return site
    }
    
    // save a new site in coredata
    class func createInManagedObjectContext(name: String, uid: Int, description: String, imageURL: String, contexts: NSArray ) -> Site {
            let context: NSManagedObjectContext = ManagedObjectContext.context
            let ent = NSEntityDescription.entityForName("Site", inManagedObjectContext: context)!
            let newSite = Site(entity: ent, insertIntoManagedObjectContext: context)
            newSite.name = name
            newSite.uid = uid
            newSite.site_description = description
            newSite.image_url = imageURL
            newSite.state = STATE.DOWNLOADED
            newSite.contexts = contexts
            context.save(nil)
            println("newSite is : \(newSite)" + "Site entity is: \(newSite.toString())")
            return newSite
    }
    
    func toString() -> String {
        var string = "name: \(name) uid: \(uid) modified: \(modified_at) state: \(state)"
        return string
    }
    
    override func resolveDependencies() {
        if (contexts.count > 0) {
            for context in contexts {
                if let tContext = context as? Context {
                    tContext.state = STATE.DOWNLOADED
                }
            }
        }
    }

}
