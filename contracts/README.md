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

Once the player has gas on at least two chains, the game will allow them to start playing.  It will also create the player's pilot, if they don't have one already.  I've decided for now to drop the ERC721 functionality and just shuttle a struct back and forth between chains.  I'll also allow multichain origins for this demo, to make it easier for people to access the game.  This inherits the trust assumptions I mentioned above, and I think a more complete version of the game would require pilots to be created on a single origin chain.  At the moment, accessiblity is the goal.

<img width="1018" alt="interior1" src="https://github.com/Cactoidal/Stardust/assets/115384394/36de3212-28f4-4065-a13c-c75c931d1f3b">

Here's the interior of your ship.  Let's pretty it up.

I'd like for the player's interaction with computer consoles to be seamless, which means being able to click on a 2D surface while existing in 3D space.  This is complicated by the mouse being invisible in first-person mode.  I decided to use a raycast from the camera to detect the clickable spot on the console.  Godot's "Visible Collision Shapes" toggle makes this easier to test: here the blue square in the center of the screen is actually the view of the ray from the back.  Once it collides with the button on the console, I can click to interact.

https://github.com/Cactoidal/Stardust/assets/115384394/083e220e-7bf6-4abc-84f6-938b5127445f

I spent a little time reorganizing the game's variables into a globally-available singleton.  Godot "scenes" are bundles of nodes, with a node being a generic game object like a 3D mesh, a 2D label, a sound, and so on.  Nodes are organized into a hierarchical tree, and they can refer to one another by referencing their positions in the tree.  

When a game needs its variables to be accessible to all nodes at all times, it can be helpful to create a singleton script and load it at runtime using Godot's Autoload feature.  This way, there's a point of reference for every node in the game, no matter when it comes into existence.  It also makes pathing between nodes much simpler.  

My RayCast, for example, is colliding with a 3D collision shape attached to a parent of a Viewport containing the 2D buttons.  Rather than trying to path to the buttons directly from the RayCast's script, I can put a script on the Viewport to load itself as a variable into the singleton.  The RayCast can then call to the buttons using that variable in the singleton.

https://github.com/Cactoidal/Stardust/assets/115384394/05a18ed3-91d6-4766-8267-dea55565f9ba

For the FPS controller, I want to give credit for the Player.gd script to [https://github.com/GarbajYT/godot_updated_fps_controller](https://github.com/GarbajYT/godot_updated_fps_controller), it works pretty great as-is.  All I changed was the movement speed and jump height, and added a toggle for accessing the Config menu by pressing ESC.

## Day 5

Happy to say that the basic game loop now totally works: a player can send their pilot around to all 5 CCIP'd testnets.  A bit sparse, but it's complete.  There are a few bugs that I need to work out, and I have a few more things to tweak, but I plan to export the game soon.

I still have time to add more features, which I'll write about later, but this release will exist as a back-up in case things go awry and I don't have time to get back to a working version.

I'll be exporting for Mac Silicon, and potentially Linux.  Games using Godot Rust can absolutely work on different platforms, not just Mac.  But there's a catch: the Rust library needs to be compiled for the target system.  The easiest way to do this is by compiling in the target environment, which I will try to do if time allows.

While I'm on the subject, I wanted to mention a couple other caveats: Godot Rust is definitely capable of running on the newest stable version of Godot (4.1) as the maintainers have worked hard to update it for the new GDExtension system, and that's something I want to look into later, since it should make everything run even better than it does now.

And a note about the code: while playing, you will notice that transactions and blockchain-reads will briefly lag the rest of the game, as Ethers-rs awaits a response from RPC nodes.  I would imagine there is some way to run Rust code on its own thread separate from the game's main thread, but I'm not quite sure how to do it.

https://github.com/Cactoidal/Stardust/assets/115384394/15acf4e4-5c0a-475a-a0ea-e4a4ea0befec

As it stands, many of my Rust-Godot interactions I've coded with the expectation that the main thread will wait for a response from Rust, and for everything involving Ethers-rs, Rust async will not proceed until it gets a response from an RPC node.  So with my current code patterns the lag is a necessity, since the game otherwise would crash trying to use data it hasn't been given yet.  If somehow I could get my RPC queries to run without lagging the main game thread, I would need to rewrite my gdscript to tolerate the lag in RPC response time.

And there it is: [the pre-release of Stardust](https://github.com/Cactoidal/Stardust/releases), and all game files have been uploaded.  Checkpoint reached.  Now that I've hammered out the basic version of the game, it's time to add more game mechanics: cargo, and exploring the ship itself.

# DAY 6

It stands to reason that a game about space commerce should have some competition.  Naturally, this means that smuggling contraband goods from chain to chain is the riskiest, but most rewarding aspect of gameplay.

There are three types of cargo:
+ Anodyne, which is free, and gives a small reward when sold.
+ Tech, which has a modest cost and a modest reward,
+ and Contraband, which is the most expensive, and commands the highest premium on the market.

Each type of cargo takes up 10 units of space in your ship's cargo hold, so it's up to you which combination of goods you want to take.  But here's where things get tricky:  if you decide to risk it and carry Contraband, you stand to gain a handsome reward should you go undetected.  But players on your destination chain can see you coming, and if they wish, they can choose to put up some collateral and put down a Contraband claim on your cargo.  

When you land and try to sell, if you have Contraband in your hold and someone has put down a claim, not only will you lose all your cargo AND the money you spent to buy it, but they will receive a small reward: 1/10 of the money you lost.

However, if they were wrong, and your cargo was clean, they lose their collateral deposit, and you take it as an extra reward.

But how does this work, if everything on-chain is public?

First, there are a couple rules.  Your hold will always be considered "full" when you leave, even if you don't actually max out.  And when you land, you have to sell your cargo on the destination chain before leaving.  You also aren't allowed to modify your ship or spend money until you sell.  Why?

Because the contents of your cargo are obscured by a hash.  Before leaving one chain for another, you will choose the amounts of the three types of cargo you want to take; these three values will be concatenated with a salt randomly generated by Godot, and then hashed.

The hash is put on-chain, and it's impossible for anyone but you to know what it represents.  This means that anyone putting a claim down on your cargo is taking a risk that you may or may not be carrying Contraband - because they can't actually see inside your ship.   They just see the hash!

When you arrive at your destination, you must sell your cargo.  This is accomplished by submitting the three values and the salt on-chain (Godot will save these in a local manifest file for you, so no worries about losing your cargo if you close the application).  Indeed, the game handles the entire process - so, while the smart contract is coded to prevent erroneous transactions from slipping through, the game itself won't allow you to create a faulty manifest.

The smart contract checks that your submitted values are valid.  It first concatenates the values, hashes them, and compares the hash to the hash you submitted previously and carried cross-chain in your pilot struct.  It then checks the size and cost of your cargo.  The amounts you pick cannot exceed the size of your hold, and you also can't put more things in your hold than you have money to buy.

The cost of the goods is subtracted from your balance retroactively (but you will make more in revenue than you lose from the cost of business - especially if you successfully shipped Contraband).

If there's a claim on your goods, the smart contract checks to see if you had any Contraband.  You could certainly choose to NOT reveal - but then your ship and your money would be permanently bricked, because you can neither leave the chain nor spend your money until you reveal.

![commit-reveal](https://github.com/Cactoidal/Stardust/assets/115384394/4279c398-a18d-4429-bedf-deb258595423)

When I say "money", of course, I'm referring to game tokens, which are to be had in abundance, and it's not the end of the world if you happen to get caught.  But as ship sizes get larger and the allure of massive Contraband payouts tantalize players, the risk of putting down claims on big ships could pay off in a big way.

Anyway, this required some creative engineering, since Godot needs to create a hash that takes into account abi.encode.  Ultimately I solved this with Ethers-rs, which has an AbiEncode trait just for this purpose.  Combined with the OpenSSL crate's SHA256, Godot Rust can produce the hash no problem.   Now I just need to create the UI that puts this all together in-game.

# DAY 7

It's coming together:

<img width="1018" alt="cargo console" src="https://github.com/Cactoidal/Stardust/assets/115384394/affd4bd4-8f9a-45db-9e20-4697fd36f133">

The next part will involve a redeploy of the smart contract, then hooking it up to Godot Rust.

I thought I would write a little about how I plan to prevent state bloat from causing problems when potential claimants are looking for incoming ships.  There needs to be a record of ships' departures and arrivals, so the game can check who is in transit from which chains to where.  But the game can't pull the entire record every time it wants to check; imagine if there were hundreds of players and they were frequently traveling back and forth, there would eventually be thousands upon thousands of departure and arrival events on each chain.

One way to solve this would be with an indexer that is looking for these events, and then loads them into a database.  Godot could then call into the database and quickly query to retrieve the data.  But it's also possible to organize the data on-chain so Godot can query only slices of the departure record at a time.

This is possible by organizing time into epochs.  The "epoch time" is refreshed if someone departs the chain at least 1800 seconds after the previous epoch time was set.  This will also increment the "current epoch" value.  Whenever someone leaves, their departure is recorded and pushed to an array mapped to the current epoch number.

When Godot needs to see if any ships are en-route from a chain, it will look at the current epoch number for that chain, and then pull the array mapped to that number.  It will also pull the array for "current epoch" - 1, just to make sure nobody gets missed.

Those arrays contain Departure structs with the pilot's departure timestamp inside, which Godot can then compare to the pilot's most recent arrival time on the destination chain.  If the departure time is greater than the arrival time, we know the ship is still in transit.


