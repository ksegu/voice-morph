//
//  PlaySoundsViewController+Audio.swift
//  PitchPerfect
//
//  Copyright Â© 2016 Udacity. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseStorage
// MARK: - PlaySoundsViewController: AVAudioPlayerDelegate

extension PlayEffectsViewController: AVAudioPlayerDelegate {
    
    // MARK: Alerts
    
    struct Alerts {
        static let DismissAlert = "Dismiss"
        static let RecordingDisabledTitle = "Recording Disabled"
        static let RecordingDisabledMessage = "You've disabled this app from recording your microphone. Check Settings."
        static let RecordingFailedTitle = "Recording Failed"
        static let RecordingFailedMessage = "Something went wrong with your recording."
        static let AudioRecorderError = "Audio Recorder Error"
        static let AudioSessionError = "Audio Session Error"
        static let AudioRecordingError = "Audio Recording Error"
        static let AudioFileError = "Audio File Error"
        static let AudioEngineError = "Audio Engine Error"
    }
    
    // MARK: PlayingState (raw values correspond to sender tags)
    
    enum PlayingState { case playing, notPlaying }
    
    // MARK: Audio Functions
    
    func setupAudio() {
        // initialize (recording) audio file
        do {
            audioFile = try AVAudioFile(forReading: recordedAudioURL as URL)
        } catch {
            showAlert(Alerts.AudioFileError, message: String(describing: error))
        }
    }
    
    func playSound(rate: Float? = nil, pitch: Float? = nil, echo: Bool = false, reverb: Bool = false) {
        
        // initialize audio engine components
        audioEngine = AVAudioEngine()
        
        // node for playing audio
        audioPlayerNode = AVAudioPlayerNode()
        audioEngine.attach(audioPlayerNode)
        
        // node for adjusting rate/pitch
        let changeRatePitchNode = AVAudioUnitTimePitch()
        if let pitch = pitch {
            changeRatePitchNode.pitch = pitch
        }
        if let rate = rate {
            changeRatePitchNode.rate = rate
        }
        audioEngine.attach(changeRatePitchNode)
        
        // node for echo
        let echoNode = AVAudioUnitDistortion()
        echoNode.loadFactoryPreset(.multiEcho1)
        audioEngine.attach(echoNode)
        
        // node for reverb
        let reverbNode = AVAudioUnitReverb()
        reverbNode.loadFactoryPreset(.cathedral)
        reverbNode.wetDryMix = 50
        audioEngine.attach(reverbNode)
        
        let audioMixer = audioEngine.mainMixerNode
       // audioEngine.attach(audioMixer)
        
        // connect nodes
        if echo == true && reverb == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, echoNode, reverbNode, audioMixer, audioEngine.outputNode)
//            connectAudioNodes(audioMixer, changeRatePitchNode, echoNode, reverbNode, audioEngine.outputNode)
        } else if echo == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, echoNode, audioMixer, audioEngine.outputNode)
//            connectAudioNodes(audioMixer, changeRatePitchNode, echoNode, audioEngine.outputNode)
        } else if reverb == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, reverbNode,audioMixer, audioEngine.outputNode)
//            connectAudioNodes(audioMixer, changeRatePitchNode, reverbNode, audioEngine.outputNode)
        } else {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, audioMixer, audioEngine.outputNode)
//            connectAudioNodes(audioMixer, changeRatePitchNode, audioEngine.outputNode)
        }
      // connectAudioNodes(audioMixer, audioEngine.outputNode)
        
        // schedule to play and start the engine!
        audioPlayerNode.stop()
        audioPlayerNode.scheduleFile(audioFile, at: nil) {
            
            var delayInSeconds: Double = 0
            
            if let lastRenderTime = self.audioPlayerNode.lastRenderTime, let playerTime = self.audioPlayerNode.playerTime(forNodeTime: lastRenderTime) {
                
                if let rate = rate {
                    delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double(self.audioFile.processingFormat.sampleRate) / Double(rate)
                } else {
                    delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double(self.audioFile.processingFormat.sampleRate)
                }
            }
            
            // schedule a stop timer for when audio finishes playing
            self.stopTimer = Timer(timeInterval: delayInSeconds, target: self, selector: #selector(PlayEffectsViewController.stopAudio), userInfo: nil, repeats: false)
            RunLoop.main.add(self.stopTimer!, forMode: RunLoop.Mode.default)
        }
        
        do {
            try audioEngine.start()
           
            let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String

            print(dirPath);
            let recordingName = "effect" + NSUUID().uuidString + ".wav";
            let pathArray = [dirPath , recordingName]
            //
            let loc = pathArray.joined(separator: "/")

          //  let filePath = URL(string: pathArray.joined(separator: "/"))!
            print(loc)
            let tmpFileUrl: NSURL = NSURL(fileURLWithPath: loc);
            let newAudio = try AVAudioFile(forWriting: tmpFileUrl as URL, settings:  [
                AVFormatIDKey: NSNumber(value:kAudioFormatLinearPCM),
                AVEncoderAudioQualityKey : AVAudioQuality.low.rawValue,
                AVEncoderBitRateKey : 320000,
                AVNumberOfChannelsKey: 2,
                AVSampleRateKey : 44100.0
                ]);
            print("newAudio created");
            let length = self.audioFile.length
            //let myPath = RecordAudioViewController.loc;
           
           audioEngine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: self.audioEngine.mainMixerNode.inputFormat(forBus: 0)) {
              (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in


            print(newAudio.length)
            print("=====================")
            print(length)
            print("**************************")
            
            var recTill :Int64;
            // handle differently for each effect, need to test
            
            // slow case
            if(rate != nil && rate == 0.5) {
                 recTill = ((length * 2) - 20000);
            }
                // fase case
            else if(rate != nil && rate == 1.5) {
                recTill = (length/2 + 10000);
            }
                // all other cases
            else {
                recTill = (length/2 + length/2 - 7000);
            }
                if ((newAudio.length) < recTill) {//Let us know when to stop saving the file, otherwise saving infinitely

                    do {
                        //print(buffer)
                        try newAudio.write(from: buffer)
                    }catch _{
                        print("Problem Writing Buffer")
                    }
                }else{
                    self.audioEngine.mainMixerNode.removeTap(onBus: 0)//if we dont remove it, will keep on tapping infinitely
                    print("got to before saving");
                    
                        
//                    let saveAlert = UIAlertController(title: "SaveInitialRec", message: "Would you like to save the current recording?", preferredStyle: UIAlertController.Style.alert)
//
//                    saveAlert.addAction(UIAlertAction(title: "Yes!", style: .default, handler: { (action: UIAlertAction!) in
                    
                        
                        let databaseRef = Database.database().reference().child("sounds")
                        
                        let curID = databaseRef.childByAutoId()
                        
                        
                        let currentDateTime = NSDate()
                        let formatter = DateFormatter()
                        formatter.dateFormat = "MM-dd-yyyy"
                        
                        curID.setValue(["name" : recordingName , "date" : formatter.string(from: currentDateTime as Date)]);
                        
                        
                        
                        let storageRef = Storage.storage().reference().child("sounds")
                        
                        
                        let uploadRef = storageRef.child(recordingName)
                        uploadRef.putFile(from: URL(string: "file://" + loc)!, metadata: nil) { (metadata, error) in
                            print("UPLOAD TASK FINISHED")
                            print(metadata ?? "NO METADATA")
                            print(error ?? "NO ERROR")
                        }
                        
                   // }))
                    
//               saveAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (action: UIAlertAction!) in
//                        print("do nothing")
//                    }))
                    
                
                                      
                    //DO WHAT YOU WANT TO DO HERE WITH EFFECTED AUDIO

                }

            }


        } catch {
            showAlert(Alerts.AudioEngineError, message: String(describing: error))
            return
        }
        
        // play the recording!
        audioPlayerNode.play()
        
     
//        let saveAlert = UIAlertController(title: "SaveInitialRec", message: "Would you like to save the current recording?", preferredStyle: UIAlertController.Style.alert)
//
//        saveAlert.addAction(UIAlertAction(title: "Yes!", style: .default, handler: { (action: UIAlertAction!) in
//
//
//
//            let databaseRef = Database.database().reference().child("sounds")
//
//            let curID = databaseRef.childByAutoId()
//
//
//            let currentDateTime = NSDate()
//            let formatter = DateFormatter()
//            formatter.dateFormat = "MM-dd-yyyy"
//
//            curID.setValue(["name" : self.recordingName , "date" : formatter.string(from: currentDateTime as Date)]);
//
//            let storageRef = Storage.storage().reference().child("sounds")
//
//            let uploadRef = storageRef.child(recordingName)
//            self.uploadTask = uploadRef.putFile(from: URL(string: "file://" + self.loc)!, metadata: nil) { (metadata, error) in
//                print("UPLOAD TASK FINISHED")
//                print(metadata ?? "NO METADATA")
//                print(error ?? "NO ERROR")
//            }
//
//
//            self.performSegue(withIdentifier: "stopRecording", sender: self.audioRecorder.url)
//        }))
//
//        saveAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (action: UIAlertAction!) in
//
//
//            self.performSegue(withIdentifier: "stopRecording", sender: self.audioRecorder.url)
//        }))
//
//        present(saveAlert, animated: true, completion: nil)
        
    
        
    }
    
    @objc func stopAudio() {
        
        if let audioPlayerNode = audioPlayerNode {
            audioPlayerNode.stop()
        }
        
        if let stopTimer = stopTimer {
            stopTimer.invalidate()
        }
        
        configureUI(.notPlaying)
        
        if let audioEngine = audioEngine {
            audioEngine.stop()
            audioEngine.reset()
        }
    }
    
    // MARK: Connect List of Audio Nodes
    
    func connectAudioNodes(_ nodes: AVAudioNode...) {
        for x in 0..<nodes.count-1 {
            audioEngine.connect(nodes[x], to: nodes[x+1], format: audioFile.processingFormat)
        }
    }
    
    // MARK: UI Functions
    
    func configureUI(_ playState: PlayingState) {
        switch(playState) {
        case .playing:
            setPlayButtonsEnabled(false)
            stopButton.isEnabled = true
        case .notPlaying:
            setPlayButtonsEnabled(true)
            stopButton.isEnabled = false
        }
    }
    
    func setPlayButtonsEnabled(_ enabled: Bool) {
        snailButton.isEnabled = enabled
        chipmunkButton.isEnabled = enabled
        rabbitButton.isEnabled = enabled
        vaderButton.isEnabled = enabled
        echoButton.isEnabled = enabled
        reverbButton.isEnabled = enabled
    }
    
    func showAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Alerts.DismissAlert, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
