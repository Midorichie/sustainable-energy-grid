// energy-grid_test.ts
import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure that participant registration works",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const user1 = accounts.get("wallet_1")!;
    
    // Register valid meter first
    let block = chain.mineBlock([
      Tx.contractCall(
        "energy-grid",
        "register-valid-meter",
        [types.uint(1)],
        deployer.address
      ),
    ]);
    assertEquals(block.receipts[0].result, '(ok true)');

    // Test participant registration
    block = chain.mineBlock([
      Tx.contractCall(
        "energy-grid",
        "register-participant",
        [types.uint(1)],
        user1.address
      ),
    ]);
    assertEquals(block.receipts[0].result, '(ok true)');

    // Verify participant info
    const result = chain.callReadOnlyFn(
      "energy-grid",
      "get-participant-info",
      [types.principal(user1.address)],
      deployer.address
    );
    assertEquals(result.result, 
      `(ok (some {active: true, energy-balance: u0, smart-meter-id: (some u1), credit-balance: u0, settlement-balance: 0, last-meter-reading: u0}))`
    );
  },
});

Clarinet.test({
  name: "Test energy supply and trading functionality",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const seller = accounts.get("wallet_1")!;
    const buyer = accounts.get("wallet_2")!;
    
    // Setup: Register meters and participants
    let block = chain.mineBlock([
      Tx.contractCall("energy-grid", "register-valid-meter", [types.uint(1)], deployer.address),
      Tx.contractCall("energy-grid", "register-valid-meter", [types.uint(2)], deployer.address),
      Tx.contractCall("energy-grid", "register-participant", [types.uint(1)], seller.address),
      Tx.contractCall("energy-grid", "register-participant", [types.uint(2)], buyer.address),
    ]);
    
    // Test energy supply
    block = chain.mineBlock([
      Tx.contractCall(
        "energy-grid",
        "supply-energy",
        [types.uint(100)],
        seller.address
      ),
    ]);
    assertEquals(block.receipts[0].result, '(ok true)');
    
    // Test trade creation
    block = chain.mineBlock([
      Tx.contractCall(
        "energy-grid",
        "create-trade-order",
        [types.uint(50), types.uint(10)],
        seller.address
      ),
    ]);
    assertEquals(block.receipts[0].result, '(ok true)');
    
    // Test trade execution
    block = chain.mineBlock([
      Tx.contractCall(
        "energy-grid",
        "execute-trade",
        [types.uint(0)],
        buyer.address
      ),
    ]);
    assertEquals(block.receipts[0].result, '(ok true)');
  },
});
