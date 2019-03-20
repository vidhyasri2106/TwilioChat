//
//  Helpers.swift
//  ChatQuickstart
//
//  Created by Vidhya Sri Soundararajan on 26/02/19.
//  Copyright © 2019 Twilio, Inc. All rights reserved.
//

import Foundation
import UIKit

func heightForView(text:String, font:UIFont, width:CGFloat) -> CGFloat{
    let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
    label.numberOfLines = 0
    label.lineBreakMode = NSLineBreakMode.byWordWrapping
    label.font = font
    label.text = text
    
    label.sizeToFit()
    return label.frame.height
}
