//
//  ARFGAClassPlayerTableViewCell.swift
//  ARFollow
//
//  Created by Julius Abarra on 07/12/2017.
//  Copyright © 2017 exZeptional. All rights reserved.
//

import UIKit

class ARFGAClassPlayerTableViewCell: UITableViewCell {
    
    @IBOutlet var playerImage: UIImageView!
    @IBOutlet var playerNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
