//
//  ARFGAClassUserSelectionTableViewCell.swift
//  ARFollow
//
//  Created by Julius Abarra on 08/12/2017.
//  Copyright © 2017 exZeptional. All rights reserved.
//

import UIKit

class ARFGAClassUserSelectionTableViewCell: UITableViewCell {
    
    @IBOutlet var selectionStatusImage: UIImageView!
    @IBOutlet var userImage: UIImageView!
    @IBOutlet var userNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
