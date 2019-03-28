//
//  ARFGPTreasureViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 14/02/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit
import CoreData
import PKHUD
import SDWebImage

class ARFGPTreasureViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate {
    
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var emptyPlaceholderView: UIView!
    @IBOutlet var emptyPlaceholderLabel: UILabel!
    @IBOutlet var backgroundImage: UIImageView!
    
    var playerId: Int64 = 0
    
    fileprivate var collectionRefreshControl: UIRefreshControl!
    fileprivate var blockOperations: [BlockOperation] = []
    fileprivate var treasureCount = 1

    // MARK: - Data Manager
    
    fileprivate lazy var arfDataManager: ARFDataManager = {
        return ARFDataManager.sharedInstance
    }()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Empty navigation bar title by default
        self.navigationBar.topItem?.title = ""
        
        /// Configure background color
        let backgroundColor = ARFConstants.color.GPV_NAV_DASHBOARD
        self.navigationBar.barTintColor = backgroundColor
        self.view.backgroundColor = backgroundColor
        
        /// Hide empty place holder by default
        self.shouldShowEmptyPlaceholderView(false)
        
        /// Handle button event
        self.cancelButton.addTarget(self, action: #selector(self.cancelButtonAction(_:)), for: .touchUpInside)
        
        /// Configure pull to refresh
        let action = #selector(self.refreshTreasureList)
        self.collectionRefreshControl = UIRefreshControl()
        self.collectionRefreshControl.addTarget(self, action: action, for: .valueChanged)
        self.collectionView.addSubview(self.collectionRefreshControl)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /// Request for list of treasures
        self.reloadTreasureList()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Private Methods
    
    /// Renders retrieved list of treasures from database on the
    /// table view as the view has loaded.
    @objc fileprivate func reloadTreasureList() {
        HUD.show(.rotatingImage(ARFConstants.image.GEN_PROGRESS))
         
        self.arfDataManager.requestRetrieveUnlockedTreasures(forPlayerWithId: "\(self.playerId)") { (result) in
            let status = result!["status"] as! Int
            
            if status == 0 {
                DispatchQueue.main.async {
                    let count = result!["count"] as! Int
                    self.treasureCount = count
                    self.navigationBar.topItem?.title = "Assets (\(count))"
                    
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
    
    /// Renders retrieved list of treasures from database on the
    /// table view as user pulls the table view.
    @objc fileprivate func refreshTreasureList() {
        self.arfDataManager.requestRetrieveUnlockedTreasures(forPlayerWithId: "\(self.playerId)") { (result) in
            let status = result!["status"] as! Int
            
            if status == 0 {
                DispatchQueue.main.async {
                    let count = result!["count"] as! Int
                    self.treasureCount = count
                    self.navigationBar.topItem?.title = "Assets (\(count))"
                    
                    self.collectionRefreshControl.endRefreshing()
                    self.reloadFetchedResultsController()
                }
            }
            else {
                DispatchQueue.main.async {
                    self.collectionRefreshControl.endRefreshing()
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
    /// requests for treasure list.
    ///
    /// - parameter show: A Bool (true or false)
    fileprivate func shouldShowEmptyPlaceholderView(_ show: Bool) {
        self.emptyPlaceholderView.isHidden = !show
        self.collectionView.isHidden = show
    }
    
    // MARK: - Collection View Data Source
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let sectionCount = fetchedResultsController.sections?.count else { return 0 }
        return sectionCount
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let sectionData = fetchedResultsController.sections?[section] else { return 0 }
        self.shouldShowEmptyPlaceholderView((sectionData.numberOfObjects > 0) ? false : true)
        return sectionData.numberOfObjects
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellIdentifier = ARFConstants.cellIdentifier.TREASURE
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! ARFGPTreasureCollectionViewCell
        let treasureObject = fetchedResultsController.object(at: indexPath) as! Treasure
        let imageUrl = treasureObject.imageUrl!
        
        cell.treasureNameLabel.text = treasureObject.name!
        cell.backView.layer.borderColor = UIColor.darkGray.cgColor
        cell.backView.layer.borderWidth = 2
        
        cell.treasureImage.sd_setImage(with: URL(string: imageUrl), completed: { (image, error, type, url) in
            cell.treasureImage.image = image != nil ? image! : ARFConstants.image.GCV_UNKNOWN_TREASURE
        })
        
        return cell
    }
    
    // MARK: - Collection View Delegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let treasureObject = fetchedResultsController.object(at: indexPath) as! Treasure
        let data: [String: Any] = ["treasure": treasureObject]
        self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GPV_TREASURE_AR_VIEW, sender: data)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 80
        let width = collectionView.frame.size.width - padding
        return CGSize(width: width / 2, height: 150)
    }
    
    // MARK: - Fetched Results Controller
    
    fileprivate var _fetchedResultsController: NSFetchedResultsController<NSManagedObject>? = nil
    
    fileprivate var fetchedResultsController: NSFetchedResultsController<NSManagedObject> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let ctx = self.arfDataManager.db.retrieveObjectMainContext()
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest<NSManagedObject>(entityName: ARFConstants.entity.TREASURE)
        fetchRequest.fetchBatchSize = 20
        
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: ctx!, sectionNameKeyPath: nil, cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        }
        catch _ as NSError {
            abort()
        }
        
        return _fetchedResultsController!
    }
    
    fileprivate func addProcessingBlock(_ processingBlock:@escaping ()->Void) {
        self.blockOperations.append(BlockOperation(block: processingBlock))
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.blockOperations.removeAll(keepingCapacity: false)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { return }
            self.addProcessingBlock { [weak self] in self?.collectionView.insertItems(at: [newIndexPath]) }
            
        case .update:
            guard let newIndexPath = newIndexPath else { return }
            self.addProcessingBlock { [weak self] in self?.collectionView.reloadItems(at: [newIndexPath]) }
            
        case .move:
            guard let indexPath = indexPath else { return }
            guard let newIndexPath = newIndexPath else { return }
            self.addProcessingBlock { [weak self] in self?.collectionView.moveItem(at: indexPath, to: newIndexPath) }
            
        case .delete:
            guard let indexPath = indexPath else { return }
            self.addProcessingBlock { [weak self] in self?.collectionView.deleteItems(at: [indexPath]) }
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        switch type {
        case .insert:
            self.addProcessingBlock { [weak self] in self?.collectionView.insertSections(IndexSet(integer: sectionIndex)) }
            
        case .update:
            self.addProcessingBlock { [weak self] in self?.collectionView.reloadSections(IndexSet(integer: sectionIndex)) }
            
        case .delete:
            self.addProcessingBlock { [weak self] in self?.collectionView.deleteSections(IndexSet(integer: sectionIndex)) }
            
        default: break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.collectionView.performBatchUpdates({
            self.blockOperations.forEach { $0.start() }
        }, completion: { finished in
            self.blockOperations.removeAll(keepingCapacity: false)
        })
    }
    
    func reloadFetchedResultsController() {
        self._fetchedResultsController = nil
        self.collectionView.reloadData()
        
        var error: NSError? = nil
        
        do {
            try self.fetchedResultsController.performFetch()
        }
        catch let error1 as NSError {
            error = error1
            print(error?.localizedDescription ?? "")
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == ARFConstants.segueIdentifier.GPV_TREASURE_AR_VIEW {
            guard let data = sender as? [String: Any], let treasure = data["treasure"] as? Treasure else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let treasure3DView = segue.destination as! ARFGPTreasure3DViewController
            treasure3DView.treasure = treasure
        }
        
    }

}
