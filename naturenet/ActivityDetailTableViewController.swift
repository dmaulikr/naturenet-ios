//
//  ActivityDetailTableViewController.swift
//  NatureNet
//
//  Created by Jinyue Xia on 4/19/15.
//  Copyright (c) 2015 Jinyue Xia. All rights reserved.
//

import UIKit

class ActivityDetailTableViewController: UITableViewController, UINavigationControllerDelegate,
                        UIImagePickerControllerDelegate, SaveObservationProtocol, APIControllerProtocol {
    
    var activity: Context!
    var cameraImage: UIImage!
    var apiService = APIService()
    var notesInActivtity: [Note]?
    
    @IBOutlet weak var activityIconImageView: UIImageView!
    @IBOutlet var tableview: UITableView!
    @IBOutlet weak var activityDescriptionLabel: UILabel!
    @IBOutlet weak var numOfNoteInActivity: UILabel!
    @IBOutlet weak var iconActivityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        apiService.delegate = self
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        // self.edgesForExtendedLayout = UIRectEdge.None

        self.navigationController?.setToolbarHidden(false, animated: true)
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setToolbarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return 1
    }

    private func setupView() {
        var iconURL = activity.extras
        if let data = iconURL.dataUsingEncoding(NSUTF8StringEncoding)  {
            if let json = (try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers)) as? NSDictionary {
                iconURL = json["Icon"] as! String
                ImageHelper.loadImageFromWeb(iconURL, imageview: activityIconImageView, indicatorView: iconActivityIndicator)            }
        }

        self.navigationItem.title = activity.title
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 180.0
        activityDescriptionLabel.text = activity.context_description
        self.notesInActivtity = Session.getAccount()?.getNotesByActivity(self.activity)
        let number: Int = notesInActivtity!.count
        self.numOfNoteInActivity.text = String(number)
    }
    

    //----------------------------------------------------------------------------------------------------------------------
    // segues setup
    //----------------------------------------------------------------------------------------------------------------------
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "activityToObservation" {
            let detailVC = segue.destinationViewController as! ObservationDetailController
            detailVC.imageFromObservation = ObservationsController.PickedImage(image: self.cameraImage, isFromGallery: false)
            detailVC.activityNameFromActivityDetail = activity.title
            detailVC.saveObservationDelegate = self
            detailVC.sourceViewController = NSStringFromClass(ActivityDetailTableViewController)
        }
    }
    
    //----------------------------------------------------------------------------------------------------------------------
    // pick from camera or gallary
    //----------------------------------------------------------------------------------------------------------------------
    @IBAction func openCamera() {
        let picker:UIImagePickerController = UIImagePickerController()
        picker.delegate = self
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)) {
            picker.sourceType = UIImagePickerControllerSourceType.Camera
            self.presentViewController(picker, animated: true, completion: nil)
        } else {
            openGallary(picker)
        }
    }
    
    func openGallary(picker: UIImagePickerController!) {
        picker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            self.presentViewController(picker, animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
        print("picker cancel.")
    }
    
    // after picking or taking a photo didFinishPickingMediaWithInfo
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        picker.dismissViewControllerAnimated(true, completion: nil)
        self.cameraImage = info[UIImagePickerControllerOriginalImage] as? UIImage
        self.performSegueWithIdentifier("activityToObservation", sender: self)
    }
    
    
    // implement saveObservation to conform SaveObservationProtocol
    func saveObservation(note: Note, media: Media?, feedback: Feedback?) {
         note.push(apiService)
    }
    
    // implement didReceiveResults to conform APIControllerProtocol
    func didReceiveResults(from: String, sourceData: NNModel?, response: NSDictionary) {
        dispatch_async(dispatch_get_main_queue(), {
            let status = response["status_code"] as! Int
            if status == 600 {
                let alertTitle = "Internet Connection Problem"
                let alertMessage = "Please check your Internet connection"
                AlertControllerHelper.createGeneralAlert(alertTitle, message: alertMessage, controller: self)
                return
            }
            
            let uid = response["data"]!["id"] as! Int
            if from == "POST_" + NSStringFromClass(Note) {
                print("now after post_note, ready for uploading feedbacks")
                let modifiedAt = response["data"]!["modified_at"] as! NSNumber
                if let newNote = sourceData as? Note {
                    newNote.updateAfterPost(uid, modifiedAtFromServer: modifiedAt)
                    newNote.doPushFeedbacks(self.apiService)
                    if let newNoteMedia = newNote.getSingleMedia() {
                        if newNoteMedia.url != nil {
                        } else {
                            newNoteMedia.apiService = self.apiService
                            newNoteMedia.uploadToCloudinary()
                        }
                    }
                }
            }
            if from == "POST_" + NSStringFromClass(Feedback) {
                print("now after post_feedback, if this is a new note, ready for uploading to cloudinary, otherwise, do update")
                let modifiedAt = response["data"]!["modified_at"] as! NSNumber
                if let newNoteFeedback = sourceData as? Feedback {
                    newNoteFeedback.updateAfterPost(uid, modifiedAtFromServer: modifiedAt)
                }
            }
            if from == "POST_" + NSStringFromClass(Media) {
                print("now after post_media")
                if let newNoteMedia = sourceData as? Media {
                    newNoteMedia.updateAfterPost(uid, modifiedAtFromServer: nil)

                }
            }
        })

    }
    
}
