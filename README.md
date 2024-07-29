# <p align=center >Weather Insurance DAO</p>
## Introduction

A decentralized and algorithmic insurance mechanism that grants automatic claims to policy holders based on the eligibility of the claim using oracles. As any usual insurance company does, this dApp 
also works on the similar mechanism on monthly premiums to provide timely, accurate claims. It's a 
low-premium - high-deductible mechanism( which means you are insured only for very catastrophic , high threat events but in turn you have to pay lower premiums every month).

Whenever you are eligible for a claim, the minimum you get is 2x of all your aggregate monthly premiums assuming risk pooling is working and you aren't the only user of the protocol. However, if your claim(2x of aggregate monthly premiums) exceeds 49% of the treasury, you are insured only 49% of treasury at most. This is to ensure stability in the protocol so that enough funds are left to insure low-balance policy holders without incurring any debt.

Adding to everything above, there's a penalty system as well. It's main purpose is to punish users for being inconsistent with their payments. Everytime a user pays a premium the timestamp of their latest payment is updated. However if a user fails to pay their premium for a period exceeding 3 months, they stand a chance to be liquidated by other users/ policy holders. This means that all of the shares held by the liquidated are seized and transferred to the one who liquidated him, indirectly handing over his stake in the protocol to the one who liquidated him.

### Demo explanation

The algorithm for granting claims in brief:
```
User A enters the insurance after paying his first monthly premium + a minimum deposit fee(20% of monthly premium) which does not count for insurance and is uninsurable

Once entered, he is awarded with the "share token" of the ERC4626 vault which represents his stake in the protocol

He is not eligible for a claim for a certain minimum period of 6 premiums

He must pay his premiums(along with deposit fees) periodically every month in order to be eligible for insurance after 6 premiums 

He cannot pay >= 2 premiums within the same month(this is to protect the protocol from bot attacks)

Each time he deposits his premium, it is put up for lending and earning interest in the AAVE lending pool. 

If he finds User B who is lagging with his premiums and hasn't paid in 3 months, User A can liquidate User B. Once a liquidation is performed, User B's stake is now transferred to User A and User B is kicked out of the protocol. 

If ever the withdrawal period comes, the entire premium aggregate is withdrawn from the lending pool, with the rewarded additional interest which also ensures stability of the treasury and safety of the protocol

If the aggregate premiums of User A * 2  exceed the 49% benchmark of the treasury, he is insured 49% of the treasury. Otherwise if the claim amount is lower than 49% of the treasury, he is insured the full claim amount i.e. aggregate premiums * 2

```

#### Proof of stability

-    As suggested above, the treasury maintains stability through a variety of processes. No unverified claims are allowed, with every deposit there is an additional deposit fee which is uninsured and collected solely to fundraise for the protocol. Also, whenever deposits are transferred to the lending pool, an additional interest is gained in favour of the treasury for the time which the assets are deposited.

#### Proof of claims

-    The benefit of using an ERC4626 vault as the treasury is that the share tokens issued to the policy holders represent not just their stake in the protocol, but also their claim. The amount of shares held by policy holders signifies that when the time comes for their claims to fruition, they are owed either their stake/aggregate premiums * 2 OR 49% of the treasury, whichever is lower.

<br>
<br>

## Getting started

### Prerequisites

List the tools and versions required to work on the project. For example:

- [Foundry](https://getfoundry.sh/) - A blazing fast, portable, and modular toolkit for Ethereum application development written in Rust.
- [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) - A linux-like terminal in windows systems. Necessary if you want to run foundry.
- [Metamask](https://metamask.io/download/) - A browser-extension which acts as a wallet for the ethereum blockchain, and other test networks

### Installation

Step-by-step instructions to set up the project locally.

1. **Install Foundry:**
   ```sh
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
    ```

2. **Clone the repository**
    ```sh
    git clone https://github.com/Aaryan-Urunkar/Insurance-DAO.git
    cd Insurance-DAO
    ```
<br>
<br>

3. **Install dependencies**
    ```sh
    forge install
    npm install
    ```

4. **Compile all contracts**
    ```sh
    forge build
    ```


### Usage

## Tests

To run the tests on a forked environment, create a ``` .env ``` file with the following:

- ```SEPOLIA_RPC_URL``` : You can easily get this from <a href="https://www.alchemy.com/">Alchemy</a>

    **Run the test**
    ```bash
    forge test --fork-url $SEPOLIA_RPC_URL 
    ```

## Use the dApp(pre deployed)

The dApp was made with DAI being the token to be used in mind. If you do not have DAI, I would suggest that you go to a <a href="https://staging.aave.com/faucet/">faucet</a> and mint some DAI for yourself

Good. Once you have minted some DAI for yourself, and are interested in joining the Insurance Protocol by depositing your first premium, open this <a href="https://sepolia.etherscan.io/token/0xFF34B3d4Aee8ddCd6F9AFFFB6Fe49bD371b8a357">link</a> which takes you to the DAI token. Under the ``Contract`` section, go to `Write Contract` and click on approve. There you see a red circle and a prompt asking you to connect your web3 wallet. Go ahead and connect that. Now, in `Write Contract` you should find an `approve` function. For the parameters put the deployed address of the Operations.sol from notes.txt file in this repo and set the approved amount to 190000000000000000000 (190 DAI basically). 

Great! Once you have approved the Operations.sol to hold some DAI, you can now transfer your first premium. Click on this <a href="https://sepolia.etherscan.io/address/0xA6C979E690d4a4D962f06c0344424641121A7458#writeContract">link, </a> go to `Write Contract` section, find the depositToPolicy function, and under the parameters pass the same amount from above which you had approved earlier. 190000000000000000000. Wait fot the transaction to go through and confirm itself. And Voila! You have deposited your first premium in the Weather Insurance DAO.

## Use the dApp(create your own instance)

To deploy your own Operations.sol contracts, you need 2 prerequisites:
- Chainlink Functions subscription
- OpenWeather API key

<br>
<br>


1. **Create a .env.enc with encrypted environment variables**
<br>

    To store your encrypted environment variables, follow the following steps:

    Set a password. This is a mandatory step everytime you kill a terminal and open a new one. Your password let's you access your environment variables and modify them. While the enviroment variables are stored permananently in the .env.enc file in an encrypted form, your password needs to be set anew everytime a new terminal is opened.

    ```bash
    npx env-enc set-pw
    ```

    Once you set a password, put in the environment variables:
    ```bash
    npx env-enc set
    ```

    Now to view them anytime in an unencrypted form you can try using this command:
    ```bash
    npx env-enc view
    ```

    You must have 3 mandatory environment variables:
    `SEPOLIA_RPC_URL` , `PRIVATE_KEY` and `OPENWEATHER_API_KEY`

<br>
<br>


2. **Generate a file containing your encrypted API key and host it online**
<br>

    This protocol requires using Chainlink functions to call external APIs. However, you always want to prevent storing your API key on chain at all costs and risk exposing it to others. Hence, to do that, what you can do it host your OpenWeather API key online in an encrypted form and encrypt the URL as well into bytes which the Chainlink DON nodes only can use to do the needed api calls.

    To generate a file with your encrypted secrets/api keys, run the following commands. However, I suggest you first make sure you are in the root directory of the project and have all the required environment variables in place in your .env.enc.

    ```bash
    node javascript-stuff/gen-offchain-secrets.js
    ```

    This creates a offchain-secrets.json file in your root directory. It contains your OpenWeather API key in an encrypted form. Upload the file to your Google Drive or AWS (if you have one). For Google Drive, set the access of the file to "Anyone can view with link" and set the permission to viewer. Lastly, copy the link of the file. 
    
    Since you have to encrypt the URL into bytes, open the `encrypt-secrets-urls.js` file and paste your drive URL in the secrets URLs by replacing the existing one. Once you have done that, run this script using the following command.

    ```bash
    node javascript-stuff/encrypt-secrets-urls.js
    ```

    This returns a huge collection of bytes which is the encrypted URL containing your encrypted secrets which will be used by Chainlink Functions to make API calls off-chain.

<br>
<br>

3. **Deploy contracts**
<br>

    Now we move on to deploying the contracts. For the purposes of this project, I have configured the deployment to succeed only for the ETHEREUM SEPOLIA( chain ID: 11155111 ) network. Before commencing the deployments, I suggest you go to <Chainlink href="https://functions.chain.link/">Chainlink Functions</a> and create a subscription.

    Good. Now to deploy all the contracts to Sepolia just follow the below scripts in order:

    ```bash
    source .env
    forge script script/DeployInsuranceVault.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --private-key $PRIVATE_KEY --verify --etherscan-api-key $ETHERSCAN_API_KEY  
    ```

    To deploy Operations.sol:
    ```bash
    source .env
    forge script script/DeployOperations.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --private-key $PRIVATE_KEY --verify --etherscan-api-key $ETHERSCAN_API_KEY --sig "run(bytes)" {YOUR BYTES ENCRYPTED SECRETS URL}
    ```

    Open the deployed InsuranceVault.sol contract on etherscan and under the `Write Contract` section open the setVaultAndPoolProvider() function. The first address must be the address of the deployed Operations.sol contract and the second address is the address of the AAVE PoolAddressesProvider contract which can be fetched from here.

    Just for your reference, the contract of the AAVE PoolAddressesProvider of the Sepolia testnet for your reference is: `0x012bAC54348C0E635dCAc9D5FB99f06F24136C9A`

    Copy and paste this address into the poolAddressesProvider argument. 

    Wonderful! Now you have successfully and fully set up your own Weather Insurance system on the sepolia network!
    