# TRON-SIG-VERIFY-LITE

A minimal demonstration of **TRON message signing and verification** using the `signMessageV2` API and a simple verification smart contract built with **TIP-191** (“TRON Signed Message”).

This project shows how to:
- Sign messages using **TronLink / TronWeb** (`signMessageV2`)
- Verify the signature **off-chain**
- Verify the signature **on-chain** via Solidity contract

---

## 📁 Project Structure

```
TRON-SIG-VERIFY-LITE/
├─ contracts/
│  ├─ Migrations.sol
│  └─ TronSigVerifierLite.sol      # Core signature verification contract
├─ migrations/
│  ├─ 1_initial_migration.js
│  └─ 2_deploy_tron_sig_verifier_lite.js
├─ web/
│  └─ index.html                   # Frontend demo with TronLink
├─ tronbox.js                      # Network configuration for TronBox
├─ package.json                    # dotenv dependency for TronBox
├─ .env.sample                     # Template for private key and node URLs
└─ README.md                       # This file
```

---

## 🚀 Overview

This project provides a **self-contained reference** for developers who want to verify messages signed with `signMessageV2` in TRON wallets such as **TronLink**.

The contract supports:
- **HEX-as-text** signatures — `"0x" + 64 hex` strings (the most compatible format)
- **Bytes32** signatures — for raw binary signing (developer tools)

Both methods implement **TRON’s standard prefix** used for personal-style messages (`\x19TRON Signed Message:\n...`).

---

## 🔹 Smart Contract: `TronSigVerifierLite.sol`

### Core Features
| Function | Type | Description |
|-----------|------|-------------|
| `recoverBytes32(bytes32, bytes)` | pure | Recover signer from a raw bytes32 message |
| `verifyBytes32(bytes32, bytes, address)` | pure | Verify signature matches expected signer |
| `recoverHexText(bytes32, bytes)` | pure | Recover signer from “0x” + 64 hex text |
| `verifyHexText(bytes32, bytes, address)` | pure | Verify hex-text signature matches signer |
| `toHexString(bytes32)` | pure | Convert bytes32 → lowercase “0x” + 64 string |

### Security Notes
- Only uses **pure** and **view** functions — safe for constant calls (`.call()`), **no Energy cost**.  
- Uses `ecrecover` directly for signer derivation.  

---

## 🌐 Web Demo — `web/index.html`

### What it does
The web page demonstrates the full flow:
1. Connects to **TronLink**
2. Generates `keccak256("demo-payload")`
3. Signs it as **HEX text** using `signMessageV2`
4. Verifies the signature **off-chain**
5. Verifies it **on-chain** using `verifyHexText(...)`

### Usage Steps
1. **Deploy** the contract (see below).  
2. **Run a simple web server:**
   ```bash
   npx http-server web -p 8080
   # or
   python3 -m http.server --directory web 8080
   ```
3. Open [http://localhost:8080](http://localhost:8080) in Chrome/Brave.  
4. Unlock **TronLink** and connect.  
5. Paste your deployed contract **T-address**.  
6. Click **“Sign keccak256('demo-payload')”**.

### Example Log Output
```
Connected: TNd2F... | node: https://nile.trongrid.io
hexText: 0x348c...d5a3
Signature: 0x3b8f...a07b
Recovered (off-chain): TNd2F...
verifyHexText (on-chain) => true
```

---

## 🧠 How It Works

### Off-chain signing (`signMessageV2`)
`signMessageV2` applies the TRON prefix:
```
"\x19TRON Signed Message:\n66" + "0x" + 64 hex chars
```
Then hashes the entire string using `keccak256` before signing.

### On-chain verification
The contract reproduces this process:
```solidity
bytes32 digest = keccak256(
    abi.encodePacked("\x19TRON Signed Message:\n66", hexText)
);
address signer = ecrecover(digest, v, r, s);
```

### View Calls (Free)
When calling `verifyHexText(...)` or `verifyBytes32(...)` with `.call()`,  
no transaction is broadcast → **no Energy / no TRX spent**.

---

## ⚙️ Deployment (TronBox)

### Setup
```bash
npm install
cp .env.sample .env
# Edit .env with your private keys and full node URLs
```

Example `.env` file:
```
PRIVATE_KEY_NILE=your_nile_private_key_here
FULL_NODE_NILE=https://nile.trongrid.io
PRIVATE_KEY_DEVELOPMENT=your_local_private_key_here
FULL_NODE_DEVELOPMENT=http://127.0.0.1:9090
```

### Compile & Deploy
```bash
tronbox compile
tronbox migrate --network nile
# or
tronbox migrate --network development
```

The deployed contract address will appear in your console.

---

## 🔍 Example Verification in Code

```js
const hexText = tronWeb.utils.ethersUtils.keccak256(
  tronWeb.utils.ethersUtils.toUtf8Bytes('demo-payload')
);
const sig = await tronWeb.trx.signMessageV2(hexText);
const who = await tronWeb.trx.verifyMessageV2(hexText, sig);
console.log('Recovered off-chain:', who);

const contract = await tronWeb.contract().at('<T-address>');
const ok = await contract.verifyHexText(hexText, sig, tronWeb.defaultAddress.hex).call();
console.log('On-chain verified:', ok);
```


---

## 📦 Dependencies

| Package | Description |
|----------|--------------|
| `dotenv` | Loads environment variables for TronBox |
| `TronWeb` | Injected by TronLink; used in the web demo |

---


## 📜 License

MIT License © 2025
