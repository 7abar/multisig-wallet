// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet public wallet;
    address[] public owners;
    address owner1 = address(0x1);
    address owner2 = address(0x2);
    address owner3 = address(0x3);
    address recipient = address(0x4);

    function setUp() public {
        owners.push(owner1);
        owners.push(owner2);
        owners.push(owner3);
        wallet = new MultiSigWallet(owners, 2); // 2-of-3
        vm.deal(address(wallet), 1 ether);
    }

    function test_Owners() public view {
        assertEq(wallet.getOwners().length, 3);
        assertTrue(wallet.isOwner(owner1));
        assertTrue(wallet.isOwner(owner2));
        assertFalse(wallet.isOwner(recipient));
    }

    function test_Required() public view {
        assertEq(wallet.required(), 2);
    }

    function test_SubmitAndConfirmAndExecute() public {
        vm.prank(owner1);
        uint256 txIndex = wallet.submitTransaction(recipient, 0.1 ether, "");

        vm.prank(owner1);
        wallet.confirmTransaction(txIndex);

        vm.prank(owner2);
        wallet.confirmTransaction(txIndex);

        uint256 before = recipient.balance;
        vm.prank(owner1);
        wallet.executeTransaction(txIndex);

        assertEq(recipient.balance, before + 0.1 ether);
        (, , , bool executed, ) = wallet.getTransaction(txIndex);
        assertTrue(executed);
    }

    function test_CannotExecuteWithoutEnoughConfirmations() public {
        vm.prank(owner1);
        uint256 txIndex = wallet.submitTransaction(recipient, 0.1 ether, "");

        vm.prank(owner1);
        wallet.confirmTransaction(txIndex);

        vm.prank(owner1);
        vm.expectRevert("not enough confirmations");
        wallet.executeTransaction(txIndex);
    }

    function test_RevokeConfirmation() public {
        vm.prank(owner1);
        uint256 txIndex = wallet.submitTransaction(recipient, 0.1 ether, "");

        vm.prank(owner1);
        wallet.confirmTransaction(txIndex);

        vm.prank(owner1);
        wallet.revokeConfirmation(txIndex);

        (, , , , uint256 confs) = wallet.getTransaction(txIndex);
        assertEq(confs, 0);
    }

    function test_NonOwnerCannotSubmit() public {
        vm.prank(recipient);
        vm.expectRevert("not owner");
        wallet.submitTransaction(recipient, 0.1 ether, "");
    }

    function test_CannotConfirmTwice() public {
        vm.prank(owner1);
        uint256 txIndex = wallet.submitTransaction(recipient, 0.1 ether, "");
        vm.prank(owner1);
        wallet.confirmTransaction(txIndex);
        vm.prank(owner1);
        vm.expectRevert("tx already confirmed");
        wallet.confirmTransaction(txIndex);
    }

    function test_Deposit() public {
        uint256 before = address(wallet).balance;
        vm.deal(address(this), 0.5 ether);
        (bool ok,) = address(wallet).call{value: 0.5 ether}("");
        assertTrue(ok);
        assertEq(address(wallet).balance, before + 0.5 ether);
    }
}
