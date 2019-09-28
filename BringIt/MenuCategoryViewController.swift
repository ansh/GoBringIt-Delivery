//
//  MenuCategoryViewController.swift
//  BringIt
//
//  Created by Alexander's MacBook on 5/18/17.
//  Copyright © 2017 Campus Enterprises. All rights reserved.
//

import UIKit
import RealmSwift
import SkeletonView

class MenuCategoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SkeletonTableViewDataSource, UIAdaptivePresentationControllerDelegate {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var viewCartButton: UIButton!
    @IBOutlet weak var cartSubtotal: UILabel!
    @IBOutlet weak var viewCartButtonView: UIView!
    @IBOutlet weak var viewCartView: UIView!
    @IBOutlet weak var viewCartViewToBottom: NSLayoutConstraint!
    
    // MARK: - Variables
    
    let defaults = UserDefaults.standard // Initialize UserDefaults
    
    var menuCategoryID = ""
    var menuCategoryName = ""
    var restaurantID = ""
    var restaurant = Restaurant()
    var menuCategory = MenuCategory()
    var cart = Order()
    var menuItems = [MenuItem]()
    var selectedMenuItemID = ""
    var selectedMenuItem = MenuItem()

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        // Setup Realm
        setupRealm()
        
        // Setup UI
        setupUI()
        
        // Setup tableview
        setupTableView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        // Check if there is a cart to display
        checkCart()
    }
    
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        checkCart()
    }
    
    func setupUI() {
        
        setCustomBackButton()
        
        self.title = menuCategoryName
        
        viewCartButtonView.layer.cornerRadius = Constants.cornerRadius
        viewCartView.backgroundColor = UIColor.white
        self.viewCartView.layer.shadowColor = Constants.lightGray.cgColor
        self.viewCartView.layer.shadowOpacity = 0.15
        self.viewCartView.layer.shadowRadius = Constants.shadowRadius
        checkCart()
//        viewCartViewToBottom.constant = viewCartView.frame.height // start offscreen
    }
    
    func setupRealm() {
        
//        let realm = try! Realm() // Initialize Realm
        
        fetchMenuItems(menuCategoryID: menuCategoryID)
        
        // Get selected restaurant and menu categories
//        menuCategory = realm.object(ofType: MenuCategory.self, forPrimaryKey: menuCategoryID)!
//        menuItems = menuCategory.menuItems.sorted(byKeyPath: "name")
        
    }
    
    func setupTableView() {
        
        // Set tableView cells to custom height and automatically resize if needed
        self.myTableView.delegate = self
        self.myTableView.dataSource = self
        self.myTableView.estimatedRowHeight = 150
        self.myTableView.rowHeight = UITableView.automaticDimension
        self.myTableView.setNeedsLayout()
        self.myTableView.layoutIfNeeded()
        
        self.myTableView.startSkeletonAnimation()
        self.myTableView.showAnimatedSkeleton()
    }
    
    func checkCart() {
        
        let realm = try! Realm() // Initialize Realm
        
        let predicate = NSPredicate(format: "restaurantID = %@ AND isComplete = %@", restaurantID, NSNumber(booleanLiteral: false))
        let filteredOrders = realm.objects(Order.self).filter(predicate)
        if filteredOrders.count > 0 {
            viewCartView.isHidden = false
            print("Cart exists. Showing View Cart button")
            
            cart = filteredOrders.first!
            print(cart.subtotal)
            print(cart.restaurantID)
            print(cart.menuItems)
            
            cartSubtotal.text = "$" + String(format: "%.2f", cart.subtotal)

        } else {
            
            print("Cart does not exist. Hide View Cart button")
            viewCartView.isHidden = true
//            viewCartViewToBottom.constant = viewCartView.frame.height
        }

        UIView.animate(withDuration: 0.4, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    @IBAction func viewCartButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "toCheckoutFromMenuCategory", sender: self)
    }

    
    // MARK: - Table view data source
    
    func numSections(in collectionSkeletonView: UITableView) -> Int {
        return 1
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {

        return "menuItemCell"
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        if menuItems != nil {
//            return menuItems.count
//        }
        return menuItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let realm = try! Realm() // Initialize Realm
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "menuItemCell", for: indexPath) as! MenuItemTableViewCell
        
        cell.name.text = menuItems[indexPath.row].name
        cell.details.text = menuItems[indexPath.row].details
        let price = menuItems[indexPath.row].price
        cell.price.text = "$" + String(format: "%.2f", price)
        cell.tag = indexPath.row
        
        let image = menuItems[indexPath.row].image
        if image != nil {
            
            print("Image is already saved at index: \(indexPath.row).")
            
            cell.menuImage.image = UIImage(data: image! as Data)
        } else {
            
            let imageURL = menuItems[indexPath.row].imageURL
            if imageURL != "" {
                
                print("Image is not yet saved. Downloading asynchronously.")
                
                DispatchQueue.global(qos: .background).async {
                    let url = URL(string: imageURL)
                    let imageData = NSData(contentsOf: url!)
                    
                    DispatchQueue.main.async {
                        // Cache image
                        let realm = try! Realm() // Initialize Realm
                        try! realm.write {
                            self.menuItems[indexPath.row].image = imageData
                        }
                        
                        // Set image to downloaded asset only if cell is still visible
                        cell.menuImage.alpha = 0
                        if imageURL == self.menuItems[indexPath.row].imageURL && imageData != nil {
                            cell.menuImage.image = UIImage(data: imageData! as Data)
                            UIView.animate(withDuration: 0.3) {
                                cell.menuImage.alpha = 1
                            }
                        }
                    }
                }
            } else {
                print("Image does not exist.")
                cell.menuImage.image = nil
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        print("MENU ITEMS: \(menuItems)")
        
//        selectedMenuItemID = menuItems[indexPath.row].id
        if menuItems.count > 0 {
            selectedMenuItem = menuItems[indexPath.row]
        }
        
        return indexPath
    }
    
    public func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.font = Constants.headerFont
        header.textLabel?.textColor = UIColor.systemGray
        header.textLabel?.textAlignment = .left
        header.backgroundView?.backgroundColor = UIColor.white
        header.textLabel?.text = header.textLabel?.text?.uppercased()
        
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        myTableView.deselectRow(at: indexPath, animated: true)
        if menuItems.count > 0 {
            performSegue(withIdentifier: "toAddToCart", sender: self)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.hideSkeleton()
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "toAddToCart" {
            let nav = segue.destination as! UINavigationController
            let addToCartVC = nav.topViewController as! AddToCartVC
            addToCartVC.menuItemID = selectedMenuItemID
            addToCartVC.restaurantID = restaurantID
            addToCartVC.menuItem = selectedMenuItem
            addToCartVC.deliveryFee = restaurant.deliveryFee
            addToCartVC.presentationController?.delegate = self
        } else if segue.identifier == "toCheckoutFromMenuCategory" {
            
            let nav = segue.destination as! UINavigationController
            let checkoutVC = nav.topViewController as! CheckoutVC
//            checkoutVC.restaurantID = restaurantID
            checkoutVC.restaurant = restaurant
        }
    }

}
