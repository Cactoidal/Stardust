// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NewPilot is CCIPReceiver, Ownable {
    enum PayFeesIn {
        Native,
        LINK
    }

    event MessageSent(bytes32 messageId);

    address immutable ROUTER;
    address immutable CHAINLINK;

    constructor(address _router, address _link) CCIPReceiver(_router) {
        ROUTER = _router;
        CHAINLINK = _link;
        LinkTokenInterface(CHAINLINK).approve(ROUTER, type(uint256).max);
        //Sepolia
        whitelistedDestinationChains[16015286601757825753] = true;
        whitelistedSourceChains[16015286601757825753] = true;
        //Optimism Goerli
        whitelistedDestinationChains[2664363617261496610] = true;
        whitelistedSourceChains[2664363617261496610] = true;
        //Avalanche Fuji
        whitelistedDestinationChains[14767482510784806043] = true;
        whitelistedSourceChains[14767482510784806043] = true;
        //Arbitrum Goerli
        whitelistedDestinationChains[6101244977088475029] = true;
        whitelistedSourceChains[6101244977088475029] = true;
        //Polygon Mumbai
        whitelistedDestinationChains[12532609583862916517] = true;
        whitelistedSourceChains[12532609583862916517] = true; 
    }

    struct Pilot {
        string name;
        address id;
        uint level;
        uint holdSize;
        bytes cargo;
        uint coinBalance;
        uint job;
        bool antimatterModule;
        bool recycler;
        bool dustCatcher;
        bool onChain;
    }

    mapping(address => Pilot) public pilots;
    mapping(address => Departure) public lastDeparted;
    mapping(address => uint) public lastArrived;

    struct Departure {
        address pilot;
        uint destinationSelector;
        uint departureTime;
    }

    mapping (uint => Departure[]) public epochs;
    uint public currentEpoch = 1;
    uint public epochTime;
    

    //  PILOT  //

    // Erase this function when deploying away from origin chain
    function createPilot(string calldata _name) public {
        require(pilots[msg.sender].level == 0);
        Pilot memory newPilot;
        newPilot.name = _name;
        newPilot.id = msg.sender;
        newPilot.level = 1;
        newPilot.holdSize = 100;
        newPilot.coinBalance = 50;
        newPilot.onChain = true;
        pilots[msg.sender] = newPilot;
    }

    //_cargo is a hash created from the cargo manifest
    function _ccipSend(
        uint64 destinationChainSelector,
        address receiver,
        PayFeesIn payFeesIn,
        bytes memory _cargo
    ) public onlyWhitelistedDestinationChain(destinationChainSelector) {

        require(pilots[msg.sender].onChain == true);
        require(  keccak256(abi.encode(pilots[msg.sender].cargo)) == keccak256(abi.encode(""))  );
        pilots[msg.sender].onChain = false;
        pilots[msg.sender].cargo = _cargo;
        recordDeparture(msg.sender, destinationChainSelector);

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: abi.encode(pilots[msg.sender]),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 700_000, strict: false})),
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

    function recordDeparture(address _pilot, uint _destination) internal {
        if (block.timestamp > epochTime + 1800) {
            epochTime = block.timestamp;
            currentEpoch += 1;
        }
        Departure memory newDeparture;
        newDeparture.pilot = _pilot;
        newDeparture.destinationSelector = _destination;
        newDeparture.departureTime = block.timestamp;
        epochs[currentEpoch].push(newDeparture);
    }


     function _ccipReceive(
        Client.Any2EVMMessage memory message
    ) internal override 
        onlyWhitelistedSourceChain(message.sourceChainSelector) 
        onlyWhitelistedSenders(abi.decode(message.sender, (address)))
    {
        Pilot memory arrivingPilot = abi.decode(message.data, (Pilot));
        arrivingPilot.onChain = true;
        arrivingPilot.coinBalance += 100;
        pilots[arrivingPilot.id] = arrivingPilot;
        lastArrived[arrivingPilot.id] = block.timestamp;
    }


    function pilotInfo(address _id) public view returns (Pilot memory) {
        return pilots[_id];
    }


    //   CARGO   //


    mapping (address => address) public claimantsAgainst;
    mapping (address => uint) public claimantRewards;

    function makeClaim(address _pilot) public {
        //an incoming ship can only have 1 claim against it
        require(claimantsAgainst[_pilot] == address(0x0));
        
        // checks that the claimant's deposit balance is valid.
        // turned off for demonstration purposes

        //require(pilots[msg.sender].onChain == true);
        //require(pilots[msg.sender].coinBalance >= 100);
        //pilots[msg.sender].coinBalance -= 100;

        claimantsAgainst[_pilot] = msg.sender;
    }

    function declareCargo(string calldata amount1, string calldata amount2, string calldata amount3, string calldata salt) public {
        //prepare for hashing
        string memory combined = amount1;
        combined = string.concat(combined, amount2);
        combined = string.concat(combined, amount3);
        combined = string.concat(combined, salt);
        // validate manifest contents
        require(keccak256(pilots[msg.sender].cargo) == keccak256(  abi.encode(sha256(abi.encode(combined)))   ));
        // validate cargo size
        uint converted_amount1 = strToUint(amount1);
        uint converted_amount2 = strToUint(amount2);
        uint converted_amount3 = strToUint(amount3);
        require(converted_amount1 + converted_amount2 + converted_amount3 <= pilots[msg.sender].holdSize);
        //validate cargo cost
        uint cost = (5 * converted_amount2) + (10 * converted_amount3);
        require(cost <= pilots[msg.sender].coinBalance);
        pilots[msg.sender].coinBalance -= cost;
        //check if caught and distribute rewards
        bool caught;
        if (claimantsAgainst[msg.sender] != address(0x0)) {
            if (converted_amount3 > 0) {
                caught = true;
                claimantRewards[claimantsAgainst[msg.sender]] += (cost / 10) + 100;
            }
            else {
                pilots[msg.sender].coinBalance += 100;
            }
            claimantsAgainst[msg.sender] = address(0x0);
        }

        if (caught == false) {
            uint revenue = (converted_amount1 * 2) + (converted_amount2 * 12) + (converted_amount3 * 22);
            pilots[msg.sender].coinBalance += revenue;
        }
        
        pilots[msg.sender].cargo = "";

    }

    //credit: stackoverflow
    function strToUint(string memory _str) public pure returns(uint256 result) {
    
    for (uint256 i = 0; i < bytes(_str).length; i++) {
        if ((uint8(bytes(_str)[i]) - 48) < 0 || (uint8(bytes(_str)[i]) - 48) > 9) {
            return 0;
        }
        result += (uint8(bytes(_str)[i]) - 48) * 10**(bytes(_str).length - i - 1);
    }
    
    return result;
}


    function takeReward() public {
        require(pilots[msg.sender].onChain == true);
        pilots[msg.sender].coinBalance += claimantRewards[msg.sender];
        claimantRewards[msg.sender] = 0;
    }


     function getOutgoingPilots() public view returns (Departure[] memory) {
        return epochs[currentEpoch];
    }
    
    function getOutgoingPilots2() public view returns (Departure[] memory) {
        return epochs[currentEpoch - 1];
    }




    // ACCESS CONTROL // 

    // Mapping to keep track of whitelisted destination chains.
    mapping(uint64 => bool) public whitelistedDestinationChains;

    // Mapping to keep track of whitelisted source chains.
    mapping(uint64 => bool) public whitelistedSourceChains;

    // Mapping to keep track of whitelisted senders.
    mapping(address => bool) public whitelistedSenders;

  
    /// @dev Modifier that checks if the chain with the given destinationChainSelector is whitelisted.
    /// @param _destinationChainSelector The selector of the destination chain.
    modifier onlyWhitelistedDestinationChain(uint64 _destinationChainSelector) {
        if (!whitelistedDestinationChains[_destinationChainSelector])
            revert DestinationChainNotWhitelisted(_destinationChainSelector);
        _;
    }

    /// @dev Modifier that checks if the chain with the given sourceChainSelector is whitelisted.
    /// @param _sourceChainSelector The selector of the destination chain.
    modifier onlyWhitelistedSourceChain(uint64 _sourceChainSelector) {
        if (!whitelistedSourceChains[_sourceChainSelector])
            revert SourceChainNotWhitelisted(_sourceChainSelector);
        _;
    }

    /// @dev Modifier that checks if the chain with the given sourceChainSelector is whitelisted.
    /// @param _sender The address of the sender.
    modifier onlyWhitelistedSenders(address _sender) {
        if (!whitelistedSenders[_sender]) revert SenderNotWhitelisted(_sender);
        _;
    }

    /// @dev Whitelists a chain for transactions.
    /// @notice This function can only be called by the owner.
    /// @param _destinationChainSelector The selector of the destination chain to be whitelisted.
    function whitelistDestinationChain(
        uint64 _destinationChainSelector
    ) external onlyOwner {
        whitelistedDestinationChains[_destinationChainSelector] = true;
    }

    /// @dev Denylists a chain for transactions.
    /// @notice This function can only be called by the owner.
    /// @param _destinationChainSelector The selector of the destination chain to be denylisted.
    function denylistDestinationChain(
        uint64 _destinationChainSelector
    ) external onlyOwner {
        whitelistedDestinationChains[_destinationChainSelector] = false;
    }

    /// @dev Whitelists a chain for transactions.
    /// @notice This function can only be called by the owner.
    /// @param _sourceChainSelector The selector of the source chain to be whitelisted.
    function whitelistSourceChain(
        uint64 _sourceChainSelector
    ) external onlyOwner {
        whitelistedSourceChains[_sourceChainSelector] = true;
    }

    /// @dev Denylists a chain for transactions.
    /// @notice This function can only be called by the owner.
    /// @param _sourceChainSelector The selector of the source chain to be denylisted.
    function denylistSourceChain(
        uint64 _sourceChainSelector
    ) external onlyOwner {
        whitelistedSourceChains[_sourceChainSelector] = false;
    }

    /// @dev Whitelists a sender.
    /// @notice This function can only be called by the owner.
    /// @param _sender The address of the sender.
    function whitelistSender(address _sender) external onlyOwner {
        whitelistedSenders[_sender] = true;
    }

    /// @dev Denylists a sender.
    /// @notice This function can only be called by the owner.
    /// @param _sender The address of the sender.
    function denySender(address _sender) external onlyOwner {
        whitelistedSenders[_sender] = false;
    }

     // Custom errors to provide more descriptive revert messages.
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees); // Used to make sure contract has enough balance to cover the fees.
    error NothingToWithdraw(); // Used when trying to withdraw Ether but there's nothing to withdraw.
    error FailedToWithdrawEth(address owner, address target, uint256 value); // Used when the withdrawal of Ether fails.
    error DestinationChainNotWhitelisted(uint64 destinationChainSelector); // Used when the destination chain has not been whitelisted by the contract owner.
    error SourceChainNotWhitelisted(uint64 sourceChainSelector); // Used when the source chain has not been whitelisted by the contract owner.
    error SenderNotWhitelisted(address sender); // Used when the sender has not been whitelisted by the contract owner.

}
