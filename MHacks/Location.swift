//
//  Location.swift
//  MHacks
//
//  Created by Manav Gabhawala on 12/22/15.
//  Copyright © 2015 MHacks. All rights reserved.
//

import Foundation
import CoreLocation

// This is intentionally a class, we don't duplicate copies of this everywhere, just immutable references.
@objc final class Location : NSObject {
	
	let ID: Int
	let name: String
	let coreLocation: CLLocation
	init(ID: Int, name: String, coreLocation: CLLocation) {
		self.ID = ID
		self.name = name
		self.coreLocation = coreLocation
	}
	private static let latitudeKey = "latitude"
	private static let longitudeKey = "longitude"
	private static let nameKey = "name"
	private static let idKey = "id"
	
	convenience init?(serialized: Serialized) {
		guard let latitudeStr = serialized[Location.latitudeKey] as? String, let latitude = Double(latitudeStr), let longitudeStr = serialized[Location.longitudeKey] as? String, let longitude = Double(longitudeStr), let id = serialized.intValueForKey(Location.idKey), let locationName = serialized[Location.nameKey] as? String
		else {
			return nil
		}
		self.init(ID: id, name: locationName, coreLocation: CLLocation(latitude: latitude, longitude: longitude))
	}
}
extension Location : JSONCreateable {
		
	@objc func encodeWithCoder(aCoder: NSCoder) {
		aCoder.encode(ID, forKey: Location.idKey)
		aCoder.encode("\(coreLocation.coordinate.latitude)", forKey: Location.latitudeKey)
		aCoder.encode("\(coreLocation.coordinate.longitude)", forKey: Location.longitudeKey)
		aCoder.encode(name, forKey: Location.nameKey)
	}
	@objc convenience init?(coder aDecoder: NSCoder) {
		self.init(serialized: Serialized(coder: aDecoder))
	}
}

func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
	return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
}

func ==(lhs: Location, rhs: Location) -> Bool {
	return lhs.ID == rhs.ID && lhs.name == rhs.name && lhs.coreLocation.coordinate == rhs.coreLocation.coordinate
}
