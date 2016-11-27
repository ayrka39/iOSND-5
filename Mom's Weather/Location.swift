//
//  Location.swift
//  Mom's Weather
//
//  Created by David on 11/10/16.
//  Copyright © 2016 David. All rights reserved.
//

import CoreLocation

class Location {
	static let shared = Location()
	private init() {}
	
	var latitude: Double!
	var longitude: Double!
}
