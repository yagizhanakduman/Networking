//
//  StarshipDetailTableViewCell.swift
//  NetworkingDemo
//
//  Created by YAGIZHAN AKDUMAN on 5.11.2020.
//  Copyright © 2020 YAGIZHAN AKDUMAN. All rights reserved.
//

import UIKit

// MARK: Starship Detail Table View Cell
final class StarshipDetailTableViewCell: UITableViewCell, Reusable, NibLoadable {
    
    @IBOutlet weak var infoLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configureCell(text: String) {
        infoLabel.text = text
    }
    
}
