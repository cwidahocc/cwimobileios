//
//  VideoViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 8/21/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import AVKit
import AVFoundation

class VideoViewController : UIViewController, UIGestureRecognizerDelegate, EllucianMobileLaunchableControllerProtocol {
    
    var module : Module!
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var textBackgroundView: UIView!
    @IBOutlet var label: UILabel!
    @IBOutlet var videoView: UIView!
    @IBOutlet var mediaPlayButton: UIView!
    
    var assetUrl : URL?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.sendView( "Video", moduleName: module!.name)
    }
    
    override func viewDidLoad() {
        
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        let loadingString = NSLocalizedString("Loading", comment: "loading message while waiting for data to load")
        hud.label.text = loadingString
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, loadingString)
        
        label.accessibilityTraits = UIAccessibilityTraitButton
        label.accessibilityHint = NSLocalizedString("Plays the video.", comment: "VoiceOver hint for button that plays a video")
        
        self.title = module!.name
        if let labelText = self.module?.property(forKey: "description") , !labelText.isEmpty {
            label.text = labelText
        } else {
            textBackgroundView.isHidden = true
            label.isHidden = true
        }
        
        if let urlString = module?.property(forKey: "video") {
            assetUrl = URL(string: urlString)
            copyImageToBackground()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            sendEventToTracker1(category: .ui_Action, action: .button_Press, label: "Play button pressed", moduleName: module?.name)
            let destination = segue.destination as!
            AVPlayerViewController
            if let url = self.assetUrl {
                do {
                    let player = AVPlayer(url: url)
                    let audioSession = AVAudioSession.sharedInstance()
                    try audioSession.setCategory(AVAudioSessionCategoryPlayback)
                    destination.player = player
                    player.play()
                } catch let error {
                    print(error)
                }
            }
    }
    
    private func copyImageToBackground() {
        DispatchQueue.global(qos: .utility).async {
            let asset: AVAsset = AVAsset(url: self.assetUrl!)
            let imageGenerator = AVAssetImageGenerator(asset: asset);
            let time = CMTimeMake(0, 600)
            do {
                let imageRef = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                let image = UIImage(cgImage: imageRef)
                DispatchQueue.main.async {
                    self.mediaPlayButton.isHidden = false
                    MBProgressHUD.hide(for: self.view, animated: true)
                    self.imageView.image = image
                    
                    self.addGestureRecognizer()
                }
            } catch let error as NSError {
                DispatchQueue.main.async {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    let alertController = UIAlertController(title: NSLocalizedString("Error Loading Video", comment: "title when error loading video"), message: error.localizedDescription, preferredStyle: .alert)
                    
                    let OKAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: nil)
                    alertController.addAction(OKAction)
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            } catch {
                
            }
        }
    }
    
    func addGestureRecognizer() {
        let recognizer = UITapGestureRecognizer(target: self, action:#selector(VideoViewController.play(_:)))
        recognizer.delegate = self
        self.videoView.addGestureRecognizer(recognizer)
    }
    
    @objc func play(_ recognizer: UITapGestureRecognizer) {
        self.performSegue(withIdentifier: "play", sender: nil)
    }
}
