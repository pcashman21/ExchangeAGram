//
//  FilterCell.swift
//  ExchangeAGram
//
//  Created by Paul Cashman on 1/6/15.
//  Copyright (c) 2015 Paul Cashman. All rights reserved.
//

import UIKit

class FilterCell: UICollectionViewCell {
    
    // To get our image to appear over the entire view, we add the variable, custom initializer,
    // imageView, and required init below.
    
    var imageView: UIImageView!
    
    // "Override" is added because without it there is an error.  Double-click on the 
    // correction to the error that is supplied along with the error message.
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
        // contentView is created automatically as part of this initialization.
        contentView.addSubview(imageView)
    }
    
    // As with "override" above, this code is added by clicking on the error message.  The 
    // error here was that the above code has to be made NS compliant.  The class instructor 
    // said the reason for this is obscure.  It just has to be so.
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
