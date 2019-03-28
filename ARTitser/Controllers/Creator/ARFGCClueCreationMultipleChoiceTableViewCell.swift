//
//  ARFGCClueCreationMultipleChoiceTableViewCell.swift
//  ARFollow
//
//  Created by Julius Abarra on 07/01/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit

class ARFGCClueCreationMultipleChoiceTableViewCell: UITableViewCell {
    
    @IBOutlet var isCorrectImage: UIImageView!
    @IBOutlet var isCorrectButton: UIButton!
    @IBOutlet var choiceStatementTextField: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
}

