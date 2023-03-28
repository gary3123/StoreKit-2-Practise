//
//  ProductTableViewCell.swift
//  Store-Kit2_Practise
//
//  Created by Gary on 2023/3/27.
//

import UIKit

class ProductTableViewCell: UITableViewCell {

    @IBOutlet weak var label: UILabel?
    
    static let identifier = "ProductTableViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
