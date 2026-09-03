# Claim Ledger

## Ethereum claim management for fintech and insurtech

Claim Ledger is a Solidity smart contract that models an insurance claim lifecycle on Ethereum. It gives customers a way to submit claims and request approval, while an administrator controls KYC verification and settlement. The contract records state transitions and emits events so the workflow can be inspected from deployment through payout.

## Portfolio site

Open the live [Claim Ledger portfolio page](https://omarja12.github.io/Fintech-Inssurtech-Project/) to see the claim lifecycle, contract roles, permissions, and event model visually.

Run it locally with:

```powershell
python -m http.server 4173
```

Then open `http://localhost:4173`.

## Core workflow

The contract implements a guarded state machine:

```text
Submitted -> Approved -> Paid
```

1. A customer calls `submitClaim(amount)`. The contract stores the customer, amount, and `Submitted` state.
2. The administrator calls `kyc(customer, true)` to approve the customer's identity.
3. The customer calls `askApproval()`. The contract checks that a claim exists, KYC is approved, and the contract balance can cover the claim.
4. The administrator calls `triggerPayment(customer)`. The claim amount is transferred, the claim becomes `Paid`, and the customer's KYC status is reset for a future claim.

The contract emits `NewClaim`, `ClaimApproved`, and `ClaimPaid` events, creating a chronological audit trail for the major lifecycle transitions.

## Contract design

### Role separation

The Solidity code defines customer and administrator interfaces. Customer actions are limited to their own workflow, while administrative actions are protected by the `onlyAdmin` modifier. The deployer becomes the administrator in the payable constructor.

### State and permissions

Each claim is represented by a customer address, an amount, and a state. The contract uses private mappings for claims and KYC decisions, then exposes role-aware getter functions:

- Customers can inspect their own claim with `getClaim()`.
- The administrator can inspect any claim with `getCustomerClaim(customer)`.
- The administrator can inspect KYC status with `getKYC(customer)`.
- Only the administrator can read the contract balance and trigger payments.

### Operational safeguards

The contract uses `require` checks to prevent duplicate active claims, unauthorized administrative actions, approval without KYC, approval when funds are insufficient, and payment before approval. These checks demonstrate how business rules can become executable on-chain permissions.

## Technology

- Solidity `>=0.5.0 <0.9.0`
- Brownie for deployment and console interaction
- Ganache for a local Ethereum development network
- Python deployment script
- Solidity contract events and state transitions

## Run the original Brownie project

The original scripts and contract are intentionally unchanged. From the repository root:

```powershell
python -m venv venv
.\venv\Scripts\activate
pip install eth-brownie
cd ClaimManager
```

Open a Ganache Quickstart workspace, then configure the local network:

```powershell
brownie networks list
brownie networks add development local host=http://127.0.0.1:7545 cmd=ganache
brownie run deployClaimManager.py
brownie console
```

In the Brownie console, use the deployed contract address:

```python
claim_manager = ClaimManager.at("DEPLOYED_CONTRACT_ADDRESS")
claim_manager.getContractBalance({'from': accounts[0]})
claim_manager.submitClaim("5 ether", {'from': accounts[1]})
claim_manager.kyc(accounts[1], True, {'from': accounts[0]})
claim_manager.askApproval({'from': accounts[1]})
claim_manager.getClaim({'from': accounts[1]})
claim_manager.getCustomerClaim(accounts[1].address, {'from': accounts[0]})
claim_manager.getKYC(accounts[1].address, {'from': accounts[0]})
claim_manager.triggerPayment(accounts[1].address, {'from': accounts[0]})
claim_manager.getContractBalance({'from': accounts[0]})
```

## Files

| File | Purpose |
| --- | --- |
| [index.html](index.html) | Portfolio-facing Claim Ledger webpage |
| [styles.css](styles.css) | Responsive visual system for the webpage |
| [ClaimManager.sol](ClaimManager/contracts/ClaimManager.sol) | Original insurance claim smart contract |
| [deployClaimManager.py](ClaimManager/scripts/deployClaimManager.py) | Original Brownie deployment script |
| [testClaimManager.py](ClaimManager/tests/testClaimManager.py) | Original test scaffold |

## Scope and limitations

This is a local Ethereum development and portfolio project, not a production insurance platform. The historical contract does not include oracle-based claim evidence, policy data, upgradeability, formal access-control libraries, reentrancy protection, gas optimization, or a production dispute process. A production implementation would require a security audit, comprehensive tests, explicit legal and compliance review, and carefully designed custody and claims controls.

## Historical note

The original implementation was committed in June 2022 and is kept intact to preserve its development context. The webpage and README are presentation and documentation layers around that source.

## Keywords

`fintech` `insurtech` `ethereum` `solidity` `smart-contracts` `insurance-claims` `claims-management` `blockchain` `decentralized-applications` `dapp` `brownie` `ganache` `web3` `ethereum-development` `on-chain-settlement` `kyc` `access-control` `state-machine` `event-driven-architecture` `financial-technology`

## License

See the repository license and source history for project terms.
