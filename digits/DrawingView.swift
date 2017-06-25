//
//  Scribblable.swift
//  Signature
//
//  Created by harsh vishwakrama on 8/26/16.
//

import UIKit

// MARK: Scribblable protocol

protocol Scribblable{
  func beginScribble(point: CGPoint)
  func appendScribble(point: CGPoint)
  func endScribble()
  func clearScribble()
}


// MARK: Hermite interpolation implementation of line drawing from point to point

class HermiteScribbleView: UIImageView, Scribblable{
  
  @IBInspectable var lineWidth: CGFloat = 30
  @IBInspectable var borderColor: UIColor = UIColor.blue
  @IBInspectable var borderWidth: CGFloat = 1
  
  
  let hermitePath = UIBezierPath()
  var interpolationPoints = [CGPoint]()
  let backgroundLayer = CAShapeLayer()
  let drawingLayer = CAShapeLayer()
  
  override func awakeFromNib() {
    
    backgroundLayer.strokeColor = UIColor.darkGray.cgColor
    backgroundLayer.fillColor = nil
    backgroundLayer.lineWidth = lineWidth
    
    drawingLayer.strokeColor = UIColor.black.cgColor
    drawingLayer.fillColor = nil
    drawingLayer.lineWidth = lineWidth
    
    layer.addSublayer(backgroundLayer)
    layer.addSublayer(drawingLayer)
    
    //
    //        layer.borderColor = borderColor.CGColor
    //        layer.borderWidth = borderWidth
    
    layer.masksToBounds = true
  }
  
  func beginScribble(point: CGPoint){
    interpolationPoints = [point]
  }
  
  func appendScribble(point: CGPoint){
    interpolationPoints.append(point)
    
    hermitePath.removeAllPoints()
    hermitePath.interpolatePointsWithHermite(interpolationPoints: interpolationPoints)
    
    drawingLayer.path = hermitePath.cgPath
  }
  
  func endScribble(){
    if let backgroundPath = backgroundLayer.path{
      hermitePath.append(UIBezierPath.init(cgPath: backgroundPath))
    }
    
    backgroundLayer.path = hermitePath.cgPath
    hermitePath.removeAllPoints()
    
    drawingLayer.path = hermitePath.cgPath
  }
  
  func clearScribble(){
    backgroundLayer.path = nil
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let location = touches.first?.location(in: self) else{
      return
    }
    
    guard frame.contains(location) else {return}
    
    if let adjustedLocationInView = touches.first?.location(in: self){
      beginScribble(point: adjustedLocationInView)
    }
  }
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let
      touch = touches.first,
      let coalescedTouches = event?.coalescedTouches(for: touch)else{return}
    
    coalescedTouches.forEach{
      appendScribble(point: $0.location(in: self))
    }
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    endScribble()
  }
}

// MARK: Extension to convert drawing to UIImage

extension HermiteScribbleView{
  func toImage() -> UIImage{
    
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, true, 0.0)
    self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image!
  }
}

extension UIBezierPath{
  func interpolatePointsWithHermite(interpolationPoints:[CGPoint],alpha: CGFloat = 1.0/3.0){
    // Return If points are empty
    guard !interpolationPoints.isEmpty else {return}
    self.move(to: interpolationPoints.first!)
    
    let n = interpolationPoints.count - 1
    
    for index in 0..<n{
      var currentPoint = interpolationPoints[index]
      var nextIndex = (index + 1) % interpolationPoints.count
      var prevIndex = index == 0 ? interpolationPoints.count - 1 : index - 1
      var previousPoint = interpolationPoints[prevIndex]
      var nextPoint = interpolationPoints[nextIndex]
      let endPoint = nextPoint
      var mx : CGFloat
      var my : CGFloat
      
      if index > 0
      {
        mx = (nextPoint.x - previousPoint.x) / 2.0
        my = (nextPoint.y - previousPoint.y) / 2.0
      }
      else
      {
        mx = (nextPoint.x - currentPoint.x) / 2.0
        my = (nextPoint.y - currentPoint.y) / 2.0
      }
      
      let controlPoint1 = CGPoint(x: currentPoint.x + mx * alpha, y: currentPoint.y + my * alpha)
      currentPoint = interpolationPoints[nextIndex]
      nextIndex = (nextIndex + 1) % interpolationPoints.count
      prevIndex = index
      previousPoint = interpolationPoints[prevIndex]
      nextPoint = interpolationPoints[nextIndex]
      
      if index < n - 1
      {
        mx = (nextPoint.x - previousPoint.x) / 2.0
        my = (nextPoint.y - previousPoint.y) / 2.0
      }
      else
      {
        mx = (currentPoint.x - previousPoint.x) / 2.0
        my = (currentPoint.y - previousPoint.y) / 2.0
      }
      
      let controlPoint2 = CGPoint(x: currentPoint.x - mx * alpha, y: currentPoint.y - my * alpha)
      self.addCurve(to: endPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
      
    }
  }
}
