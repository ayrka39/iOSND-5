//
//  ForecastData.swift
//  Mom's Weather
//
//  Created by David on 12/14/16.
//  Copyright © 2016 David. All rights reserved.
//

import Foundation
import UIKit

class ForecastWeatherData  {
	var city: String?
	var date: Date?
	var minTemp: Int?
	var maxTemp: Int?
	var icon: String?
	var hours: String?
	
	init(city: String, date: Date, minTemp: Int, maxTemp: Int, icon: String, hours: String) {
		
		self.city = city
		self.date = date
		self.minTemp = minTemp
		self.maxTemp = maxTemp
		self.icon = icon
		self.hours = hours
		
	}
	
}

