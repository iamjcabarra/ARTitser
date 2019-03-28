//
//  ARFGACourseTableViewCell.swift
//  ARFollow
//
//  Created by Julius Abarra on 23/10/2017.
//  Copyright © 2017 exZeptional. All rights reserved.
//

import UIKit

class ARFGACourseTableViewCell: UITableViewCell {
    
    @IBOutlet var courseImage: UIImageView!
    @IBOutlet var courseCodeLabel: UILabel!
    @IBOutlet var courseTitleLabel: UILabel!
    @IBOutlet var courseDescriptionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
