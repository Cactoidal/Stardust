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
        uint shipSize;
        uint cargoType;
        uint cargoAmount;
        uint coinBalance;
        uint job;
        bool antimatterModule;
        bool recycler;
        bool dustCatcher;
        bool onChain;
    }

    mapping(address => Pilot) public pilots;
    mapping(address => uint) public lastDeparted;
    mapping(address => uint) public lastArrived;

    //  PILOT  //

    // Erase this function when deploying away from origin chain
    function createPilot(string calldata _name) public {
        require(pilots[msg.sender].level == 0);
        Pilot memory newPilot;
        newPilot.name = _name;
        newPilot.id = msg.sender;
        newPilot.level = 1;
        newPilot.shipSize = 100;
        newPilot.onChain = true;
        pilots[msg.sender] = newPilot;
    }

function _ccipSend(
        uint64 destinationChainSelector,
        address receiver,
        PayFeesIn payFeesIn
    ) public onlyWhitelistedDestinationChain(destinationChainSelector) {

        require(pilots[msg.sender].onChain == true);
        pilots[msg.sender].onChain = false;
        lastDeparted[msg.sender] = block.timestamp;

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
