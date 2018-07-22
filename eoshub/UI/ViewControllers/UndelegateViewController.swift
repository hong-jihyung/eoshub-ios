//
//  UndelegateViewController.swift
//  eoshub
//
//  Created by kein on 2018. 7. 15..
//  Copyright © 2018년 EOS Hub. All rights reserved.
//

//
//  DelegateViewController.swift
//  eoshub
//
//  Created by kein on 2018. 7. 15..
//  Copyright © 2018년 EOS Hub. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class UndelegateViewController: BaseViewController {
    
    var flowDelegate: UndelegateFlowEventDelegate?
    
    @IBOutlet fileprivate weak var tableView: UITableView!
    @IBOutlet fileprivate weak var btnStake: UIButton!
    @IBOutlet fileprivate weak var btnHistory: UIButton!
    
    fileprivate var account: AccountInfo!
    
    fileprivate let inputForm = DelegateInputForm()
    
    deinit {
        Log.d("deinit")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showNavigationBar(with: .white)
        title = LocalizedString.Wallet.Delegate.undelegate
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindActions()
    }
    
    
    func configure(account: AccountInfo) {
        self.account = account
    }
    
    private func setupUI() {
        tableView.dataSource = self
        tableView.dataSource = self
        //        tableView.delegate = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 150
        
        btnStake.setTitle(LocalizedString.Wallet.Delegate.undelegate, for: .normal)
        btnHistory.setTitle(LocalizedString.Wallet.Delegate.history, for: .normal)
    }
    
    private func bindActions() {
        
        btnStake.rx.singleTap
            .bind { [weak self] in
                self?.validate()
            }
            .disposed(by: bag)
        
        btnHistory.rx.singleTap
            .bind { [weak self] in
                guard let nc = self?.navigationController else { return }
                self?.flowDelegate?.goToTx(from: nc)
            }
            .disposed(by: bag)
        
        Observable.combineLatest([inputForm.cpu.asObservable(),inputForm.net.asObservable()])
            .flatMap(isValidInput(max: account.stakedEOS))
            .bind(to: btnStake.rx.isEnabled)
            .disposed(by: bag)
    }
    
    private func undelegatebw() {
        
        let cpu = Currency(balance: inputForm.cpu.value, token: .eos)
        let net = Currency(balance: inputForm.net.value, token: .eos)
        let accountName = account.account
        unlockWallet(pinTarget: self, pubKey: account.pubKey)
            .flatMap { (wallet) -> Observable<JSON> in
                WaitingView.shared.start()
                return RxEOSAPI.undelegatebw(account: accountName, cpu: cpu, net: net, wallet: wallet)
            }
            .flatMap({ (_) -> Observable<Void> in
                WaitingView.shared.stop()
                //clear form
                self.inputForm.clear()
                //pop
                return Popup.show(style: .success, description: LocalizedString.Tx.success)
            })
            .flatMap { (_) -> Observable<Void> in
                return AccountManager.shared.loadAccounts()
            }
            .subscribe(onNext: { (_) in
                self.flowDelegate?.finish(viewControllerToFinish: self, animated: true, completion: nil)
            }, onError: { (error) in
                Log.e(error)
                WaitingView.shared.stop()
                Popup.present(style: .failed, description: "\(error)")
            })
            .disposed(by: bag)
        
    }
    
    private func validate() {
        let cpu = inputForm.cpu.value.dot4String
        let net = inputForm.net.value.dot4String
        
        //check validate
        
        //confirm
        DelegatePopup.show(cpu: cpu, net: net, buttonTitle: LocalizedString.Wallet.Delegate.undelegate)
            .subscribe(onNext: { [weak self](apply) in
                if apply {
                    self?.undelegatebw()
                }
            })
            .disposed(by: bag)
    }
    
    private func isValidInput(max: Double) -> ([String]) -> Observable<Bool> {
        return { inputs in
            let total = inputs
                .compactMap { Double($0) }
                .reduce(0.0) { $0 + $1 }
            
            if total > 0 && total <= max {
                return Observable.just(true)
            } else {
                return Observable.just(false)
            }
        }
        
    }
    
}

extension UndelegateViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cellId = ""
        if indexPath.row == 0 {
            cellId = "UndelegateMyAccountCell"
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId) as? UndelegateMyAccountCell else { preconditionFailure() }
            let balance = Currency(balance: account.totalEOS, token: .eos)
            cell.configure(account: account, balance: balance)
            return cell
            
        } else {
            cellId = "DelegateInputFormCell"
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId) as? DelegateInputFormCell else { preconditionFailure() }
            cell.configure(account: account, inputForm: inputForm)
            return cell
        }
    }
}

class UndelegateMyAccountCell: UITableViewCell {
    @IBOutlet fileprivate weak var lbAccount: UILabel!
    @IBOutlet fileprivate weak var lbAvailable: UILabel!
    @IBOutlet fileprivate weak var lbBalance: UILabel!
    @IBOutlet fileprivate weak var lbSymbol: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    
    func configure(account: AccountInfo, balance: Currency) {
        lbAvailable.text = LocalizedString.Wallet.Delegate.stakedEOS
        lbAccount.text = account.account
        lbBalance.text = balance.balance
        lbSymbol.text = balance.symbol
    }
    
}
