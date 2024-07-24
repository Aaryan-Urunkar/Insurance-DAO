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
## Getting started


