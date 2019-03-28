//
//  ARFGAUserTypePopover.swift
//  ARFollow
//
//  Created by Julius Abarra on 22/11/2017.
//  Copyright © 2017 exZeptional. All rights reserved.
//

import UIKit

protocol ARFGAUserTypePopoverDelegate: class {
    func selectedUserType(_ userType: [String: Any])
}

class ARFGAUserTypePopover: UITableViewController {
    
    weak var delegate: ARFGAUserTypePopoverDelegate?
    var isRegistration = false
    
    fileprivate var userTypeList = [[String: Any]]()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let listA = [["identifier": 0, "description": "Administrator"],
                     ["identifier": 1, "description": "Teacher"],
                     ["identifier": 2, "description": "Student"]]
        
        let listB = [["identifier": 1, "description": "Teacher"],
                     ["identifier": 2, "description": "Student"]]
        
        self.userTypeList = self.isRegistration ? listB : listA
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table View Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.userTypeList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "Cell")
        let userType = self.userTypeList[(indexPath as NSIndexPath).row]
        cell.textLabel?.text = userType["description"] as? String
        
        return cell
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let userType = self.userTypeList[(indexPath as NSIndexPath).row]
        self.dismiss(animated: true, completion: { self.delegate?.selectedUserType(userType) })
    }
}
