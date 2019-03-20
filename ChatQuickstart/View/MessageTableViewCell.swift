//
//  MessageTableViewCell.swift
//  ChatQuickstart
//
//  Created by Vidhya Sri Soundararajan on 25/02/19.
//  Copyright © 2019 Twilio, Inc. All rights reserved.
//

import UIKit

class MessageTableViewCell: UITableViewCell {

    @IBOutlet weak var messageTextLbl: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
