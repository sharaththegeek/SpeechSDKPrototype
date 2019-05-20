//
//  ViewController.swift
//  Voice Prototype
//
//  Created by Sharath on 16/05/19.
//  Copyright © 2019 Sharath. All rights reserved.
//

import UIKit
import Speech

public class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    @IBOutlet weak var recordButton: UIButton!
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
 
    @IBOutlet weak var voiceText: UITextView!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    @IBAction func buttonTapped(_ sender: UIButton) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recordButton.isEnabled = false
            recordButton.setImage(UIImage(named:"start.png"), for: .normal)
        } else {
            do {
                try startRecording()
                recordButton.setImage(UIImage(named:"stop.png"), for: .normal)
            } catch {
            }
        }
    }
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        recordButton.isEnabled = false
        
       
    }
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        speechRecognizer.delegate = self
        self.voiceText.text="Checking!"
        SFSpeechRecognizer.requestAuthorization{ authStatus in
            
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.recordButton.isEnabled = true
                    self.voiceText.text="Let's check"
                case .denied:
                    self.recordButton.isEnabled = false
                    self.recordButton.setImage(UIImage(named:"error.png"), for: .normal)
                    
                case .restricted:
                    self.recordButton.isEnabled = false
                    self.recordButton.setImage(UIImage(named:"error.png"), for: .normal)
                    
                case .notDetermined:
                    self.recordButton.isEnabled = false
                    self.recordButton.setImage(UIImage(named:"error.png"), for: .normal)
                @unknown default:
                    fatalError()
                }
            }
        }
    }
    private func startRecording() throws {
        // Cancel the previous task if it's running.
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        // Configure the audio session for the app.
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let inputNode = audioEngine.inputNode
        
        // Create and configure the speech recognition request.
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        recognitionRequest.shouldReportPartialResults = true
        
        // Create a recognition task for the speech recognition session.
        // Keep a reference to the task so that it can be canceled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                // Update the text view with the results.
                self.voiceText.text = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                // Stop recognizing speech if there is a problem.
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.recordButton.isEnabled = true
            }
        }
        
        // Configure the microphone input.
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        // Let the user know to start talking.
        voiceText.text = "Go ahead, I'm listening"
    }
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            recordButton.isEnabled = true
            recordButton.setImage(UIImage(named:"start.png"), for: .normal)
        } else {
            recordButton.isEnabled = false
            recordButton.setImage(UIImage(named:"error.png"), for: .normal)
        }
    }

}

