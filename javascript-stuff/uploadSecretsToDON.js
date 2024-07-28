const fs = require("fs");
const path = require("path");
const { SecretsManager } = require("@chainlink/functions-toolkit");
const ethers = require("ethers");
const { log } = require("console");
require("@chainlink/env-enc").config();

const routerAddress = "0xb83E47C2bC239B3bf370bc41e1459A34b41238D0";
const donId = "fun-ethereum-sepolia-1";
const gatewayUrls = [
  "https://01.functions-gateway.testnet.chain.link/",
  "https://02.functions-gateway.testnet.chain.link/",
];
const slotIdNumber = 0; // slot ID where to upload the secrets
const expirationTimeMinutes = 4000; // expiration time in minutes of the secrets

const uploadSecrets = async () => {
  // Initialize ethers signer and provider to interact with the contracts onchain
  const privateKey = process.env.PRIVATE_KEY; // fetch PRIVATE_KEY
  if (!privateKey)
    throw new Error(
      "Private key not provided - check your environment variables"
    );

  const rpcUrl = process.env.SEPOLIA_RPC_URL; // fetch Sepolia RPC URL
  if (!rpcUrl)
    throw new Error("RPC URL not provided - check your environment variables");

  const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
  const wallet = new ethers.Wallet(privateKey);
  const signer = wallet.connect(provider); // create ethers signer for signing transactions

  // Initialize SecretsManager
  const secretsManager = new SecretsManager({
    signer: signer,
    functionsRouterAddress: routerAddress,
    donId: donId,
  });
  await secretsManager.initialize();

  // Define secrets to be encrypted
  const secrets = { apiKey: process.env.OPENWEATHER_API_KEY };

  // Encrypt secrets
  console.log("Encrypting secrets...");
  const encryptedSecretsObj = await secretsManager.encryptSecrets(secrets);

  console.log("Secrets encrypted. Uploading to DON...");

  // Upload encrypted secrets to the DON
  const uploadResult = await secretsManager.uploadEncryptedSecretsToDON({
    encryptedSecretsHexstring: encryptedSecretsObj.encryptedSecrets,
    gatewayUrls: gatewayUrls,
    slotId: slotIdNumber,
    minutesUntilExpiration: expirationTimeMinutes,
  });

  if (!uploadResult.success) {
    throw new Error(
      `Encrypted secrets not uploaded. Response: ${JSON.stringify(
        uploadResult
      )}`
    );
  }

  console.log("✅ Secrets uploaded successfully!");

  const uploadSecretsReference = secretsManager.buildDONHostedEncryptedSecretsReference({
    slotId : slotIdNumber , 
    version : uploadResult.version
  });

  // Fetch and log details of the uploaded secrets
  console.log(`Uploaded secrets details:`);
  console.log(`Version: ${uploadResult.version}`);
  console.log(`Success: ${uploadResult.success}`);
  console.log(`Response: ${JSON.stringify(uploadResult)}`);
  console.log(`DON hosted uploaded reference: ${uploadSecretsReference}`);
  console.log(`To gateways: ${gatewayUrls}`);
};

uploadSecrets().catch((e) => {
  console.error(e);
  process.exit(1);
});