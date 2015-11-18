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
    
// *************************** GLOBAL VAR *******************************
    
    var pinchGesture: UIPinchGestureRecognizer = UIPinchGestureRecognizer()
    var camera = true
    let systemFont = UIFont.systemFontOfSize(12)
    let screenWidth = UIScreen.mainScreen().bounds.width
    let screenHeight = UIScreen.mainScreen().bounds.height
    let screenScale = UIScreen.mainScreen().scale
    let captureSession = AVCaptureSession()
    let stillImageOutput = AVCaptureStillImageOutput()
    var previewLayer = AVCaptureVideoPreviewLayer?()
    var imageSampleBuffer = CMSampleBuffer?()
    var captureDevice = AVCaptureDevice?()
    var rect = CGRect()
    let allImageViews = NSMutableArray()
    let allCenters = NSMutableArray()
    var emptySpot: CGPoint = CGPointMake(0, 0)
    var tapCen: CGPoint = CGPointMake(0, 0)
    var left: CGPoint = CGPointMake(0, 0)
    var right: CGPoint = CGPointMake(0, 0)
    var top: CGPoint = CGPointMake(0, 0)
    var bottom: CGPoint = CGPointMake(0, 0)
    var startTime = NSTimeInterval()
    var timer = NSTimer()
    var videoConnection = AVCaptureConnection!()
    var parentView: UIView = UIView()
    
// **************************** BUTTONS *********************************
    
    let reshuffleButton = UIButton(type: UIButtonType.System) as UIButton
    
    @IBOutlet weak var captureButton: UIButton!
    @IBAction func captureImage(sender: UIButton) {
        self.videoConnection = stillImageOutput.connectionWithMediaType(AVMediaTypeVideo)
        if (self.videoConnection != nil){
            stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection){
                (imageSampleBuffer : CMSampleBuffer!, _) in
                    if (imageSampleBuffer != nil) {
                        let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageSampleBuffer)
                        let capture: UIImage! = UIImage(data: imageData)
                        let imageObbj:UIImage = self.squareCropImageToSideLength(capture, sideLength: self.screenWidth)
                        self.captureSession.stopRunning()
                        self.previewLayer?.removeFromSuperlayer()
                        for i in self.captureSession.inputs {
                            self.captureSession.removeInput(i as! AVCaptureInput)
                        }
                        for j in self.captureSession.outputs {
                            self.captureSession.removeOutput(j as! AVCaptureOutput)
                        }
                        
                        self.createPuzzle(imageObbj)
                        self.randomizeBlocks(3)
                        self.displayTime.hidden = false
                        self.backButton.hidden = false
                        self.captureButton.hidden = true
                        self.switchCameraButton.hidden = true
                        
                    } else {
                        print("No image taken :(")
                }
            }
        }
    }
    
    @IBOutlet weak var switchCameraButton: UIButton!
    @IBAction func switchCameraView(sender: UIButton) {
        if(captureSession.running){
            camera = !camera
            reloadCamera()
        }
    }
    
    @IBOutlet weak var backButton: UIButton!
    @IBAction func returnToCamera(sender: UIButton) {

        if(!captureSession.running){
            reshuffleButton.removeFromSuperview()
            if(self.allImageViews.count == 9){
                for var i = 0; i < 9 ; i++ {
                    allImageViews.objectAtIndex(i).removeFromSuperview()
                }
            }
            allImageViews.removeAllObjects()
            allCenters.removeAllObjects()
            reloadCamera()
        }
    }
    
    @IBOutlet weak var displayTime: UILabel!
    
// *************************** INITIALIZE *******************************
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        loadButtons()
        
        //displayTime.hidden = true
        //backButton.hidden = true
        
        pinchGesture = UIPinchGestureRecognizer.init(target: self, action: "zoom:")
        
        let devices = AVCaptureDevice.devices()
        
        // Loop through all the capture devices on this phone
        for device in devices{
            // Make sure this particular device supports video
            if device.hasMediaType(AVMediaTypeVideo){
                // Finally check the position
                if device.position == AVCaptureDevicePosition.Front{
                    captureDevice = device as? AVCaptureDevice
                    if captureDevice != nil{
                        print("capture device found")
                        beginSession()
                    }
                }
            }
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let myTouch: UITouch = touches.first!
        
        if(myTouch.view != self.view){
            
            let adjustmentX: CGFloat = (self.screenWidth/3)
            let adjustmentY: CGFloat = (self.screenHeight/2 - self.screenWidth/3)
            var leftIsEmpty: Bool = false
            var rightIsEmpty: Bool = false
            var topIsEmpty: Bool = false
            var bottomIsEmpty: Bool = false
            let test1 = (emptySpot.x - adjustmentX/2) + ((emptySpot.y - adjustmentY)*3)
            let test2 = test1 / adjustmentX
            let oldTag = myTouch.view!.tag
            
            tapCen = CGPointMake(round(myTouch.view!.center.x), round(myTouch.view!.center.y))
            left = CGPointMake(round(tapCen.x - self.screenWidth/3), tapCen.y)
            right = CGPointMake(round(tapCen.x + self.screenWidth/3), tapCen.y)
            top = CGPointMake(tapCen.x, round(tapCen.y - self.screenWidth/3))
            bottom = CGPointMake(tapCen.x, round(tapCen.y + self.screenWidth/3))
            
            if(left == emptySpot) {leftIsEmpty = true}
            if(right == emptySpot) {rightIsEmpty = true}
            if(top == emptySpot) {topIsEmpty = true}
            if(bottom == emptySpot) {bottomIsEmpty = true}
            
            if(leftIsEmpty || rightIsEmpty || topIsEmpty || bottomIsEmpty){
                
                if !timer.valid {
                    let timeSelector : Selector = "updateTime"
                    timer = NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: timeSelector, userInfo: nil, repeats: true)
                    startTime = NSDate.timeIntervalSinceReferenceDate()
                }
                
                UIView.beginAnimations(nil, context: nil)
                UIView.setAnimationDuration(0.2)
                myTouch.view!.center = emptySpot
                emptySpot = tapCen
                myTouch.view!.tag = Int(round(test2))
                if(countInversions() == 0 && oldTag == 8){
                    timer.invalidate()
                    self.view.addSubview(allImageViews.objectAtIndex(8) as! UIView)
                    emptySpot = CGPointMake(-999, -999)
                    self.view.addSubview(reshuffleButton)
                }
                UIView.commitAnimations()
            }
        }
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
    
// **************************** METHODS *********************************
    
    func createPuzzle(let imageObbj: UIImage){
        
        var xCenter: CGFloat = self.screenWidth/6
        var yCenter: CGFloat = self.screenHeight/2 - self.screenWidth/3
        var access = 0
        for var c = 0; c < 3 ; c++ {
            for var r = 0; r < 3 ; r++ {
                let myImageView: UIImageView = UIImageView(frame: CGRectMake(0, 0, self.screenWidth/3, self.screenWidth/3))
                let curCen: CGPoint = CGPointMake(xCenter, yCenter)
                self.allCenters.addObject(NSValue(CGPoint: curCen))
                
                myImageView.center = curCen
                myImageView.image = self.cropImage(imageObbj, position: CGFloat(r + access + 1))
                //myImageView.image = myArray[r+access]
                myImageView.userInteractionEnabled = true
                self.allImageViews.addObject(myImageView)
                self.view.addSubview(myImageView)
                xCenter += self.screenWidth/3
            }
            xCenter = self.screenWidth/6
            yCenter += self.screenWidth/3
            access += 3
        }
    }
    
    func countInversions() -> Int {
        
        var inversions = 0;
        var nArray: Array = [-1,-1,-1,-1,-1,-1,-1,-1,-1]
        
        for var x = 0; x < 8; x++ {
            nArray[self.allImageViews.objectAtIndex(x).tag] = x
        }
        for var x = 0; x < 9; x++ {
            if(nArray[x] == -1){
                nArray.removeAtIndex(x)
                break
            }
            
        }
       
        for var x = 0; x < nArray.count; x++ {
            for var y = x + 1; y < nArray.count; y++ {
                if(nArray[x] > nArray[y]){
                    ++inversions
                }
            }
        }
        print("inversions: \(inversions)")
        return inversions;
    }
    
    func isSolvable() -> Bool{
        var solvable: Bool = false
        
        if(countInversions() % 2 == 0){
            solvable = true
        }
        return solvable
    }
    
    func randomizeBlocks(let dimensions: Int){
        
        if(reshuffleButton.touchInside){
            self.reshuffleButton.removeFromSuperview()
            displayTime.text = "00:00:00"
        }
        
        allImageViews.objectAtIndex(allImageViews.count - 1).removeFromSuperview()
        let centersCopy: AnyObject = allCenters.mutableCopy()
        var randnum: Int
        var randLoc: CGPoint
        let adjustmentX: CGFloat = (self.screenWidth/3)
        let adjustmentY: CGFloat = (self.screenHeight/2 - self.screenWidth/3)
        
        for x in self.allImageViews{
            if((x as! UIImageView) == (allImageViews.objectAtIndex(8) as! UIImageView)){
                break
            }
            if(screenScale < 3){
            randnum = Int(UInt32(arc4random()) % UInt32(centersCopy.count))
            } else {
            randnum = Int(arc4random()) % centersCopy.count
            }
            randLoc = centersCopy.objectAtIndex(randnum).CGPointValue
            
            let test1 = (randLoc.x - adjustmentX/2) + ((randLoc.y - adjustmentY)*3)
            let test2 = test1 / adjustmentX
            
            
            (x as! UIImageView).tag = Int(round(test2))
            (x as! UIImageView).center = randLoc
            centersCopy.removeObjectAtIndex(randnum)
        }
        emptySpot = CGPointMake(round(centersCopy.objectAtIndex(0).CGPointValue.x), round(centersCopy.objectAtIndex(0).CGPointValue.y))
        if(!isSolvable()){
             randomizeBlocks(dimensions)
        }
    }
    
    func cropImage(let sourceImage: UIImage, let position: CGFloat) -> UIImage {
        
        let width : CGFloat = sourceImage.size.width/(3/screenScale)
        let height : CGFloat = sourceImage.size.height/(3/screenScale)
        
        var croprect: CGRect = CGRect()
        
        switch(position){
        case 1:
            croprect = CGRectMake(0, 0, width, height)
            break
        case 2:
            croprect = CGRectMake(width, 0, width, height)
            break
        case 3:
            croprect = CGRectMake(width * 2, 0, width, height)
            break
        case 4:
            croprect = CGRectMake(0, height, width, height)
            break
        case 5:
            croprect = CGRectMake(width, height, width, height)
            break
        case 6:
            croprect = CGRectMake(width * 2, height, width, height)
            break
        case 7:
            croprect = CGRectMake(0, height * 2, width, height)
            break
        case 8:
            croprect = CGRectMake(width, height * 2, width, height)
            break
        case 9:
            croprect = CGRectMake(width * 2, height * 2, width, height)
        default:
            break
        }
        
        // Draw new image in current graphics contex
        let imageRef: CGImageRef = CGImageCreateWithImageInRect(sourceImage.CGImage, croprect)!
        
        // Create new cropped UIImage
        let croppedImage: UIImage = UIImage(CGImage: imageRef, scale: screenScale, orientation: sourceImage.imageOrientation)
        
        return croppedImage
    }
    
    func squareCropImageToSideLength(let sourceImage: UIImage, let sideLength: CGFloat) -> UIImage {
            // input size comes from image
            let inputSize: CGSize = sourceImage.size
            
            // round up side length to avoid fractional output size
            let sideLength: CGFloat = round(sideLength)
            
            // output size has sideLength for both dimensions
            let outputSize: CGSize = CGSizeMake(sideLength, sideLength)
            
            // calculate scale so that smaller dimension fits sideLength
            let scale: CGFloat = max(sideLength / inputSize.width,
                sideLength / inputSize.height)
            
            // scaling the image with this scale results in this output size
            let scaledInputSize: CGSize = CGSizeMake(inputSize.width * scale,
                inputSize.height * scale)
            
            // determine point in center of "canvas"
            let center: CGPoint = CGPointMake(outputSize.width/2.0,
                outputSize.height/2.0)
            
            // calculate drawing rect relative to output Size
            let outputRect: CGRect = CGRectMake(center.x - scaledInputSize.width/2.0,
                center.y - scaledInputSize.height/2.0,
                scaledInputSize.width,
                scaledInputSize.height)
            
            // begin a new bitmap context, scale 0 takes display scale
            UIGraphicsBeginImageContextWithOptions(outputSize, true, 0)
            
            // optional: set the interpolation quality.
            // For this you need to grab the underlying CGContext
            let ctx: CGContextRef = UIGraphicsGetCurrentContext()!
            CGContextSetInterpolationQuality(ctx, CGInterpolationQuality.High)
            
            // draw the source image into the calculated rect
            sourceImage.drawInRect(outputRect)
            
            // create new image from bitmap context
            let outImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
            
            // clean up
            UIGraphicsEndImageContext()
            
            print(outImage.scale)
            // pass back new image
            return outImage
    }
    
    func zoom(sender: UIPinchGestureRecognizer){
        self.videoConnection = stillImageOutput.connectionWithMediaType(AVMediaTypeVideo)
        if(self.videoConnection != nil){
            if(self.videoConnection.videoScaleAndCropFactor >= 1){
                var affineTransform : CGAffineTransform = CGAffineTransformMakeTranslation(sender.scale, sender.scale)
                affineTransform = CGAffineTransformScale(affineTransform, sender.scale, sender.scale)
                affineTransform = CGAffineTransformRotate(affineTransform, 0)
                CATransaction.begin()
                CATransaction.setAnimationDuration(0.025)
                //previewLayer is object of AVCaptureVideoPreviewLayer
                self.previewLayer?.setAffineTransform(affineTransform)
                if(sender.scale >= 1){
                self.videoConnection.videoScaleAndCropFactor = sender.scale
                }
                CATransaction.commit()
            }
        }
    }
    
    func reloadCamera(){
        
        //Reset timer
        if timer.valid {
            timer.invalidate()
            displayTime.text = "00:00:00"
        }
        
        //Load view buttons (add/remove)
        displayTime.hidden = true
        captureButton.hidden = false
        switchCameraButton.hidden = false
        backButton.hidden = true
        
        //Need to find way to reset captureSession without excessive code (look in beginSession)
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
                            print("Loaded Front Camera")
                            beginSession()
                            break
                        }
                    }
                } else {
                    if device.position == AVCaptureDevicePosition.Back{
                        captureDevice = device as? AVCaptureDevice
                        if captureDevice != nil{
                            print("Loaded Back Camera")
                            beginSession()
                            break
                        }
                    }
                }
            }
        }
    }
    
    func configureDevice(){
        if let device = captureDevice {
            do {
                try device.lockForConfiguration()
            } catch _ {
            }
            //device.focusMode = .Locked
            device.unlockForConfiguration()
        }
    }
    
    func beginSession(){
        
        //configureDevice()
        
        let ImageView: UIImageView = UIImageView(frame: CGRectMake(0, 0, screenWidth, screenWidth))
        parentView = UIView(frame: CGRectMake(0, 161, screenWidth, screenWidth))
        parentView.center = CGPointMake(screenWidth/2, screenHeight/2)
        ImageView.center = CGPointMake(screenWidth/2, screenHeight/2)
        //let previewParentLayer: CALayer = parentView.layer
        parentView.addGestureRecognizer(pinchGesture)
        parentView.userInteractionEnabled = true
        self.view.insertSubview(parentView, atIndex: 1)
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        let err : NSError? = nil
        do{
        try captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
        } catch {
            print("error: \(err?.localizedDescription)")
        }
        captureSession.addOutput(stillImageOutput)
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        parentView.addGestureRecognizer(pinchGesture)
        self.view.layer.insertSublayer(previewLayer!, atIndex : 0)
        previewLayer?.frame = ImageView.bounds
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer?.position = CGPointMake(screenWidth/2, screenHeight/2)
        captureSession.startRunning()
    }
    
    func updateTime() {
        
        let currentTime = NSDate.timeIntervalSinceReferenceDate()
        
        //Find the difference between current time and start time.
        
        var elapsedTime: NSTimeInterval = currentTime - startTime
        
        //calculate the minutes in elapsed time.
        
        let minutes = UInt8(elapsedTime / 60.0)
        
        elapsedTime -= (NSTimeInterval(minutes) * 60)
        
        //calculate the seconds in elapsed time.
        
        let seconds = UInt8(elapsedTime)
        
        elapsedTime -= NSTimeInterval(seconds)
        
        //find out the fraction of milliseconds to be displayed.
        
        let fraction = UInt8(elapsedTime * 100)
        
        //add the leading zero for minutes, seconds and millseconds and store them as string constants
        
        let strMinutes = String(format: "%02d", minutes)
        let strSeconds = String(format: "%02d", seconds)
        let strFraction = String(format: "%02d", fraction)
        
        //concatenate minuets, seconds and milliseconds as assign it to the UILabel
        
        displayTime.text = "\(strMinutes):\(strSeconds):\(strFraction)"
        
    }
    
    func loadButtons(){
        reshuffleButton.frame = CGRectMake(100, 100, 125, 50)
        reshuffleButton.center = CGPointMake(screenWidth/5, (screenHeight/10)*9)
        reshuffleButton.backgroundColor = UIColor.blackColor()
        reshuffleButton.setTitle("Reshuffle?", forState: UIControlState.Normal)
        reshuffleButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState())
        reshuffleButton.titleLabel?.font = UIFont(name: systemFont.fontName, size: 23.0)
        reshuffleButton.addTarget(self, action: "randomizeBlocks:", forControlEvents: UIControlEvents.TouchUpInside)
    }
    
// **********************************************************************
}






/*
func updateDeviceSettings(focusValue : Float, isoValue : Float) {
if let device = captureDevice {
if(device.lockForConfiguration(nil)){
//device.setFocusModeLockedWithLensPosition(focusValue, completionHandler: { (time) -> Void in})

//Adjust the iso to clamp between minIso and maxIso based on the active format
let minISO = device.activeFormat.minISO
let maxISO = device.activeFormat.maxISO
let clampedISO = isoValue * (maxISO - minISO) + minISO

device.setExposureModeCustomWithDuration(AVCaptureExposureDurationCurrent, ISO: clampedISO, completionHandler: { (time) -> Void in })

device.unlockForConfiguration()
}
}
}

func touchPercent(touch : UITouch) -> CGPoint {
//Get dimension of the screen in points
let screenSize = UIScreen.mainScreen().bounds.size

//create an empty CGPoint object set to (0,0)
var touchPer = CGPointZero

//Set the x and y values to be the value of the tapped position, divided by the width/height of the screen
touchPer.x = touch.locationInView(self.view).x / screenSize.width
touchPer.y = touch.locationInView(self.view).y / screenSize.height

//return the populated CGPoint
return touchPer
}

override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent?) {
let touchPer = touchPercent(touches.first as! UITouch)
updateDeviceSettings(Float(touchPer.x), isoValue: Float(touchPer.y))
}

override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent?) {
var touchPer = touchPercent(touches.first as! UITouch)
updateDeviceSettings(Float(touchPer.x), isoValue: Float(touchPer.y))
}
*/