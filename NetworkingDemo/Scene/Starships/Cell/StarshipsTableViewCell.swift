//
//  StarshipsTableViewCell.swift
//  NetworkingDemo
//
//  Created by YAGIZHAN AKDUMAN on 3.11.2020.
//  Copyright © 2020 YAGIZHAN AKDUMAN. All rights reserved.
//

import UIKit

// MARK: Starships Table View Cell
final class StarshipsTableViewCell: UITableViewCell, NibLoadable, Reusable {
    
    @IBOutlet weak var starshipNameLabel: UILabel! {
        willSet {
            newValue.font = UIFont.boldSystemFont(ofSize: 17)
        }
    }
    
    @IBOutlet weak var starshipModelLabel: UILabel! {
        willSet {
            newValue.font = UIFont.italicSystemFont(ofSize: 15)
            newValue.textColor = .lightGray
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configureCell(starship: StarshipModel) {
        starshipNameLabel.text = starship.name ?? ""
        starshipModelLabel.text = starship.model ?? ""
    }
    
}
