# MultiSig Wallet

A **N-of-M multisig wallet** written in Solidity. Requires M-of-N owner signatures to execute any transaction — ideal for treasuries, DAOs, and shared custody.

## What is a Multisig Wallet?

A multisig (multi-signature) wallet requires a minimum number of approvals from a predefined set of owners before any transaction can be executed. For example, a 2-of-3 wallet needs at least 2 out of 3 owners to confirm a transaction before it goes through.

**Key benefits:**
- No single point of failure
- Shared custody of funds
- On-chain audit trail of all approvals

## Contract Overview

| Function | Description |
|---|---|
| `submitTransaction(to, value, data)` | Owner submits a new transaction |
| `confirmTransaction(txIndex)` | Owner approves a pending transaction |
| `executeTransaction(txIndex)` | Execute once enough confirmations received |
| `revokeConfirmation(txIndex)` | Owner withdraws their confirmation |
| `getOwners()` | Returns list of owners |
| `getTransaction(txIndex)` | Returns transaction details |

## Setup

```bash
git clone https://github.com/7abar/multisig-wallet
cd multisig-wallet
forge install foundry-rs/forge-std
```

## Run Tests

```bash
forge test
forge test -vvv  # verbose output
```

## Deploy

Set environment variables:

```bash
export OWNER_1=0xYourAddress1
export OWNER_2=0xYourAddress2
export OWNER_3=0xYourAddress3
export REQUIRED=2
export PRIVATE_KEY=0xYourPrivateKey
```

Deploy to Base Sepolia testnet:

```bash
forge script script/Deploy.s.sol --rpc-url base_sepolia --broadcast --private-key $PRIVATE_KEY
```

Deploy to Base mainnet:

```bash
forge script script/Deploy.s.sol --rpc-url base --broadcast --private-key $PRIVATE_KEY
```

## Example Usage (Cast)

After deployment, interact with the contract:

```bash
# Submit a transaction (0.1 ETH to recipient)
cast send $WALLET_ADDRESS "submitTransaction(address,uint256,bytes)" \
  0xRecipient 100000000000000000 0x \
  --private-key $OWNER_1_KEY --rpc-url base_sepolia

# Confirm (owner 1)
cast send $WALLET_ADDRESS "confirmTransaction(uint256)" 0 \
  --private-key $OWNER_1_KEY --rpc-url base_sepolia

# Confirm (owner 2)
cast send $WALLET_ADDRESS "confirmTransaction(uint256)" 0 \
  --private-key $OWNER_2_KEY --rpc-url base_sepolia

# Execute
cast send $WALLET_ADDRESS "executeTransaction(uint256)" 0 \
  --private-key $OWNER_1_KEY --rpc-url base_sepolia
```

## Architecture

```
MultiSigWallet
├── owners[]          — list of authorized signers
├── required          — minimum confirmations needed
├── transactions[]    — all submitted transactions
└── confirmed[][]     — owner => txIndex => bool
```

## Security Notes

- Owners are set at construction and cannot be changed (immutable ownership)
- Each owner can only confirm once per transaction
- Transactions cannot be executed twice
- All ETH received is held by the contract until execution

## License

MIT
