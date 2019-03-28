//
//  ARFGCTreasureTableViewCell.swift
//  ARFollow
//
//  Created by Julius Abarra on 25/01/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit

class ARFGCTreasureTableViewCell: UITableViewCell {
    
    @IBOutlet var treasureImage: UIImageView!
    @IBOutlet var treasureNameLabel: UILabel!
    @IBOutlet var treasureDescriptionLabel: UILabel!
    @IBOutlet var treasurePointsLabel: UILabel!
    @IBOutlet var treasureActPointsLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
