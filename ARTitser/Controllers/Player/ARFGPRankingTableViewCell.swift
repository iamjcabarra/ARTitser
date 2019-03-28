//
//  ARFGPRankingTableViewCell.swift
//  ARFollow
//
//  Created by Julius Abarra on 14/02/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit

class ARFGPRankingTableViewCell: UITableViewCell {
    
    @IBOutlet var backView: UIView!
    @IBOutlet var rankView: UIView!
    @IBOutlet var rankLabel: UILabel!
    @IBOutlet var playerImage: UIImageView!
    @IBOutlet var playerNameLabel: UILabel!
    @IBOutlet var pointsLabel: UILabel!
    @IBOutlet var levelLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
