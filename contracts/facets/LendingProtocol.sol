// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AppStorage, Trove, TroveStatus} from "../libraries/AppStorage.sol";



/// @title Lending Pending 
/// @dev 
contract LendingProtocol {
    AppStorage internal s;


    /*//////////////////////////////////////////////////////////////
                              CUSTOM ERROR
    //////////////////////////////////////////////////////////////*/


    /// You cannot deposit Zero Ether
    error NonZeroDeposit();
    /// Your balance is too low 
    error InsuficentFund();
    /// Withdrawal failed 
    error WithdrawalFailed();
    /// You are not eligible to borrow this amount of tokens 
    error CannotBorrow();



    /*//////////////////////////////////////////////////////////////
                              EVENT 
    //////////////////////////////////////////////////////////////*/

    event Deposited(address indexed depositor,  uint256 amount);
    event Borrowed(address indexed borrower, uint256 tokenAmount);


    /// @dev make deposit => this function would recieve ether from the user and store msg.value in the balce mapping
    /// @notice users need to deposit ether first before they can borrow
    function makeDeposit() external payable {
        if(msg.value == 0) {
            revert NonZeroDeposit();
        }
        // updating the mapping of balances 
        s.balances[msg.sender] += msg.value;

        emit Deposited(msg.sender, msg.value);
    }


    /// @dev this function would enable users withdraw deposited asset that have not been used as collateral
    /// @param _amount: this is the amount of ETH the user want's to withdraw in WEI 
    function withdrawEther(uint256 _amount) external {
        if(s.balances[msg.sender] < _amount) {
            revert InsuficentFund();
        }

        // sending the ETH
        (bool sent, ) = payable(msg.sender).call{value: _amount}("");
        if(!sent) {
            revert WithdrawalFailed();
        }
    }

    /// @notice this is a view function that would return how much a user can borrow if _amountOfEther is deposited
    function tokenCanBorrowOnEther(uint256 _amountOfEther) public view returns(uint256 amount_) {
        return (_amountOfEther * s.exchange_factor * 90) / 100; // 90% 
    }


    /// @notice this function would deduct ether from the balances of the user and send them the protocols token 
    function borrow(uint256 _borrowAmount) external {
        uint256 borrower_ether_balance = s.balances[msg.sender];
        uint256 token_can_borrow = tokenCanBorrowOnEther(borrower_ether_balance);

        if(token_can_borrow !=  _borrowAmount || s.troves[msg.sender].mount) {
            revert CannotBorrow();
        }

        // removing all ether from the borrows balance 
        s.balances[msg.sender] = 0;


        // creating the trove 
        Trove storage tv = s.troves[msg.sender];

        tv.status = TroveStatus.ACTIVE;
        tv.ether_in = borrower_ether_balance;
        tv.token_out = token_can_borrow;
        tv.mount = true;

        // sending the token 
        s.protocol_token.transfer(msg.sender, token_can_borrow);

        // emiting event 
        emit Borrowed(msg.sender, token_can_borrow);
    }

    /// @notice calling this function would show users balances of ether that have been deposited
    function viewEtherBalance(address _addr) external view returns(uint256 ) {
        return s.balances[_addr];
    }

    /// @notice this would return the state of the trove conserning a particular address 
    function troveStatus(address _addr) external view returns(TroveStatus) {
        return s.troves[_addr].status;
    } 
}