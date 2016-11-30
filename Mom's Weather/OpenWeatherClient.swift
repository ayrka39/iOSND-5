//
//  OpenWeatherClient.swift
//  Mom's Weather
//
//  Created by David on 11/1/16.
//  Copyright © 2016 David. All rights reserved.
//

import UIKit
import CoreLocation

class OpenWeatherClient {
	
	static let shared = OpenWeatherClient()
	
	let keys = OpenWeatherParmeterKeys.self
	let values = OpenWeatherParameterValues.self
	let responseKeys = OpenWeatherResponseKeys.self
	let location = Location.shared
	var currentWeatherData: CurrentWeather?
	var forecastData: [Forecast]?
	
	
	// Mark: Get necessary data
	
		
	func getForecastData(_ completionForForecast: @escaping (_ forecastData: [Forecast]?, _ error: NSError?) -> Void) {
		
		forecastData = [Forecast]()
		taskForGetMethod(kind: "forecast") { (results, error) in
			
			guard error == nil else {
				return
			}
			
			guard let cityDict = results?["city"] as? Dict,
				let listArr = results?["list"] as? [Dict] else {
					return
			}
			let place = cityDict["name"] as AnyObject
			for listDict in listArr  {
				guard let mainDict = listDict["main"] as? Dict,
					let weatherArr = listDict["weather"] as? [Dict],
					let dateDbl = listDict["dt"] as? Double,
					let timeStr = listDict["dt_txt"] as? String else {
						return
				}
				let hours = self.extractHours(timeText: timeStr)
				let date = self.extractDate(dateNumber: dateDbl)
				let min_Temp = mainDict["temp_min"] as AnyObject
				let max_Temp = mainDict["temp_max"] as AnyObject
				let minTemp = self.convertKtoC(kelvin: min_Temp as! Double)
				let maxTemp = self.convertKtoC(kelvin: max_Temp as! Double)
				let icon = weatherArr[0]["icon"] as AnyObject
				
				let forecast = Forecast(city: "\(place)", hours: "\(hours)", minTemp: minTemp, maxTemp: maxTemp, icon: "\(icon)", date: "\(date)")
				self.forecastData?.append(forecast)
			}
			DispatchQueue.main.async {
				completionForForecast(self.forecastData, nil)
			}
		}
	
	}
	
	func getCurrentWeatherData(_ completionForCurrentWeather: @escaping (_ currentData: CurrentWeather?, _ error: NSError?) -> Void) {
		
		
		taskForGetMethod(kind: "current") { (results, error) in
			
			guard error == nil else {
				return
			}
			guard let weatherArr = results?[self.responseKeys.weather] as? [Dict],
					let mainDict = results?[self.responseKeys.dataMain] as? Dict,
					let windDict = results?[self.responseKeys.wind] as? Dict else {
				return
			}
			let place = (results?[self.responseKeys.cityName] as AnyObject) as! String
			let _temp = mainDict[self.responseKeys.temperature] as AnyObject
			let temp = self.convertKtoC(kelvin: _temp as! Double)
			let _windSpeed = windDict[self.responseKeys.windSpeed] as AnyObject
			let windSpeed = String(format: "%.0f", _windSpeed as! Double)
			let icon = (weatherArr[0][self.responseKeys.weatherIcon] as AnyObject) as! String
			
			let currentWeather = CurrentWeather(city: "\(place)", temp: temp, windSpeed: "\(windSpeed)", icon: "\(icon)")
			
			self.currentWeatherData = currentWeather
			DispatchQueue.main.async {
				completionForCurrentWeather(self.currentWeatherData, nil)
				
			}
		}

	}
	
			
	// Mark: Task for GET Method
	func taskForGetMethod(kind: String, completionHandlerForGet: @escaping (_ results: AnyObject?, _ error : NSError?) -> Void) {
		
		let url = getOpenWeatherURL(kind: kind)
		let request = NSMutableURLRequest(url: url)
		let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
			
			guard error == nil else {
				print("an error with request: \(error)")
				return
			}
			guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
				print("request returned a status code other than 2xx")
				return
			}
			guard let data = data else {
				print("no data was returned")
				return
			}
			self.parseData(data, completionHandlerForParseData: completionHandlerForGet)
		}
		task.resume()
	}
	
	// Mark: Parse data
	fileprivate func parseData(_ data: Data, completionHandlerForParseData: (_ result: AnyObject?, _ error: NSError?) -> Void) {
		
		var jsonResult: AnyObject?
		
		do {
			jsonResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject?
		} catch {
			fatalError("could not parse the data")
		}
		completionHandlerForParseData(jsonResult, nil)
	}
	
	// Mark: Get OpenWeather URL from parameters
	fileprivate func getOpenWeatherURL(kind: String) -> URL {
		
		let currentLocation = CLLocationManager().location
					
		let parameters: Dict = [
			keys.latitude: currentLocation!.coordinate.latitude as AnyObject,
			keys.longitude: currentLocation!.coordinate.longitude as AnyObject,
			keys.APIKey: values.APIKey as AnyObject
		]
		
		var components = URLComponents()
		components.scheme = OpenWeatherBase.APIScheme
		components.host = OpenWeatherBase.APIHost
		switch kind {
		case "current":
			components.path = OpenWeatherBase.APIPath
		case "forecast":
			components.path = OpenWeatherBase.ForecastPath
		default:
			break
		}
		components.queryItems = [URLQueryItem]()
		
		for (key, value) in parameters {
			let queryItem = URLQueryItem(name: key, value: "\(value)")
			components.queryItems!.append(queryItem)
		}

		return components.url!
	}
	
	// Mark: Convert Kevin value to Celcius
	func convertKtoC(kelvin: Double) -> Int {
		
		var celcius: String!

		let kToCFormular = Double(kelvin - 273.15)
		celcius = String(format: "%.0f", kToCFormular)
		
		return Int(celcius)!
	}
	
	// get time value from parsed data
	func extractHours(timeText: String) -> String {
		
		let fullText = timeText
		let space = fullText.characters.index(of: " ")
		let startCharacter = fullText.characters.index(after: space!)
		let endCharacter = fullText.characters.index(of: ":")
		let hour = fullText.substring(with: startCharacter..<endCharacter!)
		
		return hour
	}
	
	// get a formatted date value from parsed data
	func extractDate(dateNumber: Double) -> String {
		let convertedDate = Date(timeIntervalSince1970: dateNumber)
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "EEE, MMM dd"
		let date = dateFormatter.string(from: convertedDate)
		return date
		
	}
}

