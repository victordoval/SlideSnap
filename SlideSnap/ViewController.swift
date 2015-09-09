//
//  ViewController.swift
//  SlideSnap
//
//  Created by Victor do Val on 9/8/15.
//  Copyright (c) 2015 Victor do Val. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMedia

class ViewController: UIViewController {
    
    @IBOutlet weak var ImageView: UIImageView?
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }
    
    var camera = true
    let captureSession = AVCaptureSession()
    let stillImageOutput = AVCaptureStillImageOutput()
    var previewLayer = AVCaptureVideoPreviewLayer?()
    var imageSampleBuffer = CMSampleBuffer?()
    
    @IBAction func captureImage(sender: UIButton) {
        if let videoConnection = stillImageOutput.connectionWithMediaType(AVMediaTypeVideo){
            println(stillImageOutput.connections.count)
            stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection){(imageSampleBuffer : CMSampleBuffer!, _) in
                    if (imageSampleBuffer != nil) {
                        var imageData =      AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageSampleBuffer)
                        var capture: UIImage! = UIImage(data: imageData)
                        self.ImageView!.image = capture
                    } else {
                        println("No image taken :(")
                }
            }
        }
    }
    
    @IBAction func switchCameraView(sender: UIButton) {
        camera = !camera
        reloadCamera()
    }

    // If we find a device we'll store it here for later use
    var captureDevice = AVCaptureDevice?()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        
        let devices = AVCaptureDevice.devices()
        
        // Loop through all the capture devices on this phone
        for device in devices{
            // Make sure this particular device supports video
            if device.hasMediaType(AVMediaTypeVideo){
                // Finally check the position and confirm we've got the back camera
                if device.position == AVCaptureDevicePosition.Front{
                    captureDevice = device as? AVCaptureDevice
                    if captureDevice != nil{
                        println("capture device found")
                        beginSession()
                    }
                }
            }
            
        }
    }
    
    func reloadCamera(){
        
        var err : NSError? = nil
        captureSession.stopRunning()
        previewLayer?.removeFromSuperlayer()
        for i in captureSession.inputs {
            captureSession.removeInput(i as! AVCaptureInput)
        }
        for j in captureSession.outputs {
            captureSession.removeOutput(j as! AVCaptureOutput)
        }
        let devices = AVCaptureDevice.devices()
        for device in devices{
            if device.hasMediaType(AVMediaTypeVideo){
                if(camera){
                    if device.position == AVCaptureDevicePosition.Front{
                        captureDevice = device as? AVCaptureDevice
                        if captureDevice != nil{
                            println("Loaded Front Camera")
                            beginSession()
                            break
                        }
                    }
                } else {
                    if device.position == AVCaptureDevicePosition.Back{
                        captureDevice = device as? AVCaptureDevice
                        if captureDevice != nil{
                            println("Loaded Back Camera")
                            beginSession()
                            break
                        }
                    }
                }
            }
        }
    }
    
//    func updateDeviceSettings(focusValue : Float, isoValue : Float) {
//        if let device = captureDevice {
//            if(device.lockForConfiguration(nil)){
//                    //device.setFocusModeLockedWithLensPosition(focusValue, completionHandler: { (time) -> Void in})
//                
//                //Adjust the iso to clamp between minIso and maxIso based on the active format
//                let minISO = device.activeFormat.minISO
//                let maxISO = device.activeFormat.maxISO
//                let clampedISO = isoValue * (maxISO - minISO) + minISO
//                
//                device.setExposureModeCustomWithDuration(AVCaptureExposureDurationCurrent, ISO: clampedISO, completionHandler: { (time) -> Void in })
//                
//                device.unlockForConfiguration()
//            }
//        }
//    }
    
//    func touchPercent(touch : UITouch) -> CGPoint {
//        //Get dimension of the screen in points
//        let screenSize = UIScreen.mainScreen().bounds.size
//        
//        //create an empty CGPoint object set to (0,0)
//        var touchPer = CGPointZero
//        
//        //Set the x and y values to be the value of the tapped position, divided by the width/height of the screen
//        touchPer.x = touch.locationInView(self.view).x / screenSize.width
//        touchPer.y = touch.locationInView(self.view).y / screenSize.height
//        
//        //return the populated CGPoint
//        return touchPer
//    }
    
//        override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent?) {
//        let touchPer = touchPercent(touches.first as! UITouch)
//            updateDeviceSettings(Float(touchPer.x), isoValue: Float(touchPer.y))
//    }
//    
//    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent?) {
//        var touchPer = touchPercent(touches.first as! UITouch)
//        updateDeviceSettings(Float(touchPer.x), isoValue: Float(touchPer.y))
//    }
    
    func configureDevice(){
        if let device = captureDevice {
            device.lockForConfiguration(nil)
            //device.focusMode = .Locked
            device.unlockForConfiguration()
        }
    }
    
    func beginSession(){
        
        configureDevice()
        
        var err : NSError? = nil
        captureSession.addInput(AVCaptureDeviceInput(device: captureDevice, error: &err))
        captureSession.addOutput(stillImageOutput)
        
        if err != nil {
            println("error: \(err?.localizedDescription)")
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.view.layer.insertSublayer(previewLayer, atIndex : 0)
        previewLayer?.frame = self.view.layer.frame
        captureSession.startRunning()
    }
}