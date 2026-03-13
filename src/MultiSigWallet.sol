// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MultiSigWallet {
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(address indexed owner, uint256 indexed txIndex, address indexed to, uint256 value, bytes data);
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public required;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
    }

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmed;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }
    modifier txExists(uint256 txIndex) {
        require(txIndex < transactions.length, "tx does not exist");
        _;
    }
    modifier notExecuted(uint256 txIndex) {
        require(!transactions[txIndex].executed, "tx already executed");
        _;
    }
    modifier notConfirmed(uint256 txIndex) {
        require(!confirmed[txIndex][msg.sender], "tx already confirmed");
        _;
    }

    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "owners required");
        require(_required > 0 && _required <= _owners.length, "invalid required");
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "duplicate owner");
            isOwner[owner] = true;
            owners.push(owner);
        }
        required = _required;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(address to, uint256 value, bytes calldata data)
        external onlyOwner returns (uint256 txIndex)
    {
        txIndex = transactions.length;
        transactions.push(Transaction({ to: to, value: value, data: data, executed: false, confirmations: 0 }));
        emit SubmitTransaction(msg.sender, txIndex, to, value, data);
    }

    function confirmTransaction(uint256 txIndex)
        external onlyOwner txExists(txIndex) notExecuted(txIndex) notConfirmed(txIndex)
    {
        Transaction storage t = transactions[txIndex];
        t.confirmations += 1;
        confirmed[txIndex][msg.sender] = true;
        emit ConfirmTransaction(msg.sender, txIndex);
    }

    function executeTransaction(uint256 txIndex)
        external onlyOwner txExists(txIndex) notExecuted(txIndex)
    {
        Transaction storage t = transactions[txIndex];
        require(t.confirmations >= required, "not enough confirmations");
        t.executed = true;
        (bool ok,) = t.to.call{value: t.value}(t.data);
        require(ok, "tx failed");
        emit ExecuteTransaction(msg.sender, txIndex);
    }

    function revokeConfirmation(uint256 txIndex)
        external onlyOwner txExists(txIndex) notExecuted(txIndex)
    {
        require(confirmed[txIndex][msg.sender], "not confirmed");
        Transaction storage t = transactions[txIndex];
        t.confirmations -= 1;
        confirmed[txIndex][msg.sender] = false;
        emit RevokeConfirmation(msg.sender, txIndex);
    }

    function getOwners() external view returns (address[] memory) { return owners; }
    function getTransactionCount() external view returns (uint256) { return transactions.length; }
    function getTransaction(uint256 txIndex) external view returns (
        address to, uint256 value, bytes memory data, bool executed, uint256 confirmations
    ) {
        Transaction storage t = transactions[txIndex];
        return (t.to, t.value, t.data, t.executed, t.confirmations);
    }
}
