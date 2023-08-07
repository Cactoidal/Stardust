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


[There are handy explainers online for what calldata represents,](https://www.quicknode.com/guides/ethereum-development/transactions/ethereum-transaction-calldata) but essentially it starts with the function selector and is followed by the encoded function parameters, with padding in the form of 0s to fill out the bytes of each parameter's data type.  Each data type has a different number of bytes, requiring a different amount of padding.

<img width="761" alt="godot_metamask" src="https://github.com/Cactoidal/Stardust/assets/115384394/b416e211-cac0-4660-bb35-01818433c178">

The plugin takes care of almost everything for you.  The main task is to format the calldata, seen here under the "action" variable.  a9059cbb is the function selector for an ERC20 transfer, 24 0s are added to fill out the recipient address, and the amount of padding necessary for the transfer amount depends on how much is being transferred.

To add our own function to our game, we'll need to similarly fill in the calldata according to our function's parameters, and supply the contract address under the "to" key of the request_dict.

<img width="720" alt="functions" src="https://github.com/Cactoidal/Stardust/assets/115384394/683a1349-8214-4e0f-9ac9-064132d9deb0">

It would be pretty hard to do this without being able to compare to calldata on Etherscan.  In mint_pilot(), why is there a 4 wedged between 62 zeroes and 64 zeroes?  Frankly, I don't know.  approve_transfer() makes more sense, with 24 bytes padding the address and the 64 byte length of pilot_id.  Note that Godot numbers have a size limit, and very large integers will cause errors.

## Day 3.5

Due to unforeseen circumstances, the indexer and dashboard will not be available, as the person responsible will not be joining after all.  The game also will no longer be developed for the browser.  I'll have to pivot to a downloadable app instead.  But there are benefits!  Now that the game will be running locally, I can use better graphics, and most importantly, I can also use the reliable and powerful Ethers-rs Rust crate to do something I haven't tried before: read and write cross-chain.  

Luckily I hadn't gotten too deep into using the Metamask plugin before this turn of events, and while I've ended up not using the plugin for this project, hopefully those interested in creating web3 browser games with Godot will give it a try.

But on to Rust.  Godot Rust is a fantastic community-driven project that enables us to extend the functionality of the Godot engine; combined with Ethers-rs, my game application can generate and store secret keys locally, and use them to sign transactions.

[I'll be starting with some boilerplate code](https://github.com/Cactoidal/Stardust/blob/main/godot/rust/lib.rs) that I've developed for this purpose, as to my knowledge no other tool exists to bring this kind of functionality into Godot.

An especially beautiful part of Ethers-rs is its ability to seamlessly interact cross-chain, as I have just discovered:

<img width="1064" alt="crosschain balances" src="https://github.com/Cactoidal/Stardust/assets/115384394/02c96558-6365-445c-aeb9-51961a1d9c2d">

Alright, my UI may not be especially beautiful, but you get the idea.  When the game loads, it creates a keystore if it doesn't detect one, derives the player's EVM address from their secret key, and then checks their gas balance across three chains.  That was pretty easy.  Time to hook it up to my contract.

I've pared the contract down to make it less unwieldy.  There are now five functions to implement for Godot Rust:  createPilot(string), _ccipSend(uint64,address,1), pilotInfo(address), and lastDeparted(address) / lastArrived(address).  With these the player will be able to join the game, send their pilot between the connected chains, and see their stats.  The game will also be able to know if the player is still en-route if they restart the application during a CCIP transfer.

Ethers-rs can create a "Contract" object from an ABI.json, which I can then use to call my functions.

_ccipSend ended up being slightly tricky because the CCIP chain selectors are too large to pass as integers from gdscript into Rust.  [With some help from stackoverflow](https://stackoverflow.com/questions/32381414/converting-a-hexadecimal-string-to-a-decimal-integer) and [RapidTables](https://www.rapidtables.com/convert/number/decimal-to-hex.html), I ended up turning them into hex strings and converting them into u64 in Rust.  Problem solved.  Thanks, Shepmaster.

<img width="943" alt="ccip godot" src="https://github.com/Cactoidal/Stardust/assets/115384394/636d2dd5-933b-4906-b924-de209165dcc7">

Behold, the first CCIP transaction sent from Godot, using Godot Rust.

## Day 4

Pilots can now travel back and forth between chains, which needs to be represented in-game.  I like giving players the option of movement in games, even if it isn't integral to gameplay, and in this case you'll be playing in first person inside your ship.  Much of your time will be spent sitting around, of course, during those long flights from Sepolia to Mumbai, but the idea is to be immersive.

First, a somewhat better UI:

<img width="1018" alt="chains" src="https://github.com/Cactoidal/Stardust/assets/115384394/10fa8b37-4992-4e3c-9d0f-74f9fcc7d8f1">

Once the player has gas on at least one chain, the game will allow them to start playing.  It will also create the player's pilot, if they don't have one already.  I've decided for now to drop the ERC721 functionality and just shuttle a struct back and forth between chains.  I'll also allow multichain origins for this demo, to make it easier for people to access the game.  This inherits the trust assumptions I mentioned above, and I think a more complete version of the game would require pilots to be created on a single origin chain.  At the moment, accessiblity is the goal.

<img width="1018" alt="interior1" src="https://github.com/Cactoidal/Stardust/assets/115384394/36de3212-28f4-4065-a13c-c75c931d1f3b">

Here's the interior of your ship.  Let's pretty it up.

I'd like for the player's interaction with computer consoles to be seamless, which means being able to click on a 2D surface while existing in 3D space.  This is complicated by the mouse being invisible in first-person mode.  I decided to use a raycast from the camera to detect the clickable spot on the console.  Godot's "Visible Collision Shapes" toggle makes this easier to test: here the blue square in the center of the screen is actually the view of the ray from the back.  Once it collides with the button on the console, I can click to interact.

https://github.com/Cactoidal/Stardust/assets/115384394/083e220e-7bf6-4abc-84f6-938b5127445f




