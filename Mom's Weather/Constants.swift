//
//  Constants.swift
//  Mom's Weather
//
//  Created by David on 11/1/16.
//  Copyright © 2016 David. All rights reserved.
//

import UIKit

// Mark: Constants

extension OpenWeatherClient {
	// Mark: OpenWeatherBase
	
	struct OpenWeatherBase {
		static let APIScheme = "http"
		static let APIHost = "api.openweathermap.org"
		static let APIPath = "/data/2.5/weather"
		static let ForecastPath = "/data/2.5/forecast"
		static let DailyPath = "/data/2.5/forecast/daily"
	}
	
	// Mark: OpenWeather Parrameter Keys
	struct OpenWeatherParmeterKeys {
		static let latitude = "lat"
		static let longitude = "lon"
		static let APIKey = "appid"
	}
	
	// Mark: OpenWeather Parameter Values
	struct OpenWeatherParameterValues {
		static let APIKey = "yourApiKey"
	}
	
	// Mark: OpenWeather Response Keys
	struct OpenWeatherResponseKeys {
		static let coordinate = "coord"
		static let longitude = "lon"
		static let latitude = "lat"
		static let weather = "weather"
		static let weatherID = "id" // Weather condition ID
		static let weatherMain = "main" // Group of weather parameters
		static let weatherDescription = "description" // Weather condition within the group
		static let weatherIcon = "icon"
		static let dataList = "list"
		static let dataMain = "main"
		static let temperature = "temp"
		static let minimumTemp = "temp_min"
		static let maximumTemp = "temp_max"
		static let wind = "wind"
		static let windSpeed = "speed"
		static let clouds = "clouds"
		static let dataTime = "dt" // Time of data calculation, unix, UTC
		static let dataTimeText = "dt_txt"
		static let cityName = "name"
		
	}
	
}

// Mark: TypeAlias

typealias Dict = [String: AnyObject]
