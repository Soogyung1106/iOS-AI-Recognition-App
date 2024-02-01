//
//  MainViewController.swift
//  ai app
//
//  Created by 정수경 on 2024/02/01.
//

import UIKit

class MainViewController: UIViewController, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    let dataArray = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.dataSource = self
        // Do any additional setup after loading the view.
    }
    
    
    //UITableViewDataSource 프로토콜 구현
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "numberCell", for: indexPath)
        cell.textLabel?.text = self.dataArray[indexPath.row]
        
        return cell
    }
    
    
}
