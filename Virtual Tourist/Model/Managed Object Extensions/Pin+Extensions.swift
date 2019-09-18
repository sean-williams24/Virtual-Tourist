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
        
        let latDegrees = CLLocationDegrees(latitude)
        let longDegrees = CLLocationDegrees(longitude)
        return CLLocationCoordinate2D(latitude: latDegrees, longitude: longDegrees)
    }
}
