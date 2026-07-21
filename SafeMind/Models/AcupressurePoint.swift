//
//  AcupressurePoint.swift
//  SafeMind
//
//  Created by Anshuman Nitnaware on 21/06/26.
//

import Foundation
import SceneKit

struct AcupressurePoint: Identifiable {
    let id = UUID()
    let name: String
    let location: String
    let description: String
    let caution: String?
    let scenePosition: SCNVector3
    let cameraZoomPosition: SCNVector3
}
