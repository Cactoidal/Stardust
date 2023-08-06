// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./IStarCoin.sol";
import "./IPilot.sol";

contract TestDust2 is CCIPReceiver, IERC721Receiver {
    enum PayFeesIn {
        Native,
        LINK
    }

    function onERC721Received( address operator, address from, uint256 tokenId, bytes calldata data ) public override returns (bytes4) {
            return this.onERC721Received.selector;
        }

    event MessageSent(bytes32 messageId);

    address PILOT;
    address STARCOIN;

    address immutable ROUTER;
    address immutable CHAINLINK;

    constructor(address _router, address _pilotNFT, address _starcoin, address _link) CCIPReceiver(_router) {
        PILOT = _pilotNFT;
        STARCOIN = _starcoin;
        ROUTER = _router;
        CHAINLINK = _link;
        LinkTokenInterface(CHAINLINK).approve(ROUTER, type(uint256).max);
    }



    receive() external payable {}

    




    uint constant FOOD_SIZE = 10;
    uint constant MEDICINE_SIZE = 20;
    uint constant METAL_SIZE = 30;
    uint constant TECH_SIZE = 40;
    uint constant ANTIMATTER_SIZE = 100;

    //will vary based on chain and travel conditions
    int public FOOD_PRICE = 5;
    int public MEDICINE_PRICE = 10;
    int public METAL_PRICE = 20;
    int public TECH_PRICE = 100;
    int public ANTIMATTER_PRICE = 1000;

    uint constant SHIP1_SIZE = 100;
    uint constant SHIP2_SIZE = 1000;
    uint constant SHIP3_SIZE = 5000;
    uint constant SHIP4_SIZE = 25000;

    struct Pilot {
        string name;
        uint16 portrait;
        uint16 level;
        uint256 id;
        address employer;
        uint shipSize;
        uint32[4] mods;
        uint[2][] cargo;
        uint256 coinBalance;
        uint32 job;
        bool onChain;
    }

    mapping(address => bool) depotDeployed;
    mapping(uint => Pilot) pilotRecord;
    mapping(address => uint) lastFreeGas;


    //  PILOT  //

    //todo: check msg.value is working as intended
    function mintPilot(string calldata _name, uint16 _portrait) public {
        require(_portrait >= 1 && _portrait <= 8);
        createPilot(msg.sender, _name, _portrait, IPilot(PILOT).getId());
    }


    function createPilot(address _employer, string calldata _name, uint16 _portrait, uint _id) internal {
        Pilot memory newPilot;
        newPilot.name = _name;
        newPilot.employer = _employer;
        newPilot.level = 1;
        newPilot.portrait = _portrait;
        newPilot.shipSize = SHIP1_SIZE;
        newPilot.id = _id;
        newPilot.onChain = true;
        pilotRecord[_id] = newPilot;
        IPilot(PILOT).mint(_employer);
    }

    //need to whitelist crosschain addresses

//CCIP Send
    function pilotSend(uint _id, uint64 destinationChainSelector, address receiver, PayFeesIn payFeesIn) public {
        require(IERC721(PILOT).ownerOf(_id) == msg.sender);
        
        IERC721(PILOT).safeTransferFrom(msg.sender, address(this), _id, "");
        pilotRecord[_id].onChain = false;
        send(destinationChainSelector, receiver, payFeesIn, pilotRecord[_id]);
    }


function send(
        uint64 destinationChainSelector,
        address receiver,
        PayFeesIn payFeesIn,
        Pilot memory _pilot
    ) internal {
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: abi.encode(_pilot),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 750_000, strict: false})),
            feeToken: payFeesIn == PayFeesIn.LINK ? CHAINLINK : address(0)
        });

        uint256 fee = IRouterClient(ROUTER).getFee(
            destinationChainSelector,
            message
        );

        bytes32 messageId;

        if (payFeesIn == PayFeesIn.LINK) {
            // LinkTokenInterface(i_link).approve(i_router, fee);
            messageId = IRouterClient(ROUTER).ccipSend(
                destinationChainSelector,
                message
            );
        } else {
            messageId = IRouterClient(ROUTER).ccipSend{value: fee}(
                destinationChainSelector,
                message
            );
        }

        emit MessageSent(messageId);
    }


     function _ccipReceive(
        Client.Any2EVMMessage memory message
    ) internal override {
        Pilot memory arrivingPilot = abi.decode(message.data, (Pilot));
        pilotRecord[arrivingPilot.id] = arrivingPilot;
        IPilot(PILOT).instantiate(arrivingPilot.employer, arrivingPilot.id);
        //pilotReceive(arrivingPilot);
    }


    //CCIP Receive
    function pilotReceive(Pilot memory _pilot) internal {
        //Requires CCIP is msg.sender


        IPilot(PILOT).instantiate(_pilot.employer, _pilot.id);

        
        // Check if pilot exists on-chain yet, mint if not
        
        if (pilotRecord[_pilot.id].level == 0) {
            IPilot(PILOT).instantiate(_pilot.employer, _pilot.id);
            }
        else {
            IERC721(PILOT).safeTransferFrom(address(this), _pilot.employer, _pilot.id, "");
            }

        // Depot must exist on sender chain, therefore it exists on recipient chain
        
        depotDeployed[_pilot.employer] = true;

        pilotRecord[_pilot.id] = _pilot;

        executeInstructions(_pilot);
        
        
        
    }


    // Sells all cargo for market price immediately upon landing 
    // "instructions" currently have no function
    function executeInstructions(Pilot memory _pilot) internal {

        pilotRecord[_pilot.id].coinBalance += 10000000000000000000000000000;
      
        
    }


    function withdrawStarCoins(uint _id) public {
        require (pilotRecord[_id].employer == msg.sender);
        require (pilotRecord[_id].onChain == true);
        uint transferBalance = pilotRecord[_id].coinBalance;
        pilotRecord[_id].coinBalance = 0;
        IStarCoin(STARCOIN).mint(msg.sender, transferBalance);
    }

    //used to bridge starcoins by putting them on a ship
    function depositStarCoins(uint _id, uint _amount) public {
        require (pilotRecord[_id].employer == msg.sender);
        require (pilotRecord[_id].onChain == true);
        require (IERC20(STARCOIN).balanceOf(msg.sender) >= _amount);
        pilotRecord[_id].coinBalance += _amount;
        IERC20(STARCOIN).transferFrom(msg.sender, address(this), _amount);
    }

    function getPilots(address _employer) public view returns (uint[] memory ids) {
        uint balance = IERC721Enumerable(PILOT).balanceOf(_employer);
        ids = new uint[](balance - 1);
        for (uint i = 0; i < balance; i++) {
            ids[i] = (IERC721Enumerable(PILOT).tokenOfOwnerByIndex(_employer, i));
        }
        return ids;
    }

    function pilotInfo(uint _id) public view returns (Pilot memory) {
        return pilotRecord[_id];
    }


    // this and updateEmployer are used by NFT contract to update 
    // the Pilot struct when someone sells/transfers their NFT 
    function checkAvailable(uint _id) external view returns (bool) {
        return pilotRecord[_id].onChain;
    }
   
    function updateEmployer(uint _id, address _employer) external {
        //this check may not be safe
        require(msg.sender == PILOT);
        pilotRecord[_id].employer = _employer;
    }

    




}
