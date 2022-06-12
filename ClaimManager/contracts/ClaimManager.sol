//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

interface CustomerClaimManager {
    // A customer needs to be able to submit a claim
    function submitClaim(uint256 amount) external returns (bool success);
    // A customer needs to be able to ask the claim to be approved
    function askApproval() external returns (bool succeed);
}

interface AdminClaimManager {
    // An admin needs to be able to perform know your customer
    function kyc(address customer, bool approve) external;
    // An admin needs to be able to pay the claim
    function triggerPayment(address payable customer) external payable returns (bool success);
}

contract ClaimManager is CustomerClaimManager, AdminClaimManager {
    address payable admin;
    uint contract_balance;

    // Restrict function call to admin
    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    enum State {Submitted, Approved, Paid}

    struct S_Claim {
        address payable customer;
        uint256 amount;
        State state;
    }

    // We don't make claims public, so only admin or claim submitter can see their claim
    // through a getter method
    mapping(address => S_Claim) claims;
    // We don't make kycs public, so only admin can see them through a getter method
    // Boolean defaults to false, so if admin hasn't perform KYC on the customer,
    // it defaults to false
    mapping(address => bool) kycs;
    
    event NewClaim(address indexed customer, uint256 amount, uint256 time);
    event ClaimApproved(address indexed customer, uint256 time);
    event ClaimPaid(address indexed customer, uint256 amount, uint256 time);

    constructor() payable {
        admin = payable(msg.sender);
        contract_balance = address(this).balance;
    }

    // Function for customers to submit a claim. Returns success if the customer doesn't 
    // already have a claim, or the previous claim was paid so the customer can submit new claims
    function submitClaim(uint256 amount) public override returns (bool success) {
        address customer = msg.sender;
        require(!hasClaim(customer) || claims[customer].state == State.Paid);
        claims[customer] = S_Claim({
            customer: payable(customer),
            amount: amount,
            state: State.Submitted
        });
        emit NewClaim(customer, amount, block.timestamp);
        success = true;
    }

    // Function for admin to perform Know Your Customer 
    function kyc(address customer, bool approve) public override onlyAdmin {
        kycs[customer] = approve;
    }

    // Function for customers to ask for approval. Returns success if the customer has a claim,
    // and it's in Submitted or Approved state.
    function askApproval() public override returns (bool succeed) {
        address customer = msg.sender;   
        // making sure the contract balance is greater than the amount of the claim.
        require(contract_balance >= claims[customer].amount);
        // Make sure the customer has submitted a claim and it's in Submitted or Approved state
        require(hasClaim(customer) && (claims[customer].state == State.Submitted || claims[customer].state == State.Approved));
        // Make sure the customer has been subject to KYC
        require(kycs[customer]);
        claims[customer].state = State.Approved;
        emit ClaimApproved(customer, block.timestamp);
        succeed = true;
    }

    // Function for admin to make payment
    function triggerPayment(address payable customer) public override payable onlyAdmin returns (bool success) {
        // Make sure customer claim is in approved state
        require(claims[customer].state == State.Approved);
        // reducing the contract balance by the amount of the claim.
        contract_balance -= claims[customer].amount;
        customer.transfer(claims[customer].amount);
        // Changing the state of the claim.
        claims[customer].state = State.Paid;
        resetCustomer(customer);
        emit ClaimPaid(customer, claims[customer].amount, block.timestamp);
        success = true;
    }

    // Function for the admin the see the current balance of the contract:
    function getContractBalance() public view onlyAdmin() returns (uint balance){
        balance =  contract_balance;
    }

    // Function for customers to see their own claim, if they have submitted
    function getClaim() public view returns (S_Claim memory claim) {
        address customer = msg.sender;
        require(hasClaim(customer));
        claim = claims[customer];
    }

    // Function for admin to see any claim
    function getCustomerClaim(address customer) public onlyAdmin view returns (S_Claim memory claim) {
        claim = claims[customer];
    }

    // Function for admin to see KYC
    function getKYC(address customer) public onlyAdmin view returns (bool approved) {
        approved = kycs[customer];
    }

    // Helper function to reset customer status
    function resetCustomer(address customer) private onlyAdmin {
        // Customer is subject to KYC again for the next claim
        delete kycs[customer];
    }
 
    // Solidity doesn't have the concept of key exists in mapping. It returns the default value
    // We know it's the default value if address of claim is not the address of the customer,
    // and therefore the empty value
    function hasClaim(address customer) private view returns (bool succeed) {
        succeed = claims[customer].customer == msg.sender;
    }
}