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







