//
//  Pin+Extensions.swift
//  Virtual Tourist
//
//  Created by Sean Williams on 03/09/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import Foundation
import CoreData
import MapKit

extension Pin: MKAnnotation {
    public var coordinate: CLLocationCoordinate2D {
        // latitude and longitude are optional NSNumbers
//        guard let latitude = latitude, let longitude = longitude else {
//            return kCLLocationCoordinate2DInvalid
//        }
        
        let latDegrees = CLLocationDegrees(latitude)
        let longDegrees = CLLocationDegrees(longitude)
        return CLLocationCoordinate2D(latitude: latDegrees, longitude: longDegrees)
        
    }
    
//    class func keyPathsForValuesAffectingCoordinate() -> Set<String> {
//        return Set<String>([ #keyPath(location.latitude), #keyPath(location.longitude) ])
//    }
}
