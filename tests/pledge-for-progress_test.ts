import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types,
} from "@hirosystems/clarinet-sdk";
import { describe, expect, it, beforeEach } from "vitest";

const contractName = "pledge-for-progress";

describe("Pledge for Progress contract", () => {
  let chain: Chain;
  let deployer: Account;
  let beneficiary: Account;
  let wallet1: Account;
  let wallet2: Account;

  beforeEach(() => {
    chain = Clarinet.newChain();
    deployer = chain.getAccount("deployer");
    // The beneficiary is hardcoded in the contract.
    // 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM' is wallet_1 in Clarinet.
    beneficiary = chain.getAccount("wallet_1");
    wallet1 = chain.getAccount("wallet_2");
    wallet2 = chain.getAccount("wallet_3");

    // Deploy the contract
    chain.deployContract(contractName, deployer);
  });

  it("should allow a user to pledge funds", () => {
    const pledgeAmount = 10000000; // 10 STX
    const block = chain.mineBlock([
      Tx.contractCall(contractName, "pledge", [types.uint(pledgeAmount)], wallet1.address),
    ]);

    // The transaction should be successful
    block.receipts[0].result.expectOk().expectBool(true);

    // The contract's total pledged amount should be updated
    const status = chain.callReadOnlyFn(contractName, "get-campaign-status", [], deployer.address);
    status.result.expectOk().expectTuple();
    expect(status.result).toHaveProperty("value.data.total-pledged.value", 10000000n);

    // The user's pledged amount should be recorded
    const userPledge = chain.callReadOnlyFn(contractName, "get-pledge-amount", [types.principal(wallet1.address)], deployer.address);
    userPledge.result.expectOk().expectUint(pledgeAmount);
  });

  it("should allow the beneficiary to claim funds when the goal is met", () => {
    // wallet1 and wallet2 pledge enough to meet the 100 STX goal
    chain.mineBlock([
      Tx.contractCall(contractName, "pledge", [types.uint(60000000)], wallet1.address),
      Tx.contractCall(contractName, "pledge", [types.uint(40000000)], wallet2.address),
    ]);

    // Check that the goal is marked as achieved
    const status = chain.callReadOnlyFn(contractName, "get-campaign-status", [], deployer.address);
    expect(status.result).toHaveProperty("value.data.goal-achieved.value", true);

    // Beneficiary claims the funds
    const block = chain.mineBlock([
      Tx.contractCall(contractName, "claim-funds", [], beneficiary.address),
    ]);

    // The claim transaction should be successful
    block.receipts[0].result.expectOk().expectBool(true);

    // The STX should be transferred to the beneficiary
    block.receipts[0].events.expectSTXTransferEvent(
      100000000,
      `${deployer.address}.${contractName}`,
      beneficiary.address
    );
  });

  it("should allow a user