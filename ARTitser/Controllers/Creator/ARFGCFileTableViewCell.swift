//
//  ARFGCFileTableViewCell.swift
//  ARFollow
//
//  Created by Julius Abarra on 27/01/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit

class ARFGCFileTableViewCell: UITableViewCell {

    @IBOutlet var fileImage: UIImageView!
    @IBOutlet var fileNameLabel: UILabel!
    @IBOutlet var fileModifiedDateLabel: UILabel!
    @IBOutlet var fileSizeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
}
