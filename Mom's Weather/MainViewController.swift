//
//  ViewController.swift
//  weatherForMom
//
//  Created by David on 10/31/16.
//  Copyright © 2016 David. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData


class MainViewController: UIViewController, CLLocationManagerDelegate {

	@IBOutlet weak var date: UILabel!
	@IBOutlet weak var place: UILabel!
	@IBOutlet weak var currentTemperature: UILabel!
	@IBOutlet weak var currentWindSpeed: UILabel!
	@IBOutlet weak var currentWeatherIcon: UIImageView!
	@IBOutlet weak var morningTemperature: UILabel!
	@IBOutlet weak var afternoonTemperature: UILabel!
	@IBOutlet weak var morningIcon: UIImageView!
	@IBOutlet weak var afternoonIcon: UIImageView!
	@IBOutlet weak var currentWeatherView: UIView!
	@IBOutlet weak var morningView: UIView!
	@IBOutlet weak var afternoonView: UIView!
	
	let locationManager = CLLocationManager()
	var currentLocation: CLLocation?
	let location = Location.shared
	let openWeatherClient = OpenWeatherClient.shared
	let changeColor = ChangeColor.shared
	let coreDataStack = CoreDataStack.shared
	
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		showCurrentDate()
		locationManagerSetting()
		
		getCurrentLocation()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		getCurrentWeatherData()
		getUpcomingData()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		locationAuthStatus()
		
	}

	func getCurrentWeatherData() {
		
		openWeatherClient.getCurrentWeatherData() { (currentWeather, error) in
			guard let currentWeather = currentWeather else {
				return
			}
			DispatchQueue.main.async { 
				self.place.text = currentWeather.city
				self.currentTemperature.text = "\(currentWeather.temp!)"
				self.currentWindSpeed.text = currentWeather.windSpeed
				self.currentWeatherIcon.image = UIImage(named: currentWeather.icon!)
				self.changeColor.viewColor(icon: self.currentWeatherIcon.image!, view: self.currentWeatherView)
				self.changeColor.viewGradient(view: self.currentWeatherView, start: 1.0, end: 0.1)
			}
			
		}
		
	}
	
	func getUpcomingData() {
		openWeatherClient.getForecastData() { (forecast, error) in
			guard let forecast = forecast else {
				return
			}
			guard let i = forecast.index(where: {$0.hours == "06"}),
					let j = forecast.index(where: {$0.hours == "09"}),
					let k = forecast.index(where: {$0.hours == "12"}),
					let m = forecast.index(where: {$0.hours == "15"}) else {
				return
			}
			
			let sixTemp = forecast[i].minTemp!
			let nineTemp = forecast[j].maxTemp!
			let noonMinTemp = forecast[k].minTemp!
			let noonMaxTemp = forecast[k].maxTemp!
			let threeMinTemp = forecast[m].minTemp!
			let threeMaxTemp = forecast[m].maxTemp!
			let afternoonMinTemp = min(noonMinTemp, threeMinTemp)
			let afternoonMaxTemp = max(noonMaxTemp, threeMaxTemp)
			let nineIcon = forecast[j].icon!
			let noonIcon = forecast[k].icon!
			var threeIcon = forecast[m].icon!
			
			DispatchQueue.main.async {
				
				if sixTemp == nineTemp {
					self.morningTemperature.text = "\(sixTemp)°"
				} else {
					let MorningMinTemp = min(sixTemp, nineTemp)
					let MorningMaxTemp = max(sixTemp, nineTemp)
					self.morningTemperature.text = "\(MorningMinTemp)° ~ \(MorningMaxTemp)°"
				}
				
				if afternoonMinTemp == afternoonMaxTemp {
					self.afternoonTemperature.text = "\(afternoonMinTemp)°"
				} else {
					self.afternoonTemperature.text = "\(afternoonMinTemp)° ~ \(afternoonMaxTemp)°"
				}
				
				self.morningIcon.image = UIImage(named: nineIcon)
				
				if noonIcon == threeIcon {
					self.afternoonIcon.image = UIImage(named: noonIcon)
				} else {
					switch threeIcon {
					case "01n":
						threeIcon = "01d"
					case "02n":
						threeIcon = "02d"
					default:
						break
					}
					self.afternoonIcon.image = UIImage(named: threeIcon)
				}
				self.changeColor.viewColor(icon: self.morningIcon.image!, view: self.morningView)
				self.changeColor.viewGradient(view: self.morningView, start: 0.1, end: 1.0)
				
				self.changeColor.viewColor(icon: self.afternoonIcon.image!, view: self.afternoonView)
				self.changeColor.viewGradient(view: self.afternoonView, start: 0.1, end: 1.0)
			}
		}		
	}
	
}



extension Locations {
	
	class var fetch: NSFetchRequest<Locations> {
		return NSFetchRequest<Locations>(entityName: "Locations")
	}
	
}
