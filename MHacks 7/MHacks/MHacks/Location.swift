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
	
	let ID: String
	let name: String
	let coreLocation: CLLocation
	init(ID: String, name: String, coreLocation: CLLocation) {
		self.ID = ID
		self.name = name
		self.coreLocation = coreLocation
	}
	private static let latitudeKey = "latitude"
	private static let longitudeKey = "longitude"
	private static let nameKey = "name"
	private static let idKey = "id"
	
	convenience init?(serialized: Serialized) {
		
		guard let latitude = Double(serialized[Location.latitudeKey] as? String ?? ""), let longitude = Double(serialized[Location.longitudeKey] as? String ?? ""), let id : Any = serialized[Location.idKey] as? Int ?? serialized[Location.idKey] as? String, let locationName = serialized[Location.nameKey] as? String
			else
		{
			return nil
		}
		self.init(ID: "\(id)", name: locationName, coreLocation: CLLocation(latitude: latitude, longitude: longitude))
	}
}
extension Location : JSONCreateable {
		
	@objc func encodeWithCoder(aCoder: NSCoder) {
		aCoder.encodeObject(ID, forKey: Location.idKey)
		aCoder.encodeObject("\(coreLocation.coordinate.latitude)", forKey: Location.latitudeKey)
		aCoder.encodeObject("\(coreLocation.coordinate.longitude)", forKey: Location.longitudeKey)
		aCoder.encodeObject(name, forKey: Location.nameKey)
	}
	@objc convenience init?(coder aDecoder: NSCoder) {
		self.init(serialized: Serialized(coder: aDecoder))
	}
}

func ==(lhs: Location, rhs: Location) -> Bool
{
	return lhs.ID == rhs.ID && lhs.coreLocation == rhs.coreLocation && lhs.name == rhs.name
}