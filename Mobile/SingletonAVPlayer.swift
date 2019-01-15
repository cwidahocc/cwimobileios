//
//  SingletonAVPlayer.swift
//  Mobile
//
//  Created by Jason Hocker on 9/9/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

class SingletonAVPlayer : NSObject {
    static let shared = SingletonAVPlayer()
    var player : AVPlayer?
    
    private override init() {
        super.init()
    }
    
    public var playerItem : AVPlayerItem? {
        set { player = AVPlayer(playerItem: playerItem) }
        get { return player?.currentItem }
    }

}
