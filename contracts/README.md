# Devblog

## Day 1

We bounced a lot of ideas back and forth, knowing that we wanted to make a game and we wanted to make tooling.  A big question was what kind of game (survival horror on the blockchain, anyone?)  After a lot of deliberation, we decided to make a space commerce game, where players ship cargo between different blockchains (represented as galaxies), with our own custom infrastructure to bring data from cross-chain and render it in-game and on an analytics dashboard.   We'll be using CCIP to ferry ships from one chain to another.

Today I wrote the draft for our smart contracts, which allow players to mint pilots, take on shipments, and upgrade their ships, along with some other features.  It still needs to be Chainlinked, and it's gonna need a lot of testing, but the basic logic of the game is there.  If we have time, I'd love to add things like missions and more multiplayer-oriented gameplay, but for now, this should be sufficient to start hooking things up.

We'll be using Godot as our game engine, and a nice Metamask plugin created two years ago, which you can find here:
[https://github.com/nate-trojian/MetamaskAddon](https://github.com/nate-trojian/MetamaskAddon)

I'll be modifying the plugin script to add our game's functions, the process of which I'll talk about more in a future devblog post.

For today's post, I wanted to mention the Trigonometry.sol library, which I'm hoping to use as a means of creating a predictable "price wave" over time, to simulate real price action.  The idea is that the sin() function will digest block numbers, oscillating the price from block to block.  I thought this would produce a more gentle curve, but sequential blocks seems to produce wildly different values, which tells me I wrote my function wrong. Then again, the seeming randomness may end up being better for the game.  Will revisit later!


## Day 2

Now that we have a smart contract, we know what kind of data the game needs to track every time someone starts playing.  Have they deployed at least 1 gas depot?  What ships do they have, what are their characteristics, where are they located?  How much game currency and gas do they have?  What are the prices of goods and commodities on the different chains?

We also know the main actions a player can take:  minting a pilot, loading the ship's cargo bay, choosing a destination galaxy, warping, and upgrading the ship.

The task, therefore, is to build an interface that links the player to all these actions, allowing them to make decisions based on the data the game gives them.

But first:

<img width="1463" alt="test_ship" src="https://github.com/Cactoidal/Stardust/assets/115384394/9079825c-8e64-408f-abff-31a1a3c5a8b9">

Shiny.  Metal shader from here:
[https://godotshaders.com/shader/simple-3d-metal/](https://godotshaders.com/shader/simple-3d-metal/)

Model from Shipyard (Strikes Back), a free public domain ship model pack on sketchfab.  Thank you!
[https://sketchfab.com/3d-models/shipyard-strikes-back-773e8884db274792a3c424ed68953c08](https://sketchfab.com/3d-models/shipyard-strikes-back-773e8884db274792a3c424ed68953c08)


https://github.com/Cactoidal/Stardust/assets/115384394/336f4304-fea6-4deb-9b2e-af74e235564a

The background shader is from [https://godotshaders.com/shader/cheap-water-shader/](https://godotshaders.com/shader/cheap-water-shader/), and is applied to a flat mesh behind the ship.  While the final game will certainly look different, it's important to test how many particles and shaders the browser can handle.  Also, it's fun.

A few tweaks...

https://github.com/Cactoidal/Stardust/assets/115384394/060d171a-6fa5-4bfd-83f0-cda4fa45ab8c

I decided to break the contract down a bit and create a cross-chain NFT for testing.  For this I will need to pass a struct to CCIP to instantiate the NFT on the destination chain.  I ran into some difficulty trying to encode the struct, but luckily [Chainlink's Tic-Tac-Toe example game](https://github.com/smartcontractkit/ccip-tic-tac-toe) shows how to do it properly.  

I also thought more about the design of the token bridge.  Originally, I had planned to allow minting of Pilots on any chain.  To prevent collision of the tokenID, IDs would be 33 digits long and each chain would have its own identifiying first digit (i.e. Optimism starting with 1000000000000000000000000000000000, AVAX with 2000000000000000000000000000000000, etc.).  Allowing multichain origins would allow anyone to start playing on any chain, and pilot minting would seed gas on each chain, which could then be used as a faucet whenever someone bridges over without any gas in their wallet.

This introduces however a major trust assumption, in that hypothetically I could implement a malicious minting contract (or simply make a mistake) when adding a new chain to the system, which would break everything.  Therefore, I decided to alter the contract slightly to allow Pilot minting only on Optimism.  This eliminates one major trust assumption about the system, but there's still another one to deal with: the possibility of a malicious or exploitable bridge getting whitelisted by the main contract. 

While "true" Pilots can only be minted on Optimism, a malicious bridge could mint fake pilots that spoof the credentials of the real Pilots staked on the Optimism side of the bridge.  When the fake pilot gets sent over, the contract would then believe the owner of the fake pilot is also the owner of the real Pilot, and transfer it over upon receipt of the CCIP message.

To guard against this, the Pilot will have a new array of bridge approvals added to its struct.  If the Pilot doesn't have a bridge listed in its approval array, it'll be impossible to send it over that bridge, and it will ignore malicious requests to withdraw sent from that bridge.  The Pilot's owner can choose to grant or revoke approval for a given bridge.

I was finally able to make _ccipReceive work once I realized my gas limit was too low.  Whoops!  I'll implement the above ideas into the main smart contracts later.  For now, I'll upload my "test contract" that I'll use for my preliminary work on the player interface in Godot.

## Day 3

The Godot Metamask plugin allows the game client to interact directly with smart contracts.  It does this by constructing the transaction payload and passing it to the Metamask API.  This means that, for any contract we want to interact with, we need to have the function selector for any functions we plan to use, and we need to properly construct the calldata.

For this initial interface, I will need three functions: the mintPilot() and pilotSend() functions on the main game contract, and the approve() function from the Pilot contract.  I used Remix to get the function selectors, by compiling the contracts and clicking the "compilation details" button, and then "function hashes".  To get an idea of what the calldata is supposed to look like, I called each function and looked at the calldata on Etherscan.  Here's what we got:


mintPilot(string,uint16)

4a154586  

0x4a154586000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000009726f6f6f6f6f6275730000000000000000000000000000000000000000000000


pilotSend(uint256,uint64,address,uint8) 

8971ba5d  

0x8971ba5d000000000000000000000000000000000000629b8c891b267182b61400000005000000000000000000000000000000000000000000000000de41ba4fc9d91ad90000000000000000000000009c9b744269a59826dfb6c199402254401ccac1fe0000000000000000000000000000000000000000000000000000000000000001


approve(address,uint256)

095ea7b3 

0x095ea7b300000000000000000000000018058e6af3af65ed30307b72d055c77f3bcd3a8e000000000000000000000000000000000000629b8c891b267182b61400000005


[There are handy explainers online for what calldata represents,](https://www.quicknode.com/guides/ethereum-development/transactions/ethereum-transaction-calldata) but essentially it starts with the function selector and is followed by the encoded function parameters, with padding in the form of 0s to fill out the bytes of each parameter's data type.  Each data type has a different number of bytes, requiring a different amount of padding

<img width="761" alt="godot_metamask" src="https://github.com/Cactoidal/Stardust/assets/115384394/b416e211-cac0-4660-bb35-01818433c178">

The plugin takes care of almost everything for you.  The main task is to format the calldata, seen here under the "action" variable.  a9059cbb is the function selector for an ERC20 transfer, 24 0s are added to fill out the recipient address, and the amount of padding necessary for the transfer amount depends on how much is being transferred.

To add our own function to our game, we'll need to similarly fill in the calldata according to our function's parameters, and supply the contract address under the "to" key of the request_dict.
