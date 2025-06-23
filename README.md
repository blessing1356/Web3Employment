# Web3Employment Smart Contract

Milestone-based freelance contract management on the Stacks blockchain.

---

## Overview

**Web3Employment** is a Clarity smart contract for managing milestone-based agreements between employers and freelancers. It enables secure escrow, milestone submissions, approvals, payments, and dispute resolution—all on-chain.

---

## Features

- **Create Contracts:** Employers can create contracts specifying freelancer, number of milestones, and payment per milestone.
- **Escrow Payments:** Full contract value is escrowed at creation for security.
- **Milestone Submissions:** Freelancers submit work for each milestone.
- **Approval & Payment:** Employers approve submissions to release milestone payments.
- **Dispute Handling:** Either party can raise a dispute, flagging the contract for off-chain or future on-chain resolution.
- **Read-Only Queries:** Anyone can query contract and milestone status.

---

## Contract Functions

### Public Functions

- `create-contract (freelancer principal) (milestones uint) (pay-per-milestone uint)`
  - Employer creates a new contract and escrows total funds.
- `submit-work (contract-id uint) (content (string-ascii 280))`
  - Freelancer submits work for the current milestone.
- `approve-work (contract-id uint)`
  - Employer approves the current milestone and releases payment.
- `raise-dispute (contract-id uint)`
  - Either party can flag the contract as in dispute.

### Read-Only Functions

- `get-contract (contract-id uint)`
  - Returns contract details.
- `get-submission (contract-id uint) (milestone uint)`
  - Returns submission details for a specific milestone.

---

## Data Structures

- **contracts**:  
  Stores contract details keyed by contract ID.
- **submissions**:  
  Stores milestone submissions keyed by contract ID and milestone number.

---

## Error Codes

| Code                | Meaning                        |
|---------------------|-------------------------------|
| `ERR_NOT_FREELANCER`| Only the assigned freelancer  |
| `ERR_NOT_EMPLOYER`  | Only the employer             |
| `ERR_NOT_PARTICIPANT`| Only employer or freelancer  |
| `ERR_INVALID_CONTRACT`| Contract not found          |
| `ERR_ALREADY_COMPLETE`| Contract/milestone complete |
| `ERR_NO_SUBMISSION` | No submission found           |

---

## Example Usage

```clarity
;; Employer creates a contract
(create-contract 'SP...freelancer u3 u100000)

;; Freelancer submits work for milestone 1
(submit-work u0 "Deliverable for milestone 1")

;; Employer approves milestone 1
(approve-work u0)

;; Either party raises a dispute
(raise-dispute u0)
```

---


### Testing

```sh
clarinet test
```

---

## Security

- All funds are escrowed at contract creation.
- Only authorized parties can submit, approve, or dispute.
- All state changes are on-chain and auditable.

---
