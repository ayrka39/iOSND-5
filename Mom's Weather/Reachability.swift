//
//  Reachability.swift
//  Mom's Weather
//
//  Created by David on 11/28/16.
//  Copyright © 2016 David. All rights reserved.
//

import SystemConfiguration

public class Reachability {
	
	class func isInternetAvailable() -> Bool {
		
		var zeroAddress = sockaddr_in()
		zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
		zeroAddress.sin_family = sa_family_t(AF_INET)
		
		let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
			$0.withMemoryRebound(to: sockaddr.self, capacity: 1) { zeroAddress in
				SCNetworkReachabilityCreateWithAddress(nil, zeroAddress)
			}
		}
		
		var flags = SCNetworkReachabilityFlags()
		guard SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) else {
			return false
		}
		
		let isReachable = flags.rawValue & UInt32(kSCNetworkFlagsReachable) != 0
		let needsConnection = flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired) != 0
		
		return isReachable && !needsConnection
	}

}
