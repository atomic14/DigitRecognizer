//
//  ViewController.swift
//  digits
//
//  Created by Chris Greening on 25/06/2017.
//  Copyright © 2017 Chris Greening. All rights reserved.
//

import UIKit
import CoreML
import Vision
import ImageIO

class ViewController: UIViewController {
  @IBOutlet weak var scribbleView: HermiteScribbleView!
  @IBOutlet weak var classification: UILabel!
  @IBOutlet weak var tmpImage: UIImageView!
  var model: VNCoreMLModel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    do {
      model = try VNCoreMLModel(for: MNISTClassifier().model)
    } catch {
      fatalError("Could not load model")
    }
    Timer.scheduledTimer(withTimeInterval: 0.25,
                         repeats: true) { (timer) in
                          let image = self.scribbleView.toImage()
                          guard let ciImage = CIImage(image: image)
                            else { fatalError("can't create CIImage from UIImage") }
                          let invertedImage = ciImage.applyingFilter("CIColorInvert", withInputParameters: nil)
                          let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue))
                          if let orienation = orientation {
                            let inputImage = invertedImage.applyingOrientation(Int32(orienation.rawValue))
                            
                            self.tmpImage.image = UIImage.init(ciImage: inputImage)
                          
                            let request = VNCoreMLRequest(model: self.model, completionHandler: self.handleClassification)
                            request.imageCropAndScaleOption = VNImageCropAndScaleOptionCenterCrop
                            // Run the rectangle detector, which upon completion runs the ML classifier.
                            let handler = VNImageRequestHandler(ciImage: inputImage, orientation: Int32(orientation!.rawValue))
                            DispatchQueue.global(qos: .userInteractive).async {
                              do {
                                try handler.perform([request])
                              } catch {
                                print(error)
                              }
                            }
                          }
    }
  }

  @IBAction func clearAction(_ sender: Any) {
    self.scribbleView.clearScribble()
  }
  
  func handleClassification(request: VNRequest, error: Error?) {
    guard let observations = request.results as? [VNClassificationObservation]
      else { fatalError("unexpected result type from VNCoreMLRequest") }
    guard let best = observations.first
      else { fatalError("can't get best result") }
    
    DispatchQueue.main.async {
      self.classification.text = "Classification: \"\(best.identifier)\" Confidence: \(best.confidence)"
    }
  }
}

