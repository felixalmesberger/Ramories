//
//  MyViewModel.swift
//  frame
//
//  Created by Felix Almesberger on 29.05.22.
//

import Foundation
import SwiftUI
import Photos
import PhotosUI

final class RandomPhotoLibraryFoto : ObservableObject {
    @Published var current : UIImage = UIImage()
    @Published var isAuthorized : Bool = true
    @Published var isLoading : Bool = true
    @Published var location : String = ""
    @Published var date : String = ""
    
    private var numberOfImages : Int = 0
    private var fotos: PHFetchResult<PHAsset> = PHFetchResult<PHAsset>()
    
    init() {
        let timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { timer in
             self.loadNewImage()
         }
        
        self.ensureAuthorized()
    }
    
    func ensureAuthorized() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        if(status == PHAuthorizationStatus.authorized) {
            self.isAuthorized = true
            self.initializeImages()
            self.loadNewImage()
            return
        }
        
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { (status) in
            self.isAuthorized = true
            self.initializeImages()
            self.loadNewImage()
        }
    }
    
    func initializeImages() {
        self.isLoading = true;
        
        self.fotos = PHAsset.fetchAssets(with: PHFetchOptions())
        self.numberOfImages = self.fotos.count
        
        self.isLoading = false;
    }
    
    func gotoAppPrivacySettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
            UIApplication.shared.canOpenURL(url) else {
                assertionFailure("Not able to open App privacy settings")
                return
        }

        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    func loadNewImage() {
        DispatchQueue.main.async {
        let randomIndex = Int.random(in: 0..<self.numberOfImages)
        let foto = self.fotos[randomIndex]
        
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        PHImageManager.default().requestImage(for: foto,
                                              targetSize:  PHImageManagerMaximumSize,
                                              contentMode: .aspectFill,
                                              options: options,
                                              resultHandler: { image, _ in
            let cropped = cropImageWithSaliency(image: image!, screenSize: UIScreen.main.bounds)
            self.current = cropped
      })
    }
  }
}
