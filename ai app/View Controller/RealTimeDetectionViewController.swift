//
//  RealTimeDetectionViewController.swift
//  ai app
//
//  Created by 정수경 on 2/5/24.
//

import UIKit
import Vision

class RealTimeDetectionViewController: UIViewController {
 
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    

    var videoCapture: VideoCapture!
    let visionRequestHandler = VNSequenceRequestHandler()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //라벨 초기값 설정
        self.categoryLabel.text = ""
        self.confidenceLabel.text = ""
        
        let spec = VideoSpec(fps: 3, size: CGSize(width: 1280, height: 720))
        self.videoCapture = VideoCapture(cameraType : .back, preferredSpec: spec, previewContainer: self.cameraView.layer)
        
         //인식하는 이미지가 바뀔때마다 detectObject 펑션 호출
        self.videoCapture.imageBufferHandler = { (imageBuffer, timestamp, outputBuffer) in
            self.detectObject(image: imageBuffer)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let videoCapture = self.videoCapture{
            videoCapture.startCapture()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let videoCapture = self.videoCapture{
            videoCapture.stopCapture()
        }
    }
    
    //사물 인식 펑션
    func detectObject(image: CVImageBuffer){
        do{
            let vnCoreMLModel = try VNCoreMLModel(for: Inceptionv3().model)
            let request = VNCoreMLRequest(model: vnCoreMLModel, completionHandler: self.handleObjectDetection)
            request.imageCropAndScaleOption = .centerCrop
            try self.visionRequestHandler.perform([request], on: image)
        }catch{
            print(error)
        }
    }
    
    func handleObjectDetection(request: VNRequest, error: Error?){
        if let result = request.results?.first as? VNClassificationObservation{
            //print("실시간 사물 인식 log : \(result.identifier) : \(result.confidence)")
            
            //UI 관련된 코드는 메인 쓰레드에서 실행
            DispatchQueue.main.async {
                self.categoryLabel.text = result.identifier
                self.confidenceLabel.text = "\(String(format: "%.2f",  result.confidence*100))%"
            }
            
         }
    }
}
