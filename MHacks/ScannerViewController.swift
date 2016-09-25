//
//  ScannerViewController.swift
//  MHacks
//
//  Created by Russell Ladd on 9/21/16.
//  Copyright © 2016 MHacks. All rights reserved.
//

import UIKit

protocol ScannerViewControllerDelegate: class {
    
    func scannerViewControllerDidFinish(scannerViewController: ScannerViewController)
}

final class ScannerViewController: UIViewController, ScannerViewDelegate {
    
    // MARK: Model
    
    enum InputMode: Int {
        case list = 0
        case scan = 1
    }
    
    var inputMode = InputMode.scan {
        didSet {
            updateViews()
        }
    }
    
    var currentScanEvent = APIManager.shared.scanEvents.first {
        didSet {
            updateEventsBarButtonItemTitle()
        }
    }
    
    var currentIdentifier: String? {
        didSet {
            updateUserView()
            updateToolbarItems(animated: true)
        }
    }
    
    // MARK: Delegate
    
    weak var delegate: ScannerViewControllerDelegate?
    
    // MARK: Views
    
    let inputModeControl = UISegmentedControl(items: ["List", "Scan"])
    
    let eventsBarButtonItem = UIBarButtonItem(title: "Loading", style: .plain, target: nil, action: nil)
    let confirmationBarButtonItem = UIBarButtonItem(title: "Confirm", style: .done, target: nil, action: nil)
    
    let tableView = UITableView(frame: CGRect.zero, style: .plain)
    let scannerView = ScannerView()
    
    let userBackgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
    
    final class DoubleLabel: UIStackView {
        
        init() {
            super.init(frame: CGRect.zero)
            
            addArrangedSubview(titleLabel)
            addArrangedSubview(textLabel)
            
            axis = .vertical
            alignment = .leading
            
            titleLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        }
        
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        let titleLabel = UILabel()
        let textLabel = UILabel()
    }
    
    let nameLabel = DoubleLabel()
    let emailLabel = DoubleLabel()
    let schoolLabel = DoubleLabel()
    let mentorLabel = DoubleLabel()
    let minorLabel = DoubleLabel()
    let shirtSizeLabel = DoubleLabel()
    
    // MARK: View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // View
        
        view.backgroundColor = UIColor.white
        
        // Bars
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Finish", style: .plain, target: self, action: #selector(finish))
        
        navigationItem.titleView = inputModeControl
        
        inputModeControl.selectedSegmentIndex = 1
        inputModeControl.addTarget(self, action: #selector(inputModeControlValueChanged), for: .valueChanged)
        
        eventsBarButtonItem.target = self
        eventsBarButtonItem.action = #selector(selectScanEvent)
        
        confirmationBarButtonItem.target = self
        confirmationBarButtonItem.action = #selector(confirmUser)
        
        // Table view
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        // Scanner view
        
        scannerView.translatesAutoresizingMaskIntoConstraints = false
        scannerView.delegate = self
        view.addSubview(scannerView)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(cancelUserScan))
        scannerView.addGestureRecognizer(tapGestureRecognizer)
        
        userBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(userBackgroundView)
        
        let userStackView = UIStackView(arrangedSubviews: [nameLabel, emailLabel, schoolLabel, mentorLabel, minorLabel, shirtSizeLabel])
        userStackView.translatesAutoresizingMaskIntoConstraints = false
        userStackView.axis = .vertical
        userStackView.spacing = 15.0
        
        userBackgroundView.contentView.addSubview(userStackView)
        
        nameLabel.titleLabel.text = "NAME"
        emailLabel.titleLabel.text = "EMAIL"
        schoolLabel.titleLabel.text = "SCHOOL"
        mentorLabel.titleLabel.text = "MENTOR"
        minorLabel.titleLabel.text = "MINOR"
        shirtSizeLabel.titleLabel.text = "SHIRT SIZE"
        
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scannerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scannerView.topAnchor.constraint(equalTo: view.topAnchor),
            scannerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            userBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            userBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            userBackgroundView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor),
            userStackView.leadingAnchor.constraint(equalTo: userBackgroundView.contentView.leadingAnchor, constant: 10.0),
            userStackView.trailingAnchor.constraint(equalTo: userBackgroundView.contentView.trailingAnchor, constant: -10.0),
            userStackView.topAnchor.constraint(equalTo: userBackgroundView.contentView.topAnchor, constant: 10.0),
            userStackView.bottomAnchor.constraint(equalTo: userBackgroundView.contentView.bottomAnchor, constant: -10.0),
        ])
        
        updateViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(scanEventsUpdated), name: APIManager.ScanEventsUpdatedNotification, object: nil)
        
        APIManager.shared.updateScanEvents()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: APIManager.ScanEventsUpdatedNotification, object: nil)
    }
    
    // MARK: Update views
    
    func updateViews() {
        
        inputModeControl.selectedSegmentIndex = inputMode.rawValue
        
        tableView.isHidden = (inputMode != .list)
        scannerView.isHidden = (inputMode != .scan)
        
        updateEventsBarButtonItemTitle()
        
        updateUserView()
        
        updateToolbarItems(animated: false)
    }
    
    func updateEventsBarButtonItemTitle() {
        
        eventsBarButtonItem.title = currentScanEvent?.name ?? "Loading"
    }
    
    func updateUserView() {
        
        userBackgroundView.alpha = (currentIdentifier == nil) ? 0.0 : 1.0
        
        if let currentIdentifier = currentIdentifier {
            
            emailLabel.textLabel.text = currentIdentifier
        }
    }
    
    func updateToolbarItems(animated: Bool) {
        
        if currentIdentifier == nil {
            setToolbarItems([UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), eventsBarButtonItem, UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)], animated: animated)
        } else {
            setToolbarItems([UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), confirmationBarButtonItem, UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)], animated: animated)
        }
    }
    
    // MARK: Actions
    
    func finish() {
        delegate?.scannerViewControllerDidFinish(scannerViewController: self)
    }
    
    func inputModeControlValueChanged() {
        inputMode = InputMode(rawValue: inputModeControl.selectedSegmentIndex)!
    }
    
    func scanEventsUpdated() {
        
        DispatchQueue.main.async {
            
            if self.currentScanEvent == nil {
                self.currentScanEvent = APIManager.shared.scanEvents.first
            }
        }
    }
    
    func selectScanEvent() {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        for scanEvent in APIManager.shared.scanEvents {
            
            alertController.addAction(UIAlertAction(title: scanEvent.name, style: .default, handler: { action in
                self.currentScanEvent = scanEvent
            }))
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
    
    func confirmUser() {
        
        APIManager.shared.performScan(userDataScanned: currentIdentifier!, scanEvent: currentScanEvent!, readOnlyPeek: false) { success, additionalData in
            
            DispatchQueue.main.async {
                
                guard success else {
                    return
                }
                
                UIView.animate(withDuration: 0.15) {
                    self.currentIdentifier = nil
                }
            }
        }
    }
    
    func cancelUserScan() {
        
        UIView.animate(withDuration: 0.15) {
            self.currentIdentifier = nil
        }
    }
    
    // MARK: Scanner view delegate
    
    func scannerView(scannerView: ScannerView, didScanIdentifier identifier: String) {
        
        guard currentIdentifier == nil, let scanEvent = currentScanEvent else {
            return
        }
        
        APIManager.shared.performScan(userDataScanned: identifier, scanEvent: scanEvent, readOnlyPeek: true) { success, additionalData in
            
            DispatchQueue.main.async {
                
                guard success else {
                    return
                }
                
                // TODO: if already scanned, make confirmation button red
                
                UIView.animate(withDuration: 0.15) {
                    self.currentIdentifier = identifier
                }
            }
        }
    }
}
