//
//  Note.swift
//  naturenet
//
//  Created by Jinyue Xia on 1/27/15.
//  Copyright (c) 2015 Jinyue Xia. All rights reserved.
//

import Foundation
import CoreData

@objc(Note)
class Note: NNModel {

    @NSManaged var status: String
    @NSManaged var longitude: NSNumber
    @NSManaged var latitude: NSNumber
    @NSManaged var kind: String
    @NSManaged var context_id: NSNumber
    @NSManaged var account_id: NSNumber
    @NSManaged var content: String
    @NSManaged var context: Context
    
    // parse a note JSON
    func parseNoteJSON(mNote: NSDictionary) -> Note {
        self.uid = mNote["id"] as Int
        self.created_at = mNote["created_at"] as Int
        self.kind = mNote["kind"] as String
        self.modified_at = mNote["modified_at"] as Int
        if let lat = mNote["latitude"] as? Float {
            self.latitude = lat
        } else {
            self.latitude = 0.0
            println("no latitude")
        }
        
        if let lon = mNote["longitude"] as? Float {
            self.longitude = lon
        } else {
            self.longitude = 0.0
            println("no longitude")
        }

        self.content = mNote["content"] as String
        var contextID = mNote["context"]!["id"] as Int
        self.context_id = contextID
        var context = NNModel.doPullByUIDFromCoreData(NSStringFromClass(Context), uid: contextID) as Context
        self.context = context
        self.account_id = mNote["account"]!["id"] as Int
        self.status = mNote["status"] as String
        self.state = STATE.DOWNLOADED
        
        var medias = mNote["medias"] as NSArray
        setMedias(medias)
        return self
    }
    
    // give a new note update local
    func updateNote(mNote: NSDictionary) {
        self.setValue(mNote["modified_at"] as Int, forKey: "modified_at")
        self.setValue(mNote["content"] as String, forKey: "content")
        var contextID = mNote["context"]!["id"] as Int
        self.setValue(contextID, forKey: "contextID")
        self.setValue(STATE.DOWNLOADED, forKey: "state")
        var context = NNModel.doPullByUIDFromCoreData(NSStringFromClass(Context), uid: contextID) as Context
        self.setValue(context, forKey: "context")
    }
    
    // determine a note in local core data whether is up to date 
    // @Deprecated
    func isSyncedWithServer(serverNote: NSDictionary) -> Bool {
        var severModified = serverNote["modified_at"] as String
        if self.modified_at == severModified {
            return true
        }
        return false
    }
    
    // give a new note save to Note data
    class func saveNote(mNote: NSDictionary) -> Note {
        let context: NSManagedObjectContext = SwiftCoreDataHelper.nsManagedObjectContext
        var note =  SwiftCoreDataHelper.insertManagedObject(NSStringFromClass(Note), managedObjectConect: context) as Note
        note.parseNoteJSON(mNote as NSDictionary)
        println("note with \(note.uid) is: { \(note.toString()) }")
        SwiftCoreDataHelper.saveManagedObjectContext(context)
        note.commit()
        return note
    }
    
    // given JSON response of medias of a note, save medias into core data
    func setMedias(medias: NSArray) {
        for mediaDict in medias {
            let context: NSManagedObjectContext = SwiftCoreDataHelper.nsManagedObjectContext
            var media =  SwiftCoreDataHelper.insertManagedObject(NSStringFromClass(Media), managedObjectConect: context) as Media
            media.parseMediaJSON(mediaDict as NSDictionary)
            media.note = self
            println("media with note \(media.note.uid) is: { \(media.toString()) }")
            SwiftCoreDataHelper.saveManagedObjectContext(context)
        }
    }
    
    // given a note id, get medias from core data
    func getMedias() -> NSArray {
        let context: NSManagedObjectContext = SwiftCoreDataHelper.nsManagedObjectContext
        let request = NSFetchRequest(entityName: NSStringFromClass(Media))
        request.returnsDistinctResults = false
        request.predicate = NSPredicate(format: "note = %@", self.objectID)
        var results: NSArray = context.executeFetchRequest(request, error: nil)!
        return results
    }
    
    // update media with a local path
    func updateMedia(path: String) {
        
    }
    
    
    func toString() -> String {
        return "noteid: \(uid) createdAt: \(created_at) latitude: \(latitude) logitutde: \(longitude) status: \(status)"
    }

}
