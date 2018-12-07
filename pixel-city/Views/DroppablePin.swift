//
//  DroppablePin.swift
//  pixel-city
//
//  Created by Ahmed Mohamed El-Desouky on 12/5/18.
//  Copyright © 2018 Ahmed Mohamed El-Desouky. All rights reserved.
//

import UIKit
import MapKit

class DroppablePin: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var identifire: String
    
    init(coordinate: CLLocationCoordinate2D, identifire:String) {
        self.coordinate = coordinate
        self.identifire = identifire
        super.init()
    }
}
