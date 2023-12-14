//
//  Origin.swift
//  autoMapping
//
//  Created by Stefano di Terlizzi on 15/07/23.
//

import Foundation
import SceneKit

class Origin: SCNNode {
  
  // see: https://developer.apple.com/documentation/arkit/arsessionconfiguration/worldalignment/gravityandheading
  // if ar session configured with gravity and heading, then +x is east, +y is up, +z is south
  
  private enum Axis {
    case x, y, z
    
    var normal: simd_float3 {
      switch self {
      case .x: return simd_float3(1, 0, 0)
      case .y: return simd_float3(0, 1, 0)
      case .z: return simd_float3(0, 0, 1)
      }
    }
  }
  
  // TODO: Set pivot to origin and redo tranforms, it'll make it easier to place additional nodes
  
  init(length: CGFloat = 1.0, radiusRatio ratio: CGFloat = 0.04, color: (x: UIColor, y: UIColor, z: UIColor, origin: UIColor) = (.blue, .green, .red, .cyan)) {
   
    // x-axis
    let xAxis = SCNCylinder(radius: length*ratio, height: length)
    xAxis.firstMaterial?.diffuse.contents = color.x
    let xAxisNode = SCNNode(geometry: xAxis)
    // by default the middle of the cylinder will be at the origin aligned to the y-axis
    // need to spin around to align with respective axes and shift position so they start at the origin
    xAxisNode.simdWorldOrientation = simd_quatf.init(angle: .pi/2, axis: Axis.z.normal)
    xAxisNode.simdWorldPosition = simd_float1(length)/2 * Axis.x.normal
    
    // y-axis
    let yAxis = SCNCylinder(radius: length*ratio, height: length)
    yAxis.firstMaterial?.diffuse.contents = color.y
    let yAxisNode = SCNNode(geometry: yAxis)
    yAxisNode.simdWorldPosition = simd_float1(length)/2 * Axis.y.normal // just shift

    // z-axis
    let zAxis = SCNCylinder(radius: length*ratio, height: length)
    zAxis.firstMaterial?.diffuse.contents = color.z
    let zAxisNode = SCNNode(geometry: zAxis)
    zAxisNode.simdWorldOrientation = simd_quatf(angle: -.pi/2, axis: Axis.x.normal)
    zAxisNode.simdWorldPosition = simd_float1(length)/2 * Axis.z.normal

    // dot at origin
    let origin = SCNSphere(radius: length*ratio)
    origin.firstMaterial?.diffuse.contents = color.origin
    let originNode = SCNNode(geometry: origin)
    
    super.init()
    
    self.addChildNode(originNode)
    self.addChildNode(xAxisNode)
    self.addChildNode(yAxisNode)
    self.addChildNode(zAxisNode)
    
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
}

