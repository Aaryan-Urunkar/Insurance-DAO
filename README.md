# <p align=center >Weather Insurance DAO</p>
## Introduction

A decentralized and algorithmic insurance mechanism that grants automatic claims to policy holders based on the eligibility of the claim using oracles. As any usual insurance company does, this dApp 
also works on the similar mechanism on monthly premiums to provide timely, accurate claims. It's a 
low-premium - high-deductible mechanism( which means you are insured only for very catastrophic , high threat events but in turn you have to pay lower premiums every month).

Whenever you are eligible for a claim, the minimum you get is 2x of all your aggregate monthly premiums assuming risk pooling is working and you aren't the only user of the protocol. However, if your claim(2x of aggregate monthly premiums) exceeds 49% of the treasury, you are insured only 49% of treasury at most. This is to ensure stability in the protocol so that enough funds are left to insure low-balance policy holders without incurring any debt.

### Demo explanation

The algorithm for granting claims in brief:
```
User A enters the insurance after paying his first monthly premium + a minimum deposit fee(20% of monthly premium) which does not count for insurance and is uninsurable

Once entered, he is awarded with the "share token" of the ERC4626 vault which represents his stake in the protocol

He is not eligible for a claim for a certain minimum period of 6 premiums

He must pay his premiums(along with deposit fees) periodically every month in order to be eligible for insurance after 6 premiums 

He cannot pay >= 2 premiums within the same month(this is to protect the protocol from bot attacks)

Each time he deposits his premium, it is put up for lending and earning interest in the AAVE lending pool. 

If ever the withdrawal period comes, the entire premium aggregate is withdrawn from the lending pool, with the rewarded additional interest which also ensures stability of the treasury and safety of the protocol

If the aggregate premiums of User A * 2  exceed the 49% benchmark of the treasury, he is insured 49% of the treasury. Otherwise if the claim amount is lower than 49% of the treasury, he is insured the full claim amount i.e. aggregate premiums * 2

```

#### Proof of stability

-    As suggested above, the treasury maintains stability through a variety of processes. No unverified claims are allowed, with every deposit there is an additional deposit fee which is uninsured and collected solely to fundraise for the protocol. Also, whenever deposits are transferred to the lending pool, an additional interest is gained in favour of the treasury for the time which the assets are deposited.

#### Proof of claims

-    The benefit of using an ERC4626 vault as the treasury is that the share tokens issued to the plicy holders represent not just their stake in the protocol, but also their claim. The amount of shares held by policy holders signifies that when the time comes for their claims to fruition, they are owed either their stake/aggregate premiums * 2 OR 49% of the treasury, whichever is lower.

<br>
<br>

## Getting started

### Prerequisites

List the tools and versions required to work on the project. For example:

- [Foundry](https://getfoundry.sh/) - A blazing fast, portable, and modular toolkit for Ethereum application development written in Rust.
- [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) - A linux-like terminal in windows systems. Necessary if you want to run foundry.

### Installation

Step-by-step instructions to set up the project locally.

1. **Install Foundry:**
   ```sh
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
    ```

2. **Fork the repository**

<br>
<br>

3. **Install dependencies**
    ```sh
    forge install
    ```

4. **Compile all contracts**
    ```sh
    forge build
    ```


