//
//  FeedItem.swift
//  ExchangeAGram
//
//  Created by Paul Cashman on 1/6/15.
//  Copyright (c) 2015 Paul Cashman. All rights reserved.
//

import Foundation
import CoreData

@objc (FeedItem)

class FeedItem: NSManagedObject {

    @NSManaged var caption: String
    @NSManaged var image: NSData
    @NSManaged var thumbnail: NSData

}
