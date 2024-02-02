//
//  MainViewController.swift
//  ai app
//
//  Created by 정수경 on 2024/02/01.
//

import UIKit

class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    let sampleData = SampleData()
    
    //viewDidLoad 펑션
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }
    
    //viewWillAppear / viewWillDisappear - 네비게이션 바 크기 조절
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    //UITableViewDataSource 프로토콜 구현
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sampleData.samples.count
    }
    
    //테이블 뷰
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mainFeatureCell", for: indexPath) as! MainFeatureCell
        
        let sample = self.sampleData.samples[indexPath.row]
        cell.titleLabel.text = sample.title
        cell.descriptionLabel.text = sample.description
        cell.featureImageView.image = UIImage(named: sample.image)
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("log: \(indexPath.row)번째 열이 선택됨")
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0:
            self.performSegue(withIdentifier: "photoObjectDetection", sender: nil)
        case 1:
            self.performSegue(withIdentifier: "realTimeObjectDetection", sender: nil)
        case 2:
            self.performSegue(withIdentifier: "facialAnalysis", sender: nil)
        default:
            return
        }
    }
    
    
}
