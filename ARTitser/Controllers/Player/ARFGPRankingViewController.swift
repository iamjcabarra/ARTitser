//
//  ARFGPRankingViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 14/02/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit
import CoreData
import PKHUD
import SDWebImage

class ARFGPRankingViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var backgroundImage: UIImageView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var emptyPlaceholderView: UIView!
    @IBOutlet var emptyPlaceholderLabel: UILabel!

    var playerId: Int64 = 0
    fileprivate var tableRefreshControl: UIRefreshControl!

    // MARK: - Data Manager
    
    fileprivate lazy var arfDataManager: ARFDataManager = {
        return ARFDataManager.sharedInstance
    }()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Configure navigation bar
        self.navigationBar.topItem?.title = "Ranking"
        
        /// Configure background color
        let backgroundColor = ARFConstants.color.GPV_NAV_DASHBOARD
        self.navigationBar.barTintColor = backgroundColor
        self.view.backgroundColor = backgroundColor
        
        /// Hide empty place holder by default
        self.shouldShowEmptyPlaceholderView(false)
        
        /// Handle button event
        self.cancelButton.addTarget(self, action: #selector(self.cancelButtonAction(_:)), for: .touchUpInside)
        
        /// Request for list of clues
        self.reloadPlayerList()
        
        /// Configure pull to refresh
        let action = #selector(self.refreshPlayerList)
        self.tableRefreshControl = UIRefreshControl()
        self.tableRefreshControl.addTarget(self, action: action, for: .valueChanged)
        self.tableView.addSubview(self.tableRefreshControl)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Private Methods
    
    /// Renders retrieved list of players from database on the
    /// table view as the view has loaded.
    @objc fileprivate func reloadPlayerList() {
        HUD.show(.rotatingImage(ARFConstants.image.GEN_PROGRESS))
        
        self.arfDataManager.requestRetrievePlayers { (result) in
            let status = result!["status"] as! Int
            
            if status == 0 {
                DispatchQueue.main.async {
                    HUD.hide()
                    self.reloadFetchedResultsController()
                }
            }
            else {
                DispatchQueue.main.async {
                    HUD.hide()
                    let subtitle = result!["message"] as! String
                    HUD.flash(.labeledError(title: "Oops!", subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in })
                }
            }
        }
    }
    
    /// Renders retrieved list of players from database on the
    /// table view as user pulls the table view.
    @objc fileprivate func refreshPlayerList() {
        self.arfDataManager.requestRetrievePlayers { (result) in
            let status = result!["status"] as! Int
            
            if status == 0 {
                DispatchQueue.main.async {
                    self.tableRefreshControl.endRefreshing()
                    self.reloadFetchedResultsController()
                }
            }
            else {
                DispatchQueue.main.async {
                    self.tableRefreshControl.endRefreshing()
                    let subtitle = result!["message"] as! String
                    HUD.flash(.labeledError(title: "Oops!", subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in })
                }
            }
        }
    }
    
    // MARK: - Button Event Handlers
    
    /// Goes back to the previous view.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func cancelButtonAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Empty Placeholder View
    
    /// Shows or hides empty place holder view as user
    /// requests for player list.
    ///
    /// - parameter show: A Bool (true or false)
    fileprivate func shouldShowEmptyPlaceholderView(_ show: Bool) {
        self.emptyPlaceholderView.isHidden = !show
        self.tableView.isHidden = show
    }
    
    // MARK: - Table View Data Source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        guard let sectionCount = fetchedResultsController.sections?.count else { return 0 }
        return sectionCount
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionData = fetchedResultsController.sections?[section] else { return 0 }
        self.shouldShowEmptyPlaceholderView((sectionData.numberOfObjects > 0) ? false : true)
        return sectionData.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ARFConstants.cellIdentifier.RANKING, for: indexPath) as! ARFGPRankingTableViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        cell.selectionStyle = .none
        return cell
    }
    
    func configureCell(_ cell: ARFGPRankingTableViewCell, atIndexPath indexPath: IndexPath) {
        let playerObject = fetchedResultsController.object(at: indexPath) as! PlayerRanking
        let id = playerObject.playerId
        let imageUrl = playerObject.playerImageUrl!
        
        cell.rankLabel.text = "\(indexPath.row + 1)"
        cell.playerNameLabel.text = playerObject.playerName!
        cell.pointsLabel.text = "\(playerObject.points)"
        cell.levelLabel.text = "Level \(playerObject.level)"
        
        cell.playerImage.sd_setImage(with: URL(string: imageUrl), completed: { (image, error, type, url) in
            cell.playerImage.image = image != nil ? image! : ARFConstants.image.GEN_UNKNOWN_USER
        })
        
        cell.backView.layer.borderColor = id == self.playerId ? UIColor.yellow.cgColor : UIColor.darkGray.cgColor
        cell.backView.layer.borderWidth = 2
    }
    
    // MARK: - Fetched Results Controller
    
    fileprivate var _fetchedResultsController: NSFetchedResultsController<NSManagedObject>? = nil
    
    fileprivate var fetchedResultsController: NSFetchedResultsController<NSManagedObject> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let ctx = self.arfDataManager.db.retrieveObjectMainContext()
        
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest<NSManagedObject>(entityName: ARFConstants.entity.PLAYER_RANKING)
        fetchRequest.fetchBatchSize = 20
       
        let sortDescriptor = NSSortDescriptor(key: "points", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: ctx!, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        
        _fetchedResultsController = frc
        
        do {
            try _fetchedResultsController!.performFetch()
        }
        catch {
            abort()
        }
        
        return _fetchedResultsController!
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        switch type {
        case .insert:
            self.tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            self.tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            return
        }
        
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch (type) {
        case .insert:
            if let indexPath = newIndexPath {
                self.tableView.insertRows(at: [indexPath], with: .fade)
            }
            break;
        case .delete:
            if let indexPath = indexPath {
                self.tableView.deleteRows(at: [indexPath], with: .fade)
            }
            break;
        case .update:
            if let indexPath = indexPath {
                if let cell = self.tableView.cellForRow(at: indexPath) {
                    self.configureCell(cell as! ARFGPRankingTableViewCell, atIndexPath: indexPath)
                }
            }
            break;
        case .move:
            if let indexPath = indexPath {
                self.tableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            if let newIndexPath = newIndexPath {
                self.tableView.insertRows(at: [newIndexPath], with: .fade)
            }
            break;
        }
        
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }
    
    func reloadFetchedResultsController() {
        self._fetchedResultsController = nil
        self.tableView.reloadData()
        
        do {
            try _fetchedResultsController!.performFetch()
        }
        catch let error as NSError {
            print(error.localizedDescription)
        }
    }


}
