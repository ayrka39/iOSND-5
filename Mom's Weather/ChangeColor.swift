//
//  ChangeColor.swift
//  Mom's Weather
//
//  Created by David on 11/18/16.
//  Copyright © 2016 David. All rights reserved.
//

import Foundation
import UIKit

class ChangeColor: UIViewController {
	
	static let shared = ChangeColor()
	
	func viewColor(icon: UIImage, view: UIView) {
		
		switch icon {
		case #imageLiteral(resourceName: "01d"), #imageLiteral(resourceName: "01n"):
			
			view.backgroundColor = UIColor(red: 102/255, green: 153/255, blue: 204/255, alpha: 1.0)
			
		case #imageLiteral(resourceName: "02d"), #imageLiteral(resourceName: "02n"):
			view.backgroundColor = UIColor(red: 135/255, green: 206/255, blue: 250/255, alpha: 1.0)
			
		case #imageLiteral(resourceName: "03d"), #imageLiteral(resourceName: "03n"), #imageLiteral(resourceName: "04d"), #imageLiteral(resourceName: "04n"):
			view.backgroundColor = UIColor(red: 153/255, green: 186/255, blue: 221/255, alpha: 1.0)
			
		case #imageLiteral(resourceName: "09d"), #imageLiteral(resourceName: "09n"), #imageLiteral(resourceName: "10d"), #imageLiteral(resourceName: "10n"):
			view.backgroundColor = UIColor(red: 176/255, green: 224/255, blue: 230/255, alpha: 1.0)
			
		case #imageLiteral(resourceName: "13d"), #imageLiteral(resourceName: "13n"):
			view.backgroundColor = UIColor(red: 244/255, green: 255/255, blue: 255/255, alpha: 1.0)
			
		default:
			view.backgroundColor = UIColor(red: 245/255, green: 245/255, blue: 220/255, alpha: 1.0)
			
		}
	}
	
	func viewGradient(view: UIView, start: Double, end: Double) {
		
		let gradient = CAGradientLayer()
		let bgColor = view.layer.backgroundColor
		gradient.frame = view.bounds
		gradient.startPoint = CGPoint(x: 0.0, y: start)
		gradient.endPoint = CGPoint(x: 0.0, y: end)
		gradient.colors = [UIColor.white.cgColor, bgColor!]
		view.layer.insertSublayer(gradient, at: 0)
		
	}
	

	
}
