//
//  FilterViewController.swift
//  ExchangeAGram
//
//  Created by Paul Cashman on 1/6/15.
//  Copyright (c) 2015 Paul Cashman. All rights reserved.
//

import UIKit

class FilterViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    var thisFeedItem: FeedItem! // Passed in from the FeedViewController didSelectItemAtIndexPath function
    var collectionView: UICollectionView!
    let kIntensity = 0.7
    // CIContext provides an evaluation context for working with CIImages
    var context:CIContext = CIContext(options: nil)
    var filters: [CIFilter] = []
    let placeholderImage = UIImage(named: "Placeholder") // Name of images in Images.xcassets
    let tmp = NSTemporaryDirectory() // Place to store cached items temporarily
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let layout = UICollectionViewFlowLayout() // Means of organizing how the collection looks
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10) // Set borders
        layout.itemSize = CGSize(width: 150.0, height: 150.0) // Size of a displayed FeedItem
        // Create the CollectionView using the entire real estate of the frame we're in
        collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor.whiteColor()
        // Recall that in the Storyboard, we would set the name of the class of the cell
        // within the collection or table, and give the name of the prototype cell
        collectionView.registerClass(FilterCell.self, forCellWithReuseIdentifier: "MyCell")
        
        self.view.addSubview(collectionView) // Cause collectionView to be displayed
        filters = photoFilters() // Set up the array of filters
        
       
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // UICollectionViewDataSource protocol
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filters.count // There will be one FilterCell for each filter, to show all filtered images
    }
    
    // cellForItemAtIndexPath is called as many times as the value of the 
    // numberOfItemsInSection function returns.
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        // Get the reusable cell we named earlier
        let cell: FilterCell = collectionView.dequeueReusableCellWithReuseIdentifier("MyCell", forIndexPath: indexPath) as FilterCell
        if cell.imageView.image == nil {
            cell.imageView.image = placeholderImage
            
            // cell has an imageView property (see FilterCell) and we can set its thumbnail, but
            // image processing takes a long time, so put it in another processing queue.
            // Create a queue for the thread that will handle image processing
            let filterQueue: dispatch_queue_t = dispatch_queue_create("filter queue", nil)
            // Create a closure to run when the filter queue gets priority
            dispatch_async(filterQueue, { () -> Void in
                // Get the cached image (if it's not in cache, put it there)
                let filterImage = self.getCachedImage(indexPath.row)
                // Once we have the filtered image, tell the main queue to run and update the UI.
                // NEVER UPDATE UI FROM QUEUE OTHER THAN MAIN!!
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    cell.imageView.image = filterImage
                })
            })
        }
        
        return cell // This will return the Placeholder cell.  The above closure will cause the
                    // image of each cell to become the filtered image when the processing for that
                    // image is ready.
    }
    
    // UICollectionViewDelegate functions
    
    // User selects a filtered image to store.
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        // Save the filtered image of the image itself, NOT the low-res thumbnail.  In other words,
        // when the user goes back to the main FeedItem view, replace the unfiltered image there 
        // with the selected filtered image.
        let filterImage = self.filteredImageFromImage(self.thisFeedItem.image, filter: self.filters[indexPath.row])
        let imageData = UIImageJPEGRepresentation(filterImage, 1.0)
        self.thisFeedItem.image = imageData
        self.thisFeedItem.thumbnail = UIImageJPEGRepresentation(filterImage, 0.1)
        // Save the changed object in Core Data
        (UIApplication.sharedApplication().delegate as AppDelegate).saveContext()
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    // Helper functions
    
    func photoFilters () -> [CIFilter] {
        let blur = CIFilter(name: "CIGaussianBlur")
        let instant = CIFilter(name: "CIPhotoEffectInstant")
        let noir = CIFilter(name: "CIPhotoEffectNoir")
        let transfer = CIFilter(name: "CIPhotoEffectTransfer")
        let unsharpen = CIFilter(name: "CIUnsharpMask")
        let monochrome = CIFilter(name: "CIColorMonochrome")
        
        let colorControls = CIFilter(name: "CIColorControls")
        colorControls.setValue(0.5, forKey: kCIInputSaturationKey)
        
        let sepia = CIFilter(name: "CISepiaTone")
        sepia.setValue(kIntensity, forKey: kCIInputIntensityKey)
        
        let colorClamp = CIFilter(name: "CIColorClamp")
        colorClamp.setValue(CIVector(x: 0.9, y: 0.9, z: 0.9, w: 0.9), forKey: "inputMaxComponents")
        colorClamp.setValue(CIVector(x: 0.2, y: 0.2, z: 0.2, w: 0.2), forKey: "inputMinComponents")
        
        let composite = CIFilter(name: "CIHardLightBlendMode")
        composite.setValue(sepia.outputImage, forKey: kCIInputImageKey)
        
        let vignette = CIFilter(name: "CIVignette")
        vignette.setValue(composite.outputImage, forKey: kCIInputImageKey)
        vignette.setValue(kIntensity * 2, forKey: kCIInputIntensityKey)
        vignette.setValue(kIntensity * 30, forKey: kCIInputRadiusKey)
        
        return [blur, instant, noir, transfer, unsharpen, monochrome, colorControls, sepia, colorClamp, composite, vignette]
    }
    
    func filteredImageFromImage(imageData: NSData, filter: CIFilter) -> UIImage {
        let unfilteredImage = CIImage(data: imageData) // Turn our NSData into a CIImage first
        filter.setValue(unfilteredImage, forKey: kCIInputImageKey) // And pass the CIImage into the filter
        let filteredImage: CIImage = filter.outputImage // Get the filtered result
        let extent = filteredImage.extent() // Get the rect[angle] of the filtered image
        // Create an optimized bitmap image of the right size
        let cgImage: CGImage = context.createCGImage(filteredImage, fromRect: extent)
        // Finally, turn the CGImage into a UIImage and return it
        let finalImage = UIImage(CGImage: cgImage)
        return finalImage!
    }
    
    // Caching functions
    
    func cacheImage(imageNumber: Int) {
        let fileName = "\(imageNumber)"
        let uniquePath = tmp.stringByAppendingPathComponent(fileName) // Create unique path within temp directory
        // If the image hasn't been cached, do so now
        if !NSFileManager.defaultManager().fileExistsAtPath(fileName) {
            let data = self.thisFeedItem.thumbnail
            let filter = self.filters[imageNumber]
            let image = filteredImageFromImage(data, filter: filter)
            UIImageJPEGRepresentation(image, 1.0).writeToFile(uniquePath, atomically: true)
        }
    }
    
    func getCachedImage (imageNumber: Int) -> UIImage {
        let fileName = "\(imageNumber)"
        let uniquePath = tmp.stringByAppendingPathComponent(fileName)
        var image:UIImage
        
        if NSFileManager.defaultManager().fileExistsAtPath(uniquePath) {
            image = UIImage(contentsOfFile: uniquePath)!
        } else {
            self.cacheImage(imageNumber)
            image = UIImage(contentsOfFile: uniquePath)!
        }
        return image
    }

}
