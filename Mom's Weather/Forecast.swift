//
//  Forecast.swift
//  Mom's Weather
//
//  Created by David on 11/6/16.
//  Copyright © 2016 David. All rights reserved.
//

import Foundation
import UIKit

class Forecast {
	
	var city: String?
	var hours: String?
	var minTemp: Int?
	var maxTemp: Int?
	var icon: String?
	var date: String?
	
	init(city: String, hours: String, minTemp: Int, maxTemp: Int, icon: String, date: String) {
		
		self.city = city
		self.hours = hours
		self.minTemp = minTemp
		self.maxTemp = maxTemp
		self.icon = icon
		self.date = date
	}
	
}

