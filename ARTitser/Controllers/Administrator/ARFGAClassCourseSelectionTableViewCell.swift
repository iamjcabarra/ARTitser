//
//  ARFGAClassCourseSelectionTableViewCell.swift
//  ARFollow
//
//  Created by Julius Abarra on 11/12/2017.
//  Copyright © 2017 exZeptional. All rights reserved.
//

import UIKit

class ARFGAClassCourseSelectionTableViewCell: UITableViewCell {
    
    @IBOutlet var statusSelectionImage: UIImageView!
    @IBOutlet var courseImage: UIImageView!
    @IBOutlet var courseCodeLabel: UILabel!
    @IBOutlet var courseTitleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
