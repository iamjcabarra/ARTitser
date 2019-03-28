//
//  ARFGCClueTypeSelectionTableViewCell.swift
//  ARFollow
//
//  Created by Julius Abarra on 21/12/2017.
//  Copyright © 2017 exZeptional. All rights reserved.
//

import UIKit

class ARFGCClueTypeSelectionTableViewCell: UITableViewCell {
    
    @IBOutlet var clueTypeImage: UIImageView!
    @IBOutlet var clueTypeTitleLabel: UILabel!
    @IBOutlet var clueTypeDescriptionLabel: UILabel!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
