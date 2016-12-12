//
//  OpenWeatherClient.swift
//  Mom's Weather
//
//  Created by David on 11/1/16.
//  Copyright © 2016 David. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

class OpenWeatherClient {
	
	static let shared = OpenWeatherClient()
	
	let keys = OpenWeatherParmeterKeys.self
	let values = OpenWeatherParameterValues.self
	let responseKeys = OpenWeatherResponseKeys.self
	var currentData: CurrentWeather?
	var forecastData: [Forecast]?
	var location: [Locations]?
	
	// Mark: Get necessary data
	
		
	func getForecastData() {

		forecastData = [Forecast(context: CoreDataStack.shared.context)]
		
		taskForGetMethod(kind: "forecast") { (results, error) in
			
			guard error == nil else {
				return
			}
			
			guard let cityDict = results?["city"] as? Dict,
				let listArr = results?["list"] as? [Dict] else {
				return
			}
			
			let place = (cityDict["name"] as AnyObject) as! String
			
			for listDict in listArr  {
				guard let dateDle = listDict["dt"] as? Double,
					let mainDict = listDict["main"] as? Dict,
					let weatherArr = listDict["weather"] as? [Dict],
					let timeStr = listDict["dt_txt"] as? String else {
						return
				}
				
				let date = (Date(timeIntervalSince1970: dateDle)) as NSDate
				let min_Temp = mainDict["temp_min"] as AnyObject
				let max_Temp = mainDict["temp_max"] as AnyObject
				let minTemp = self.convertKtoC(kelvin: min_Temp as! Double)
				let maxTemp = self.convertKtoC(kelvin: max_Temp as! Double)
				let icon = weatherArr[0]["icon"] as! String
				let hours = self.extractHours(timeText: timeStr)
				
				let forecast = Forecast(context: CoreDataStack.shared.context)
				forecast.city = place
				forecast.date = date
				forecast.minTemp = Int16(minTemp)
				forecast.maxTemp = Int16(maxTemp)
				forecast.icon = icon 
				forecast.hours = hours
				self.forecastData!.append(forecast)
				
			}
//			DispatchQueue.main.async {
				CoreDataStack.shared.saveContext()
//			}
		}
	}
	
	func getCurrentWeatherData() {
		
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
			
			self.currentData = CurrentWeather(context: CoreDataStack.shared.context)
			self.currentData?.city = place
			self.currentData?.temp = Int16(temp)
			self.currentData?.windSpeed = windSpeed
			self.currentData?.icon = icon
			
			DispatchQueue.main.async {
				CoreDataStack.shared.saveContext()
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
		var parameters: Dict
		// From user location
		do {
			location = try CoreDataStack.shared.context.fetch(Locations.fetch)
			
			print("saved? \(location?.last?.latitude)")
		} catch {
			fatalError("no info")
		}
		if location?.last?.latitude == nil {
			
			let currentLocation = CLLocationManager().location?.coordinate
			print("current: \(currentLocation)")
			parameters = [
				keys.latitude: currentLocation?.latitude as AnyObject,
				keys.longitude: currentLocation?.longitude as AnyObject,
				keys.APIKey: values.APIKey as AnyObject
			]
			
			// From selected or saved location
		} else {
			let latitude = location?.last?.latitude
			let longitude = location?.last?.longitude
			parameters = [
				keys.latitude: latitude as AnyObject,
				keys.longitude: longitude as AnyObject,
				keys.APIKey: values.APIKey as AnyObject
			]

		}
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
		print("url \(components.url!)")
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

}

