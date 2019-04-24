//
//  ViewController.swift
//  VoiceMorph
//
//  Created by Kishan Segu on 4/20/19.
//  Copyright © 2019 Kishan Segu. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
class RecordAudioViewController: UIViewController, AVAudioRecorderDelegate {
    
    var audioRecorder: AVAudioRecorder!
    
    @IBOutlet weak var recordingLabel: UILabel!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var stopRecordingButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        stopRecordingButton.isEnabled = false
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("view will appear called")
        
    }
    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//    }

    @IBAction func recordAudio(_ sender: Any) {
         recordingLabel.text = "Recording in Progress"
       stopRecordingButton.isEnabled = true
        recordButton.isEnabled = false
        
        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
//
//        let currentDateTime = NSDate()
//        let formatter = DateFormatter()
//        formatter.dateFormat = "ddMMyyyy-HHmmss"
        let recordingName = "recordedVoice.wav"
            //formatter.string(from: currentDateTime as Date)+".wav"
        let pathArray = [dirPath, recordingName]
        let filePath = URL(string: pathArray.joined(separator: "/"))
        print(filePath!)
        
        //Setup audio session
        let session = AVAudioSession.sharedInstance()
        try! session.setCategory(.playAndRecord, mode: .default, options: [])
        try! session.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)

        try! audioRecorder = AVAudioRecorder(url: filePath!, settings: [ : ])
        audioRecorder.delegate = self
        audioRecorder.isMeteringEnabled = true
        audioRecorder.prepareToRecord()
        audioRecorder.record()
       
    }
    
    @IBAction func stopRecording(_ sender: Any) {
        recordButton.isEnabled = true
        stopRecordingButton.isEnabled = false
        recordingLabel.text = "Tap to Start Recording"
        audioRecorder.stop()
        
        
        
        let audioSession = AVAudioSession.sharedInstance()
        try! audioSession.setActive(false)
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            let saveAlert = UIAlertController(title: "SaveInitialRec", message: "Would you like to save the current recording?", preferredStyle: UIAlertController.Style.alert)
            
            saveAlert.addAction(UIAlertAction(title: "Yes!", style: .default, handler: { (action: UIAlertAction!) in
              //  let id = self.audioRecorder.url
                
                
//                let audioName = NSUUID().uuidString //You'll get unique audioFile name
//                let storageRef = Storage.storage().reference().child("audio").child(audioName)
//                let metadata  = StorageMetadata()
//                metadata.contentType = "audio/wav"
//                if let uploadData = AVFileType(self.recordedVoice.wav!) {
//
//                    storageRef.putData(uploadData, metadata: metadata) { (metadata, err) in
//                        if err != nil {
//                            //print(err)
//                            return
//                        }
//                        if let _ = metadata?.downloadURL()?.absoluteString {
//                            print("uploading done!")
//                        }
//                    }
//                }
                
                self.performSegue(withIdentifier: "stopRecording", sender: self.audioRecorder.url)
            }))
            
            saveAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (action: UIAlertAction!) in
                
                
                self.performSegue(withIdentifier: "stopRecording", sender: self.audioRecorder.url)
            }))
            
            present(saveAlert, animated: true, completion: nil)
            
        } else {
            print("recording was not saved")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "stopRecording" {
            let playSoundsVC = segue.destination as! PlayEffectsViewController
            let recordedAudioURL = sender as! URL
            playSoundsVC.recordedAudioURL = recordedAudioURL
        }
    }
    
}

