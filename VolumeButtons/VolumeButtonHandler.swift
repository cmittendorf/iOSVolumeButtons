//
//  VolumeButtonHandler.swift
//  VolumeButtons
//
//  Created by Christian Mittendorf on 05/08/16.
//  Copyright © 2016 Christian Mittendorf. All rights reserved.
//

import AVFoundation
import MediaPlayer
import Darwin

public final class VolumeButtonHandler: NSObject {

    private var context = "context"
    private let cameraTriggerKeyPath = "outputVolume"
    private let maxVolume: Float = 0.99999
    private let minVolume: Float = 0.00001

    private var appIsActive = true

    private var audioSession: AVAudioSession?
    private var fakeVolumeView: MPVolumeView?
    private var initialVolume: Float = 0.0

    public var volumeUpAction: (() -> Void)?
    public var volumeDownAction: (() -> Void)?

    override init() {
        super.init()

        setupSession()

        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(VolumeButtonHandler.applicationDidChangeActive(_:)),
                       name:NSNotification.Name.UIApplicationWillResignActive,
                       object: nil)
        nc.addObserver(self,
                       selector: #selector(VolumeButtonHandler.applicationDidChangeActive(_:)),
                       name: NSNotification.Name.UIApplicationDidBecomeActive,
                       object: nil)
    }

    convenience init(volumeUpAction: (() -> Void)?, volumeDownAction: (() -> Void)?) {
        self.init()
        self.volumeUpAction = volumeUpAction
        self.volumeDownAction = volumeDownAction
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        fakeVolumeView?.removeFromSuperview()
        guard let audioSession = audioSession
            else { return }

        audioSession.removeObserver(self, forKeyPath: cameraTriggerKeyPath)
    }

    private func setupSession() {
        guard audioSession == nil
            else { return }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(AVAudioSessionCategoryAmbient)
            try audioSession.setActive(true)

            /// we detect a volume button press by observing
            /// the outputVolume property for changes
            audioSession.addObserver(self, forKeyPath: cameraTriggerKeyPath,
                                     options: [.old, .new], context: &context)

            NotificationCenter.default.addObserver(self,
                  selector: #selector(VolumeButtonHandler.audioSessionInterrupted(_:)),
                  name:NSNotification.Name.AVAudioSessionInterruption,
                  object: nil)

            self.audioSession = audioSession
        } catch {
            NSLog("Error initiliazing AVAudioSession: \(error)")
        }
    }

    private func setInitialVolume() {
        guard let audioSession = audioSession
            else { return }

        initialVolume = audioSession.outputVolume
        if initialVolume > maxVolume {
            initialVolume = maxVolume
        } else if initialVolume < minVolume {
            initialVolume = minVolume
        }
        setSystemVolume(initialVolume)
    }

    private func disableVolumeHUD() {
        guard let view = UIApplication.shared.windows.first
            , self.fakeVolumeView == nil
            else { return }

        /// place the view outside the visible area
        let frame = CGRect(x: LONG_MAX, y: LONG_MAX, width: 0, height: 0)
        let fakeVolumeView = MPVolumeView(frame: frame)
        view.addSubview(fakeVolumeView)
        self.fakeVolumeView = fakeVolumeView
    }

    public func audioSessionInterrupted(_ notification: Notification) {
        guard let userInfo = (notification as NSNotification).userInfo,
            let type = userInfo[AVAudioSessionInterruptionTypeKey] as? AVAudioSessionInterruptionType
            else { return }

        switch type {
        case .began:
            break
        case .ended:
            _ = try? audioSession?.setActive(true)
            break
        }
    }

    public func applicationDidChangeActive(_ notification: Notification) {
        appIsActive = (notification.name == NSNotification.Name.UIApplicationDidBecomeActive)
        if appIsActive {
            disableVolumeHUD()
            setInitialVolume()
        }
    }

    private func setSystemVolume(_ volume: Float) {
        guard let fakeVolumeView = fakeVolumeView
            else { return }

        // this is a hack, but there is afaik no other way for an
        // application to change the system volume programmatically
        for subView in fakeVolumeView.subviews {
            if let slider = subView as? UISlider {
                slider.value = volume
                slider.sendActions(for: .touchUpInside)
                break
            }
        }
    }

    public override func observeValue(forKeyPath keyPath: String?,
                                      of object: Any?,
                                      change: [NSKeyValueChangeKey : Any]?,
                                      context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath, let change = change,
            let newValue = change[NSKeyValueChangeKey.newKey] as? Float,
            let oldValue = change[NSKeyValueChangeKey.oldKey] as? Float, 
            context == context && appIsActive &&
                keyPath == cameraTriggerKeyPath &&
                newValue != initialVolume
            else { return }

        if newValue > oldValue {
            volumeUpAction?()
        } else {
            volumeDownAction?()
        }

        /// reset the system volume to its initial value
        setSystemVolume(initialVolume)
    }
}
