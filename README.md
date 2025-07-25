# Pledge for Progress

A simple, decentralized crowdfunding smart contract on the Stacks blockchain. This project enables transparent, all-or-nothing fundraising campaigns for public goods, ensuring that funds are only released if the goal is met. Otherwise, all contributors are guaranteed a refund.

## The Problem

Funding public goods—like planting trees, cleaning a beach, or supporting open-source software—is challenging. People are often hesitant to contribute if they aren't sure their money will make a difference or if the funding goal will even be met. This creates a coordination problem where potential donors hold back, fearing their contribution will be wasted.

## The Solution

This smart contract acts as a transparent and automated escrow system to solve this problem. It creates a trustless, all-or-nothing crowdfunding campaign:

1.  **Pledge:** Anyone can pledge STX (the native currency of Stacks) to a specific cause before a set deadline.
2.  **Goal Met:** If the funding goal is met by the deadline, a designated beneficiary (e.g., an environmental NGO) can claim all the pledged funds.
3.  **Goal Not Met:** If the goal is *not* met by the deadline, all pledgers can get a full, automated refund.

This ensures no one's money is wasted and the entire process is auditable on the blockchain.

## Getting Started

### Prerequisites

You must have [Clarinet](https://github.com/hirosystems/clarinet) installed to work with this project.

### Installation & Testing

1.  **Install dependencies:**
    ```bash
    npm install
    ```

2.  **Check contract syntax:**
    ```bash
    clarinet check
    ```

3.  **Run the tests:**
    ```bash
    npm test
    ```
    Alternatively, you can run the tests directly with Clarinet:
    ```bash
    clarinet test
    ```

## Smart Contract Functions

The core logic is contained in `contracts/pledge-for-progress.clar`.

### Public Functions
- `pledge(amount uint)`: Allows any user to pledge a specific amount of micro-STX to the campaign.
- `claim-funds()`: Allows the designated beneficiary to withdraw the total pledged amount if the funding goal has been achieved.
- `refund()`: Allows a user to reclaim their pledged funds if the campaign deadline has passed and the goal was not met.

### Read-Only Functions
- `get-campaign-status()`: Returns an object with the current status of the campaign, including the total amount pledged, the funding goal, and whether the goal has been achieved.
- `get-pledge-amount(who principal)`: Returns the amount pledged by a specific user.
 
