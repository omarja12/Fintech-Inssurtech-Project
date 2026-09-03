# Claim Ledger

## Ethereum claim management for fintech and insurtech

Claim Ledger is a Solidity smart contract that models an insurance claim lifecycle on Ethereum. It gives customers a way to submit claims and request approval, while an administrator controls KYC verification and settlement. The contract records state transitions and emits events so the workflow can be inspected from deployment through payout.

## Portfolio site

Open the live [Claim Ledger portfolio page](https://omarja12.github.io/Fintech-Inssurtech-Project/) to see the claim lifecycle, contract roles, permissions, and event model visually. The dedicated [How It Works guide](how-it-works.html) explains the system in plain English for non-technical readers.

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

## Smart-contract theory

### Claims as a state machine

The contract models each claim as a finite state machine:

```text
Submitted -> Approved -> Paid
```

This matters because the contract does not merely store a status label; it enforces which transitions are legal. A customer can create a claim, but approval requires both KYC approval and enough tracked contract balance. Settlement requires the claim to already be approved. An invalid transition reverts through `require`, leaving the previous state unchanged.

### Access control as a capability boundary

The deployer becomes `admin` in the constructor. Administrative capabilities are guarded by the `onlyAdmin` modifier, which checks the caller before allowing KYC, balance inspection, claim inspection, or payment. Customer methods operate on `msg.sender`, so a customer cannot submit or inspect another address's claim through the public customer interface.

This is a simple role-based access-control pattern: authorization is attached to the function boundary, close to the state mutation it protects. In larger systems, the same principle is commonly implemented with audited access-control libraries and multiple operational roles.

### Events and auditability

Ethereum contract storage records the current state, while events record important transitions in transaction logs. Claim Ledger emits:

- `NewClaim` when a customer submits a claim.
- `ClaimApproved` when KYC and funding checks pass.
- `ClaimPaid` when the administrator settles the claim.

These logs can be indexed by an off-chain dashboard or analytics service. Events are useful for audit trails, but they are not a substitute for access control: the contract still needs `require` checks to protect state changes.

### Escrow-style reserve and trust model

The payable constructor funds the contract, and the contract maintains a tracked `contract_balance`. Before approval, the claim amount is compared with that balance. At payment, the balance is reduced and the customer receives the claim amount.

This demonstrates an escrow-style reserve, but it is not a complete insurance protocol. Real claim evidence, policy terms, external data, dispute resolution, and compliance workflows would require additional contracts or trusted off-chain services. The important design trade-off is visible: on-chain rules are transparent and deterministic, while real-world insurance facts are often external to the blockchain.

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
| [layout-fix.css](layout-fix.css) | Full-width hero layout styling |
| [protocol-theme.css](protocol-theme.css) | Protocol-focused color theme |
| [theory.css](theory.css) | Smart-contract theory section styling |
| [how-it-works.html](how-it-works.html) | Plain-English smart-contract explainer |
| [how-it-works.css](how-it-works.css) | Explainer page styling |
| [ClaimManager.sol](ClaimManager/contracts/ClaimManager.sol) | Original insurance claim smart contract |
| [deployClaimManager.py](ClaimManager/scripts/deployClaimManager.py) | Original Brownie deployment script |
| [testClaimManager.py](ClaimManager/tests/testClaimManager.py) | Original test scaffold |

## Historical note

The original implementation was committed in June 2022 and is kept intact to preserve its development context. The webpage and README are presentation and documentation layers around that source.

## License

See the repository license and source history for project terms.
