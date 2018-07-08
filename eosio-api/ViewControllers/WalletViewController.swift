//
//  WalletViewController.swift
//  eosio-api
//
//  Created by kein on 2018. 6. 17..
//  Copyright © 2018년 kein. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class WalletViewController: UIViewController {
    
    @IBOutlet fileprivate weak var balance: UILabel?
    @IBOutlet fileprivate weak var btnAccount: UIButton?
    @IBOutlet fileprivate weak var btnKey: UIButton?
    @IBOutlet fileprivate weak var btnSend: UIButton?
    @IBOutlet fileprivate weak var btnReceive: UIButton?
    @IBOutlet fileprivate weak var btnSetting: UIButton?
    @IBOutlet fileprivate weak var lbDebug: UILabel?
    
    fileprivate var walletViews: [WalletView] = []
    
    private var isInitialized = false
    
    private let bag = DisposeBag()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
        
        AccountManager.shared.refreshAccountInfo()
        
        if isInitialized == false {
            isInitialized = true
            setupUIAfterLayout()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        bindActions()
    }
    
    private func setupUI() {
        balance?.text = "Loading..."
    }
    
    private func setupUIAfterLayout() {
        view.layoutIfNeeded()
        if let wallet = WalletManager.shared.getWallet() {
            NSLog(wallet.publicKey)
            addWalletUI(wallet: wallet)
        }
    }
    
    private func bindActions() {
        btnSetting?.rx.singleTap
            .bind(onNext: { [weak self](_) in
                self?.goToSetting()
            })
            .disposed(by: bag)
        
        //TODO 0 EOS일때 "0.0000 EOS"를 return 하도록 변경
//        WalletManager.shared.balance
//            .subscribe(onNext: { [weak self](currency) in
//                guard let eosCurrency = currency.first else { return }
//                self?.balance?.text = eosCurrency.currency
//            })
//            .disposed(by: bag)
        
        AccountManager.shared.accountInfo
            .subscribe(onNext: { [weak self ](account) in
                if let account = account {
                    
                    self?.lbDebug?.text = "\(account)"
                    
                    self?.balance?.text = account.liquidBalance.currency
                    
                } else {
                    self?.balance?.text = Currency.zeroEOS.currency
                }
            })
            .disposed(by: bag)
        
    }
    
    private func addWalletUI(wallet: Wallet) {
        
        btnAccount?.setTitle(wallet.name, for: .normal)
        btnKey?.titleLabel?.minimumScaleFactor = 0.5
        btnKey?.titleLabel?.adjustsFontSizeToFitWidth = true
        btnKey?.setTitle(wallet.publicKey, for: .normal)
        
    }

    
    fileprivate func goToSetting() {
        guard let tc = tabBarController as? MainTabBarViewController else { return }
        
        guard let nc = tc.navigationController else { return }
        
        tc.flowDelegate?.goToSetting(nc: nc)
        
    }
    
}
