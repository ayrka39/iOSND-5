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
		
		if hourly.hours == "00" {
			hourLabel.text = dayOfWeek(date: hourly.date!)
		} else {
			hourLabel.text = hourly.hours
		}
		guard let icon = hourly.icon else {
			return
		}
		iconImageView.image = UIImage(named: icon)
		tempLabel.text = "\(hourly.minTemp)°"
		
	}
	
	func dayOfWeek(date: NSDate) -> String {
		
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "EEE"
		let forecastDate = dateFormatter.string(from: date as Date)
		return forecastDate
	}
}
