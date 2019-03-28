//
//  ARFGPGameClueChoiceTableViewCell.swift
//  ARFollow
//
//  Created by Julius Abarra on 10/03/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit

class ARFGPGameClueChoiceTableViewCell: UITableViewCell {

    @IBOutlet var backView: UIView!
    @IBOutlet var letterChoiceLabel: UILabel!
    @IBOutlet var choiceLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
