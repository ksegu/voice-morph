//
//  SavedRecordingsViewController.swift
//  VoiceMorph
//
//  Created by Kishan Segu on 4/28/19.
//  Copyright © 2019 Kishan Segu. All rights reserved.
//

import UIKit

import Firebase
import AVFoundation

class SavedRecordingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var arr: [String] = []
    
    @IBOutlet weak var table: UITableView!
    
    var audioPlayer:AVAudioPlayer = AVAudioPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        table.delegate = self
        table.dataSource = self
        
        getFromFirebase()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true);
        getFromFirebase()
    }
    
    func getFromFirebase() {
        let dataRef = Database.database().reference().queryOrdered(byChild: "sounds")
        var temp = [String]()
        
        
        dataRef.observeSingleEvent(of: .childAdded) { (snapshot) in
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                    let dict = childSnapshot.value as? [String : Any] {
                    temp.append(dict["name"] as? String ?? "ERROR")
                }
            }
            self.arr = temp
            self.table.reloadData()
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Number of rows to be listed for my recordings

        return arr.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        

        let soundCell = tableView.dequeueReusableCell(withIdentifier: "soundCell", for: indexPath)
        
        
        soundCell.textLabel!.text = arr[indexPath.row]
        
                let currentDateTime = NSDate()
                let formatter = DateFormatter()
                formatter.dateFormat = "MM-dd-yyyy"
        
       // formatter.string(from: currentDateTime as Date)
        soundCell.detailTextLabel!.text = formatter.string(from: currentDateTime as Date)

        
       //  let uploadRef = RecordAudioViewController().getData()
        
//        storageRef.observe(CFStreamEventType.value,with:{(snapshot) in
//            if snapshot.childrenCount > 0 {
//                for audioFile in snapshot.children.allObjects as!CFStreamEventType {
//
//                }
//            }
//        })
//
//            uploadRef.observe(.progress) { (snapshot) in
//                    print(snapshot.progress ?? "no more progress")
//            }
//
//            uploadRef.resume()
//

        
        return soundCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let nameOfFile = arr[indexPath.row]
        
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(nameOfFile)

        let storageRef = Storage.storage().reference().child("sounds").child(nameOfFile)
        
        
            storageRef.getData(maxSize: 128 * 1024 * 1024) { (data, error) in
                if let error = error {
                    print(error)
                } else {
                    
                    if let d = data {
                        print("got data")
                        do {
                            try d.write(to: fileURL)
                            
                            self.audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
                            self.audioPlayer.delegate = self as? AVAudioPlayerDelegate
                            self.audioPlayer.prepareToPlay()
                            self.audioPlayer.play()
                           
                        } catch {
                            print(error)
                        }
                    }
                }
        }
    }
}
