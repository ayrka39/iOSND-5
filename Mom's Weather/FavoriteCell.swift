//
//  FavoriteCell.swift
//  Mom's Weather
//
//  Created by David on 12/7/16.
//  Copyright © 2016 David. All rights reserved.
//

import UIKit

class FavoriteCell: UITableViewCell {

	
	@IBOutlet weak var favoriteLabel: UILabel!
	@IBOutlet weak var deleteButton: UIButton!
	
	var tapAction: ((FavoriteCell) -> Void)?
	
	func configureCell(favorite: Favorite) {
		guard let place = favorite.place else {
			return
		}
		favoriteLabel.text = "\(place)"
	}
	
	@IBAction func deleteClicked(_ sender: Any) {
		tapAction?(self)
	}
	

}


