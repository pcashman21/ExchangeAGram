//
//  FeedViewController.swift
//  ExchangeAGram
//
//  Created by Paul Cashman on 1/2/15.
//  Copyright (c) 2015 Paul Cashman. All rights reserved.
//

import UIKit
import MobileCoreServices   // to get at UIImagePickerController functions
import CoreData             // to get at persistent storage functions

class FeedViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    
    // For this project, we are NOT using FetchedResultsController (as we did in TaskIt) 
    // because the BitFountain instructor feels it's useful for us to see what is going on 
    // under the hood.
    //
    // The feedArray is declared to hold items of type AnyObject rather than FeedItem because 
    // when we make the request, Swift doesn't know what types are going to be handed back.
    
    var feedArray: [AnyObject] = [] // Every class property MUST be initalized or you get an error
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // viewDidAppear is called *every time* the view is presented on the screen, not just the 
    // first time (viewDidLoad).  This enables us to refresh the view in case the user selects
    // a filtered image to replace the unfiltered image originally presented in this view.
    override func viewDidAppear(animated: Bool) {
        // Create an NSFetchRequest to get all the FeedItems
        let request = NSFetchRequest(entityName: "FeedItem")
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let context = appDelegate.managedObjectContext!
        // Even though we are specifying a fetch request on "FeedItem", the "execute" function
        // doesn't know the type of object it is returning.  This is why feedArray is an array
        // holding instance of AnyObject.
        feedArray = context.executeFetchRequest(request, error: nil)!
        collectionView.reloadData() // Refresh the view
    }
    
    @IBAction func snapBarButtonItemTapped(sender: UIBarButtonItem) {
        
        // Check to see if there is a camera available to us. To get at the UIImagePickerController
        // class, we have to import the MobileCoreServices framework.
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            var cameraController = UIImagePickerController()  // Set up a controller
            cameraController.delegate = self                  // The instance to call back is self
            cameraController.sourceType = UIImagePickerControllerSourceType.Camera // This is a camera
            
            let mediaTypes:[AnyObject] = [kUTTypeImage] // This line and next are boilerplate
            cameraController.mediaTypes = mediaTypes
            cameraController.allowsEditing = false      // Pictures can't be edited
            
            // Now display the camera
            self.presentViewController(cameraController, animated: true, completion: nil)
        }
            
        // Check to see if the photo library is available instead
        else if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary) {
            // Same structure as for camera above
            var photoLibraryController = UIImagePickerController()
            photoLibraryController.delegate = self
            photoLibraryController.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            
            let mediaTypes:[AnyObject] = [kUTTypeImage]
            photoLibraryController.mediaTypes = mediaTypes
            photoLibraryController.allowsEditing = false
            
            self.presentViewController(photoLibraryController, animated: true, completion: nil)
        }
        else {
            // Set up AlertController instance
            var alertController = UIAlertController(title: "Alert", message: "Your device does not support the camera or photo library", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    // UIImagePickerControllerDelegate protocol functions
    //
    // Needed when we're picking images from the camera or photo library.
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) { // Note that the info parameter is a dictionary
        
        // Use the info dictionary to select the original photo image (other keys allow selection 
        // of edited, cropped, etc. versions).  Since this is a dictionary that can return an 
        // instance of AnyObject, need the "as UIImage" to set the right class.
        let image = info[UIImagePickerControllerOriginalImage] as UIImage
        
        // Take the image and return it as an NSData object which is the JPEG representation at 
        // the specified compression (1.0, in this case).  We need the image as NSData because 
        // that is what CoreData's representation (FeedItem) knows how to store.
        let imageData = UIImageJPEGRepresentation(image, 1.0)
        // Create the thumbnail image at a lower compression quality
        let thumbnailData = UIImageJPEGRepresentation(image, 0.1)
        
        
        // To store in persistent storage, (1) get our managed object context, and 
        // (2) create an "empty" FeedItem using that managed object context.
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let managedObjectContext = appDelegate.managedObjectContext
        let entityDescription = NSEntityDescription.entityForName("FeedItem", inManagedObjectContext: managedObjectContext!)
        
        // This line of code SHOULD work, but a bug in Xcode seems to prevent its working.
        // The problem shows up as (1) can't autocomplete FeedItem(...) and (2) the properties
        // of FeedItem aren't recognized as properties.  I tried doing the fix at
        // http://stackoverflow.com/questions/25133039/xcode-6-isnt-autocompleting-in-swift
        // but could not find the Xcode directory they mention.
        //
        //        let feedItem = FeedItem(entity: entityDescription!, insertIntoManagedItemContext: managedObjectContext!)
        // The following line was suggested by someone in the course in the comments at 
        // http://bitfountain.io/lecture/100628/exchangeagram-persisting-a-feeditem/
        // and that seems to work.
        
        let feedItem = NSEntityDescription.insertNewObjectForEntityForName("FeedItem", inManagedObjectContext: managedObjectContext!) as FeedItem
        
        feedItem.image = imageData
        feedItem.caption = "test caption"
        feedItem.thumbnail = thumbnailData
        
        feedArray.append(feedItem)  // Add the picked item to the feedArray
        appDelegate.saveContext()
        
        // Get rid of the image picker view controller.
        self.dismissViewControllerAnimated(true, completion: nil)
        // And force a reload/redisplay of the updated data
        self.collectionView.reloadData()
    
    }
    
    // UICollectionViewDataSource protocol functions
    //
    // To make iOS aware that this FeedViewController class is a participant in the 
    // UICollectionViewDataSource and UICollectionViewDelegate protocols, two things have to happen:
    //
    //  1. UICollectionViewDataSource and UICollectionViewDelegate must be added as part of
    //      the type definition forFeedViewController at the top of this file.
    //  2. In the storyboard view, click on the Collection View item in the sidebar and use
    //      control-drag to link it to the Feed View Controller item.  In the pop-up menu that 
    //      displays, click on "dataSource."  Repeat this step, but click on the "delegate"
    //      selection in the pop-up menu.
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return feedArray.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        // Get the FeedCell at the given indexPath.  The ReuseIdentifier was set for this cell 
        // in the storyboard (look at the identity examiner for the prototype cell).
        var cell: FeedCell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as FeedCell
        
        // Get the item for the feedArray.  The "row" property is something of a misnomer, since
        // in a collection it's as if there were one giant row.  But in effect, this property, 
        // when used in a collection, acts as an index into the collection.
        let thisItem = feedArray[indexPath.row] as FeedItem
        
        // To display the image, convert it from NSData (JPEG binary) to UIImage.
        cell.imageView.image = UIImage(data: thisItem.image)
        cell.captionLabel.text = thisItem.caption
        
        return cell
    }
    
    // UICollectionViewDelegate protocol functions
    //
    // These functions set up the segue once a user has selected a feed item (image) from the
    // collection of those images.
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let thisItem = feedArray[indexPath.row] as FeedItem // get the selected FeedItem
        
        // Create an empty FilterViewController.  In previous projects we created a view controller 
        // in the Storyboard, gave it a name, and called it from the code.  Now we're creating a VC 
        // entirely in code.
        var filterVC = FilterViewController()
        filterVC.thisFeedItem = thisItem // Pass the selected feed item to the VC
        
        // Now display the FilterViewController.  We are inside a NavigationController stack
        // (can see this in the Storyboard), so push the FilterViewController onto the stack.
        // Class instructor says not to use animation -- looks better without it.
        self.navigationController?.pushViewController(filterVC, animated: false)
    }

}
