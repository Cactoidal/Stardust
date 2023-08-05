# Devblog

## Day 1

We bounced a lot of ideas back and forth, knowing that we wanted to make a game and we wanted to make tooling.  A big question was what kind of game (survival horror on the blockchain, anyone?)  After a lot of deliberation, we decided to make a space commerce game, where players ship cargo between different blockchains (represented as galaxies), with our own custom infrastructure to bring data from cross-chain and render it in-game.   We'll be using CCIP to ferry ships from one chain to another.

Today I wrote the draft for our smart contracts, which allow players to mint pilots, take on shipments, and upgrade their ships, along with some other features.  It still needs to be Chainlinked, and it's gonna need a lot of testing, but the basic logic of the game is there.  If we have time, I'd love to add things like missions and more multiplayer-oriented gameplay, but for now, this should be sufficient to start hooking things up.

We'll be using Godot as our game engine, and a nice Metamask plugin created two years ago, which you can find here:
[https://github.com/nate-trojian/MetamaskAddon](https://github.com/nate-trojian/MetamaskAddon)

I'll be modifying the plugin script to add our game's functions, the process of which I'll talk about more in a future devblog post.
