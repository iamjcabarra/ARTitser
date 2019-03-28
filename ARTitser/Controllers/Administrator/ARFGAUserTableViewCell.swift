//
//  ARFGAUserTableViewCell.swift
//  ARFollow
//
//  Created by Julius Abarra on 23/10/2017.
//  Copyright © 2017 exZeptional. All rights reserved.
//

import UIKit

class ARFGAUserTableViewCell: UITableViewCell {
    
    @IBOutlet var userImage: UIImageView!
    @IBOutlet var userTypeImage: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var extraLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
