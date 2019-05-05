//
//  ViewController.swift
//  VoiceMorph
//
//  Created by Kishan Segu on 4/20/19.
//  Copyright © 2019 Kishan Segu. All rights reserved.
//

import UIKit
import AVFoundation
import FirebaseStorage
import Firebase
class RecordAudioViewController: UIViewController, AVAudioRecorderDelegate {
    
    var audioRecorder: AVAudioRecorder!
    
    @IBOutlet weak var recordingLabel: UILabel!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var stopRecordingButton: UIButton!
    
    
    var recordingName = "";
    var filePath = URL(string: "");
    var loc = ""
    var uploadTask: StorageUploadTask? = nil;
    
    
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
    
    func getData() -> StorageUploadTask {
        return uploadTask!;
    }
    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//    }

    @IBAction func recordAudio(_ sender: Any) {
         recordingLabel.text = "Recording in Progress"
       stopRecordingButton.isEnabled = true
        recordButton.isEnabled = false
        
        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String

        recordingName = NSUUID().uuidString + ".wav";
        
        // recordingName = "recordedAudio.wav";
        let pathArray = [dirPath, recordingName]
        
        loc = pathArray.joined(separator: "/")
        
        filePath = URL(string: pathArray.joined(separator: "/"))!
        // print(filePath!)
        
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
                //var ref: DatabaseReference!

               // ref = Database.database().reference()
                // _ = self.audioRecorder.url
                //You'll get unique audioFile name
               

                let databaseRef = Database.database().reference().child("sounds")
                
                databaseRef.childByAutoId().setValue(["name" : self.recordingName])
                let currentDateTime = NSDate()
                let formatter = DateFormatter()
                formatter.dateFormat = "MM-dd-yyyy"
                databaseRef.childByAutoId().setValue(["date" :  formatter.string(from: currentDateTime as Date)])
                
                
                let storageRef = Storage.storage().reference().child("sounds")
//                let myMetadata  = StorageMetadata()
//                metadata.contentType = "audio/wav"
                let uploadRef = storageRef.child(self.recordingName)
                self.uploadTask = uploadRef.putFile(from: URL(string: "file://" + self.loc)!, metadata: nil) { (metadata, error) in
//                    print("UPLOAD TASK FINISHED")
//                    print(metadata ?? "NO METADATA")
//                    print(error ?? "NO ERROR")
                }
                self.uploadTask?.observe(.progress) { (snapshot) in
//                    print(snapshot.progress ?? "no more progress")
                    
                }
//                uploadTask.observe(.progress) { (snapshot) in
//                    print(snapshot.progress ?? "no more progress")
//                }
//
//                 uploadTask.resume()
//
                
                self.performSegue(withIdentifier: "stopRecording", sender: self.audioRecorder.url)
            }))
            
            saveAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (action: UIAlertAction!) in
                
                
                self.performSegue(withIdentifier: "stopRecording", sender: self.audioRecorder.url)
            }))
            
            present(saveAlert, animated: true, completion: nil)
            
        } else {
//            print("recording was not saved")
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

