//
//  CurrentWeather.swift
//  Mom's Weather
//
//  Created by David on 11/8/16.
//  Copyright © 2016 David. All rights reserved.
//

import Foundation
import UIKit

class CurrentWeather: NSObject {
	var city: String?
	var temp: Int?
	var windSpeed: String?
	var icon: String?

	
	init(city: String, temp: Int, windSpeed: String, icon: String) {
		
		self.city = city
		self.temp = temp
		self.windSpeed = windSpeed
		self.icon = icon
		
	}
	
}

