//
//  ImageBySaliencyCropper.swift
//  randomimage
//
//  Created by Felix Almesberger on 01.05.23.
//

import Foundation
import Vision
import CoreGraphics
import UIKit

func cropImageWithSaliency(image: UIImage, screenSize:CGRect ) -> UIImage {
    let imageAspectRatio = image.size.width / image.size.height
    let screenAspectRatio = screenSize.width / screenSize.height
    
    var cropRect: CGRect
    if imageAspectRatio > screenAspectRatio {
        let height = image.size.height
        let width = height * screenAspectRatio
        let x = (image.size.width - width) / 2
        cropRect = CGRect(x: x, y: 0, width: width, height: height)
    } else {
        let width = image.size.width
        let height = width / screenAspectRatio
        let y = (image.size.height - height) / 2
        cropRect = CGRect(x: 0, y: y, width: width, height: height)
    }
    
    let salientRect = calculateSalientRect(image: image, cropRect: cropRect)
    let croppedImage = image.cgImage!.cropping(to: salientRect)!
    return UIImage(cgImage: croppedImage)
}

func calculateSalientRect(image:UIImage, cropRect: CGRect) -> CGRect {
    let salientPoint = findSalientPoint(image: image)
    let salientX = max(min(salientPoint.x, cropRect.maxX), cropRect.minX)
    let salientY = max(min(salientPoint.y, cropRect.maxY), cropRect.minY)
    let salientWidth = min(cropRect.width, max(cropRect.minX + cropRect.width - salientX, salientX - cropRect.minX))
    let salientHeight = min(cropRect.height, max(cropRect.minY + cropRect.height - salientY, salientY - cropRect.minY))
    return CGRect(x: salientX - salientWidth/2, y: salientY - salientHeight/2, width: salientWidth, height: salientHeight)
}

func findSalientPoint(image: UIImage) -> CGPoint {
    let orientation = mapOrientation(from: image.imageOrientation)
    
    // Create a saliency detection request
    let saliencyRequest = VNGenerateAttentionBasedSaliencyImageRequest()
    
    // Perform the request
    let handler = VNImageRequestHandler(ciImage: CIImage(image: image)!, orientation: orientation)
    try! handler.perform([saliencyRequest])
    
    // Get the saliency map
    let saliencyMap = saliencyRequest.results?.first as! VNSaliencyImageObservation
    let saliencyMapImage = saliencyMap.pixelBuffer

    
    // Find the most salient point
    var maxSalience = Float.leastNormalMagnitude
    var salientPoint = CGPoint.zero
    let saliencyMapWidth = CVPixelBufferGetWidth(saliencyMap.pixelBuffer)
    let saliencyMapHeight = CVPixelBufferGetHeight(saliencyMap.pixelBuffer)
    CVPixelBufferLockBaseAddress(saliencyMap.pixelBuffer, .readOnly)
    let baseAddress = CVPixelBufferGetBaseAddress(saliencyMap.pixelBuffer)
    let bytesPerRow = CVPixelBufferGetBytesPerRow(saliencyMap.pixelBuffer)
    let widthRatio = CGFloat(saliencyMapWidth) / image.size.width
    let heightRatio = CGFloat(saliencyMapHeight) / image.size.height
    for y in 0..<saliencyMapHeight {
        for x in 0..<saliencyMapWidth {
            let salience = baseAddress!.load(fromByteOffset: y * bytesPerRow + x * 4, as: Float32.self)
            if salience > maxSalience {
                maxSalience = salience
                salientPoint = CGPoint(x: CGFloat(x) / widthRatio, y: CGFloat(y) / heightRatio)
            }
        }
    }
    CVPixelBufferUnlockBaseAddress(saliencyMap.pixelBuffer, .readOnly)
    
    return salientPoint
}

func mapOrientation(from uiImageOrientation: UIImage.Orientation) -> CGImagePropertyOrientation {
    switch uiImageOrientation {
    case .up:
        return .up
    case .down:
        return .down
    case .left:
        return .left
    case .right:
        return .right
    case .upMirrored:
        return .upMirrored
    case .downMirrored:
        return .downMirrored
    case .leftMirrored:
        return .leftMirrored
    case .rightMirrored:
        return .rightMirrored
    @unknown default:
        fatalError("Unknown UIImage.Orientation case.")
    }
}
