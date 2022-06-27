# Fin-Inssurtech

In order to run this project please follow the following steps, in the folder containing ClaimManger:
  - `python -m venv venv`
  - `.\venv\Scripts\activate`
  - `pip install eth-brownie`
  - `cd ClaimManager`
  -  Open a Ganache workspace (Quickstart).
  - `brownie networks list`
  - `brownie networks add development local host=http://127.0.0.1:7545 cmd=ganache`
  - `brownie run deployClaimManager.py`
  - `brownie console`

In the brownie console you can execute the following commands:
 - `claim_manager = ClaimManager.at("the address of the contract should be insered here")`
 - `claim_manager.getContractBalance({'from': accounts[0]})`
 - `claim_manager.submitClaim("5 ether", {'from': accounts[1]})`
 - `claim_manager.kyc(accounts[1], True, {'from': accounts[0]})`
 - `claim_manager.askApproval({'from': accounts[1]})`
 - `claim_manager.getClaim({'from': accounts[1]})`
- `claim_manager.getCustomerClaim(accounts[1].address, {'from': accounts[0]})`
- `claim_manager.getKYC(accounts[1].address, {'from': accounts[0]})`
- `claim_manager.triggerPayment(accounts[1].address, {'from': accounts[0]})`
- `claim_manager.getContractBalance({'from': accounts[0]})`
