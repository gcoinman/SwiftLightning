//
//  CameraMainInteractor.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-05-02.
//  Copyright (c) 2018 BiscottiGelato. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit
import AVFoundation


protocol CameraMainBusinessLogic {
  func update(request: CameraMain.Update.Request)
}

protocol CameraMainDataStore {
  var cameraMode: CameraMode? { get set }
}

class CameraMainInteractor: NSObject, CameraMainBusinessLogic, CameraMainDataStore, AVCaptureMetadataOutputObjectsDelegate {
  
  var presenter: CameraMainPresentationLogic?
  var cameraMode: CameraMode?
  
  
  // MARK: Update Apperance
  
  func update(request: CameraMain.Update.Request) {
    guard let cameraMode = cameraMode else {
      SLLog.assert("cameraMode = nil")
      return
    }
    let response = CameraMain.Update.Response(cameraMode: cameraMode, address: nil, addressValid: false)
    presenter?.presentUpdate(response: response)
  }
  
  
  // MARK: AV Capture Metadata Output Delegate
  
  func metadataOutput(_ output: AVCaptureMetadataOutput,
                      didOutput metadataObjects: [AVMetadataObject],
                      from connection: AVCaptureConnection) {
    
    guard let cameraMode = cameraMode else {
      SLLog.assert("cameraMode = nil")
      return
    }
    
    guard metadataObjects.count != 0, let metadataObj = metadataObjects[0] as? AVMetadataMachineReadableCodeObject,
      metadataObj.type == AVMetadataObject.ObjectType.qr, let metadataString = metadataObj.stringValue else {
      let response = CameraMain.Update.Response(cameraMode: cameraMode, address: nil, addressValid: false)
      presenter?.presentUpdate(response: response)
      return
    }
    
    // Check if it's a valid address if we find a QR code
    switch cameraMode {
    case .payment:
      LNManager.determineAddress(inputString: metadataString) { (_, _, _, _, valid) in
        var response: CameraMain.Update.Response
        
        switch valid {
        case .some(true):
          response = CameraMain.Update.Response(cameraMode: cameraMode, address: metadataString, addressValid: true)
          
        case .some(false):
          response = CameraMain.Update.Response(cameraMode: cameraMode, address: metadataString, addressValid: false)
          
        case nil:
          response = CameraMain.Update.Response(cameraMode: cameraMode, address: metadataString, addressValid: nil)
        }
        self.presenter?.presentUpdate(response: response)
      }
      
    case .channel:
      var response: CameraMain.Update.Response
      
      // Somestimes the node peer host address is appended at the back, make sure it's dropped before validating
      let pubKeyString = String(metadataString.split(separator: "@")[0])
      
      if LNManager.validateNodePubKey(pubKeyString) {
        response = CameraMain.Update.Response(cameraMode: cameraMode, address: metadataString, addressValid: true)
      } else {
        response = CameraMain.Update.Response(cameraMode: cameraMode, address: metadataString, addressValid: false)
      }
      presenter?.presentUpdate(response: response)
    }
  }
}