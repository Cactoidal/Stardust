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

Insecurity is the major flaw of this approach, since a malicious minting contract on one chain (or simply a mistake) could break the entire system.  Therefore, I decided to alter the contract slightly to allow Pilot minting only on Optimism.  This eliminates one major trust assumption about the system, but there's still another one to deal with: what happens if a malicious bridge is implemented?  

While "true" Pilots can only be minted on Optimism, a malicious bridge could mint fake pilots that spoof the credentials of the real Pilots staked on the Optimism side of the bridge.  The contract would then believe the owner of the fake pilot is also the owner of the real Pilot, and transfer it over.

To guard against this, the Pilot will have a new array of bridge approvals added to its struct.  If the Pilot doesn't have a bridge listed in its approval array, it'll be impossible to send it over that bridge, and it will ignore malicious requests to withdraw sent from that bridge.  The Pilot's owner can choose to grant or revoke approval for a given bridge.






