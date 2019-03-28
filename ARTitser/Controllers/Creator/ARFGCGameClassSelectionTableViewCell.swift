//
//  ARFGCGameClassSelectionTableViewCell.swift
//  ARFollow
//
//  Created by Julius Abarra on 04/02/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit

class ARFGCGameClassSelectionTableViewCell: UITableViewCell {
    
    @IBOutlet var selectionStatusImage: UIImageView!
    @IBOutlet var classImage: UIImageView!
    @IBOutlet var classCodeLabel: UILabel!
    @IBOutlet var classDescriptionLabel: UILabel!
    @IBOutlet var classScheduleLabel: UILabel!
    @IBOutlet var classSizeLabel: UILabel!
    @IBOutlet var actClassSizeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
