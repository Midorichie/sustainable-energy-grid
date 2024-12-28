// meters_test.ts
Clarinet.test({
  name: "Test meter registration and reading submission",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    
    // Test meter registration
    let block = chain.mineBlock([
      Tx.contractCall(
        "meters",
        "register-meter",
        [
          types.uint(1),
          types.utf8("Location 1"),
          types.uint(100000)
        ],
        deployer.address
      ),
    ]);
    assertEquals(block.receipts[0].result, '(ok true)');
    
    // Test reading submission
    block = chain.mineBlock([
      Tx.contractCall(
        "meters",
        "submit-reading",
        [types.uint(1), types.uint(1000)],
        deployer.address
      ),
    ]);
    assertEquals(block.receipts[0].result, '(ok true)');
    
    // Verify reading
    const reading = chain.callReadOnlyFn(
      "meters",
      "get-reading",
      [types.uint(1), types.uint(block.height - 1)],
      deployer.address
    );
    assertEquals(reading.result,
      `(ok (some {reading: u1000, validated: false, reported-by: '${deployer.address}'}))`
    );
  },
});

// Integration tests
Clarinet.test({
  name: "Test complete energy trading workflow",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const producer = accounts.get("wallet_1")!;
    const consumer = accounts.get("wallet_2")!;
    
    // Setup: Register meters and participants
    let block = chain.mineBlock([
      // Register meters
      Tx.contractCall("meters", "register-meter", 
        [types.uint(1), types.utf8("Producer Location"), types.uint(100000)],
        deployer.address
      ),
      Tx.contractCall("meters", "register-meter",
        [types.uint(2), types.utf8("Consumer Location"), types.uint(100000)],
        deployer.address
      ),
      
      // Register valid meters in energy grid
      Tx.contractCall("energy-grid", "register-valid-meter", [types.uint(1)], deployer.address),
      Tx.contractCall("energy-grid", "register-valid-meter", [types.uint(2)], deployer.address),
      
      // Register participants
      Tx.contractCall("energy-grid", "register-participant", [types.uint(1)], producer.address),
      Tx.contractCall("energy-grid", "register-participant", [types.uint(2)], consumer.address),
    ]);
    
    // Submit meter readings
    block = chain.mineBlock([
      Tx.contractCall("meters", "submit-reading", [types.uint(1), types.uint(1000)], producer.address),
    ]);
    
    // Supply energy
    block = chain.mineBlock([
      Tx.contractCall("energy-grid", "supply-energy", [types.uint(100)], producer.address),
    ]);
    
    // Create and execute trade
    block = chain.mineBlock([
      Tx.contractCall(
        "energy-grid",
        "create-trade-order",
        [types.uint(50), types.uint(10)],
        producer.address
      ),
      Tx.contractCall(
        "energy-grid",
        "execute-trade",
        [types.uint(0)],
        consumer.address
      ),
    ]);
    
    // Trigger settlement
    block = chain.mineBlock([
      Tx.contractCall(
        "energy-grid",
        "trigger-settlement",
        [],
        deployer.address
      ),
    ]);
    
    // Verify final states
    const producerInfo = chain.callReadOnlyFn(
      "energy-grid",
      "get-participant-info",
      [types.principal(producer.address)],
      deployer.address
    );
    const consumerInfo = chain.callReadOnlyFn(
      "energy-grid",
      "get-participant-info",
      [types.principal(consumer.address)],
      deployer.address
    );
    
    // Assert final states
    assertEquals(block.receipts[0].result, '(ok true)');
  },
});
