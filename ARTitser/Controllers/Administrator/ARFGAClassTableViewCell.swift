//
//  ARFGAClassTableViewCell.swift
//  ARFollow
//
//  Created by Julius Abarra on 06/12/2017.
//  Copyright © 2017 exZeptional. All rights reserved.
//

import UIKit

class ARFGAClassTableViewCell: UITableViewCell {
    
    @IBOutlet var classImage: UIImageView!
    @IBOutlet var classCodeLabel: UILabel!
    @IBOutlet var classScheduleLabel: UILabel!
    @IBOutlet var classDescriptionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
