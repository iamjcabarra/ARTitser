//
//  ARFGCGameTableViewCell.swift
//  ARFollow
//
//  Created by Julius Abarra on 29/01/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit

class ARFGCGameTableViewCell: UITableViewCell {
    
    @IBOutlet var gameImage: UIImageView!
    @IBOutlet var gameSecurityStatusImage: UIImageView!
    @IBOutlet var gameNameLabel: UILabel!
    @IBOutlet var gameDiscussionLabel: UILabel!
    @IBOutlet var gamePointsLabel: UILabel!
    @IBOutlet var gameActPointsLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
