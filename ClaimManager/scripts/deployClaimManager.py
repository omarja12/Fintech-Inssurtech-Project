import os
from dotenv import load_dotenv
from brownie import Wei, accounts, ClaimManager

load_dotenv()
def main():
    deploy_account = accounts[0]
    deployment_details = {"from": deploy_account, "value": Wei("10 ether")}
	
    Claim_Manager = ClaimManager.deploy(deployment_details)
    return Claim_Manager