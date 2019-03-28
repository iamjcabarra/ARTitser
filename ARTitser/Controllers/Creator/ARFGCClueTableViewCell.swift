//
//  ARFGCClueTableViewCell.swift
//  ARFollow
//
//  Created by Julius Abarra on 19/12/2017.
//  Copyright © 2017 exZeptional. All rights reserved.
//

import UIKit

class ARFGCClueTableViewCell: UITableViewCell {
    
    @IBOutlet var clueImage: UIImageView!
    @IBOutlet var clueTypeImage: UIImageView!
    @IBOutlet var clueLabel: UILabel!
    @IBOutlet var clueRiddleLabel: UILabel!
    @IBOutlet var cluePointsLabel: UILabel!
    @IBOutlet var clueActPointsLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
