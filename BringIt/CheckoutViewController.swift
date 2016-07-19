//
//  CheckoutViewController.swift
//  BringIt
//
//  Created by Alexander's MacBook on 5/26/16.
//  Copyright © 2016 Campus Enterprises. All rights reserved.
//

import UIKit

// TO-DO: Add special delivery cost cell?
// Add return segues to both viewcontrollers
// Add segues to deliverTo and payWith
// Add rest of IBOutlets and make them dynamic

var comingFromOrderPlaced = false

class CheckoutViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - IBOutlets
    @IBOutlet weak var itemsTableView: UITableView!
    @IBOutlet weak var detailsTableView: UITableView!
    @IBOutlet weak var itemsTableViewHeight: NSLayoutConstraint!
    //@IBOutlet weak var ETALabel: UILabel!
    @IBOutlet weak var deliveryFeeLabel: UILabel!
    @IBOutlet weak var subtotalCostLabel: UILabel!
    @IBOutlet weak var totalCostLabel: UILabel!
    
    var cameFromVC = ""
    var deliverTo = ""
    var payWith = ""
    var totalCost = 0.0
    var selectedCell = 0
    var deliveryFee = 2.5 // CHAD!!!! PLEASE PULL THE DELIVERY FEE AND STORE IT HEREEEE (It is different for a couple restaurants so this is needed)
    
    // Data structure
    struct Item {
        var name = ""
        var quantity = 0
        var price = 0.00
    }
    
    // FOR CHAD - Uncomment this when you finish the data loading
    // var items = [Item]()
    // FOR CHAD - Delete this when you finish the data loading
    let items = [Item(name: "The Carolina Cockerel", quantity: 2, price: 10.00), Item(name: "Chocolate Milkshake", quantity: 1, price: 4.99), Item(name: "Large Fries", quantity: 2, price: 3.00)]
    
    // Get USER ID
    let defaults = NSUserDefaults.standardUserDefaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set title
        self.title = "Checkout"
        
        // Set nav bar preferences
        self.navigationController?.navigationBar.tintColor = UIColor.darkGrayColor()
        navigationController!.navigationBar.titleTextAttributes =
            ([NSFontAttributeName: TITLE_FONT,
                NSForegroundColorAttributeName: UIColor.blackColor()])
        
        // Set custom back button
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        
        // TO-DO: - LOAD CART DATA FROM DB
        // FOR CHAD
        // Write code hereeeee
        // Suggestion: Use the struct I created to structure the data. So use a for loop to loop through the items in the db cart and then put each in items[i].name or items[i].quantity or items[i].price

        // Get Address of User
       // var userID: String?
        let userID = self.defaults.objectForKey("userID") as AnyObject! as! String
        
        var addressString: String?
        
        // Open Connection to PHP Service
        let requestURL: NSURL = NSURL(string: "http://www.gobring.it/CHADaccountAddresses.php")!
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(URL: requestURL)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(urlRequest) { (data, response, error) -> Void in
            if let data = data {
                do {
                    let httpResponse = response as! NSHTTPURLResponse
                    let statusCode = httpResponse.statusCode
                    
                    // Check HTTP Response
                    if (statusCode == 200) {
                        
                        do{
                            // Parse JSON
                            let json = try NSJSONSerialization.JSONObjectWithData(data, options:.AllowFragments)
                            
                            for Restaurant in json as! [Dictionary<String, AnyObject>] {
                                //var account_id: String?
                                let account_id = Restaurant["account_id"] as! String
                                    if ( account_id.rangeOfString(userID) != nil ) {
                                        print(userID)
                                        print(Restaurant["street"] as? String)
                                        let street = Restaurant["street"] as AnyObject! as! String //+ ", " + Restaurant["apartment"] as AnyObject! as! String
                                        let apartment = Restaurant["apartment"] as AnyObject! as! String
                                        addressString = street + ", " + apartment
                                    }
                                }
                            NSOperationQueue.mainQueue().addOperationWithBlock {
                                print(addressString!)
                                self.deliverTo = addressString!
                                self.detailsTableView.reloadData()
                            }
                        }
                    }
                } catch let error as NSError {
                    print("Error:" + error.localizedDescription)
                }
            } else if let error = error {
                print("Error:" + error.localizedDescription)
            }
        }
        
        task.resume()

        // Set SAMPLE DATA
        //deliverTo = "1369 Campus Drive"
        payWith = "Food Points"
        
        // Calculate and display totalCost
        calculateTotalCost()
        subtotalCostLabel.text = String(format: "$%.2f", totalCost)
        totalCostLabel.text = String(format: "$%.2f", totalCost + deliveryFee)

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(animated: Bool) {
        if comingFromOrderPlaced == true {
            comingFromOrderPlaced = false
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func calculateTotalCost() {
        for item in items {
            totalCost += Double(item.price) * Double(item.quantity)
        }
    }

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == itemsTableView {
            return items.count
        } else {
            return 2
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if tableView == itemsTableView {
            let cell = tableView.dequeueReusableCellWithIdentifier("checkoutCell", forIndexPath: indexPath) as! CheckoutTableViewCell
            
            cell.itemNameLabel.text = items[indexPath.row].name
            cell.itemQuantityLabel.text = String(items[indexPath.row].quantity)
            let totalItemCost = Double(items[indexPath.row].quantity) * items[indexPath.row].price
            cell.totalCostLabel.text = String(format: "%.2f", totalItemCost)
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("checkoutDetailsCell", forIndexPath: indexPath)
            
            if indexPath.row == 0 {
                cell.textLabel?.text = "Deliver To"
                cell.detailTextLabel?.text = deliverTo
            } else {
                cell.textLabel?.text = "Pay With"
                cell.detailTextLabel?.text = payWith
            }
            
            return cell
        }
    }
    
    // Resize itemsTableView
    override func updateViewConstraints() {
        super.updateViewConstraints()
        itemsTableViewHeight.constant = itemsTableView.contentSize.height
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
    
    // Find out which cell was selected and sent to prepareForSegue
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        selectedCell = indexPath.row
        
        return indexPath
    }

    @IBAction func xButtonPressed(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true);
        
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "prepareForUnwind" {
            let VC = segue.destinationViewController as! MenuTableViewController
            VC.backToVC = cameFromVC
        } else if segue.identifier == "toDeliverToPayingWith" {
            let VC = segue.destinationViewController as! DeliverToPayingWithTableViewController
            if self.selectedCell == 0 {
                VC.selectedCell = "Deliver To"
            } else if self.selectedCell == 1 {
                VC.selectedCell = "Paying With"
            }
        }
    }

}
