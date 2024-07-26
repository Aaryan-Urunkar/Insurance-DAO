const fs = require("fs");
const path = require("path");
const { SecretsManager } = require("@chainlink/functions-toolkit");
const ethers = require("ethers");
require("@chainlink/env-enc").config();

const secretsUrls = [
  "https://drive.google.com/file/d/1Kd0NmRGWaPTrW7UvLx7codJML0TTMimS/view?usp=sharing",
  // Add more URLs if needed
];

const encryptSecretsUrls = async () => {
  // Initialize ethers signer and provider
  const privateKey = process.env.PRIVATE_KEY;
  if (!privateKey) {
    throw new Error("Private key not provided - check your environment variables");
  }

  const rpcUrl = process.env.SEPOLIA_RPC_URL;
  if (!rpcUrl) {
    throw new Error("RPC URL not provided - check your environment variables");
  }

  const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
  const wallet = new ethers.Wallet(privateKey);
  const signer = wallet.connect(provider);

  // Initialize SecretsManager instance
  const routerAddress = "0xb83E47C2bC239B3bf370bc41e1459A34b41238D0"; // Replace with your router address
  const donId = "fun-ethereum-sepolia-1"; // Replace with your DON ID
  const secretsManager = new SecretsManager({
    signer: signer,
    functionsRouterAddress: routerAddress,
    donId: donId,
  });

  await secretsManager.initialize();

  console.log(`\nEncrypting URLs...`);
  try {
    const encryptedSecretsUrls = await secretsManager.encryptSecretsUrls(secretsUrls);
    console.log(`\n✅ Encrypted URLs:`, encryptedSecretsUrls);
  } catch (error) {
    console.error(`\n❌ Error encrypting secrets URLs:`, error);
  }
};

encryptSecretsUrls().catch((error) => {
  console.error(error);
  process.exit(1);
});