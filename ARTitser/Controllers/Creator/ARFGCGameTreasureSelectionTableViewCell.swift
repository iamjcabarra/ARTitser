//
//  ARFGCGameTreasureSelectionTableViewCell.swift
//  ARFollow
//
//  Created by Julius Abarra on 03/02/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit

class ARFGCGameTreasureSelectionTableViewCell: UITableViewCell {
    
    @IBOutlet var statusSelectionImage: UIImageView!
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
