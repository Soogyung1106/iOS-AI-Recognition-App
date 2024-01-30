//
//  MyFirstViewController.swift
//  ai app
//
//  Created by 정수경 on 2024/01/29.
//

import UIKit

class MyFirstViewController: UIViewController {

    @IBOutlet weak var myLabel: UILabel!
    @IBOutlet weak var myButton: UIButton!
    @IBOutlet weak var myLabel2: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    @IBAction func buttonPressed(_ sender: UIButton) {
        print("log : button pressed")
        self.myLabel.text = "Hello Swift"
    }
    
    
    @IBAction func switchChanged(_ sender: UISwitch) {
        
        if sender.isOn{
            print("log : switch is on")
            self.myLabel2.text = "switch is on"
        }else{
            print("log : switch is off")
            self.myLabel2.text = "switch is off"
        }
        
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
