//
//  SearchCell.swift
//  Mom's Weather
//
//  Created by David on 11/28/16.
//  Copyright © 2016 David. All rights reserved.
//

import UIKit

class SearchCell: UITableViewCell {

	@IBOutlet weak var placeLabel: UILabel!
	@IBOutlet weak var favoriteButton: UIButton!
	
	var tapAction: ((SearchCell) -> Void)?

	@IBAction func favoriteClicked(_ sender: Any) {
		tapAction?(self)
	}
	
}
