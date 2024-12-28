// energy-token_test.ts
Clarinet.test({
  name: "Ensure token transfers work correctly",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet1 = accounts.get("wallet_1")!;
    
    // Test minting
    let block = chain.mineBlock([
      Tx.contractCall(
        "energy-token",
        "mint",
        [types.uint(1000), types.principal(wallet1.address)],
        deployer.address
      ),
    ]);
    assertEquals(block.receipts[0].result, '(ok true)');
    
    // Verify balance
    let balance = chain.callReadOnlyFn(
      "energy-token",
      "get-balance",
      [types.principal(wallet1.address)],
      deployer.address
    );
    assertEquals(balance.result, '(ok u1000)');
    
    // Test transfer
    const wallet2 = accounts.get("wallet_2")!;
    block = chain.mineBlock([
      Tx.contractCall(
        "energy-token",
        "transfer",
        [
          types.uint(500),
          types.principal(wallet1.address),
          types.principal(wallet2.address),
          types.none()
        ],
        wallet1.address
      ),
    ]);
    assertEquals(block.receipts[0].result, '(ok true)');
  },
});
