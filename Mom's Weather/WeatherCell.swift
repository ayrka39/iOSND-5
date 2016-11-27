//
//  WeatherCell.swift
//  Mom's Weather
//
//  Created by David on 11/17/16.
//  Copyright © 2016 David. All rights reserved.
//

import Foundation
import UIKit

class WeatherCell: UICollectionViewCell {
	
	@IBOutlet weak var hourLabel: UILabel!
	@IBOutlet weak var iconImageView: UIImageView!
	@IBOutlet weak var tempLabel: UILabel!
	@IBOutlet weak var hourView: UIView!
	
	func configureCollectionViewCell(hourly: Forecast) {
		
		hourLabel.text = hourly.hours
		iconImageView.image = UIImage(named:hourly.icon!)
		tempLabel.text = "\(hourly.minTemp!)°"
		
	}
}
