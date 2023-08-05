// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "IStarCoin.sol";
import "IPilot.sol";
import "Trigonometry.sol";


//Need to implement CCIP and instructions
//For convenience, may need to use native gas for payment

//this contract should be able to act as receiver/sender

contract Stardust {
    using Trigonometry for int;

    address PILOT;
    address STARCOIN;
    address WEATHER;

    constructor (address _pilotNFT, address _starcoin, address _weather) {
        PILOT = _pilotNFT;
        STARCOIN = _starcoin;
        WEATHER = _weather;
    }

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
        uint16 level;
        uint256 id;
        address employer;
        uint shipSize;
        uint32[4] mods;
        uint[2][] cargo;
        uint256 coinBalance;
        uint32 job;
        uint16[] instructions;
        bool onChain;
    }

    mapping(address => bool) depotDeployed;
    mapping(uint => Pilot) pilotRecord;
    mapping(address => uint) lastFreeGas;


    //  PILOT  //

    //todo: check msg.value is working as intended
    function deployDepot(string calldata _name) public payable {
        require(depotDeployed[msg.sender] == false);
        require(msg.sender.balance >= 3*1e16);
        require(msg.value == 3*1e16);
        depotDeployed[msg.sender] = true;
        createPilot(msg.sender, _name);
    }


    function createPilot(address _employer, string calldata _name) internal {
        Pilot memory newPilot;
        newPilot.name = _name;
        newPilot.employer = _employer;
        newPilot.level = 1;
        newPilot.shipSize = SHIP1_SIZE;
        newPilot.id = IPilot(PILOT).getId();
        newPilot.onChain = true;
        IPilot(PILOT).mint(_employer);
    }

    //CCIP Send
    function pilotSend(address _employer, uint _id, uint[2][] calldata _cargo, uint32 _job, uint16[] memory _instructions) public {
        //May need to rethink the depot requirement a little
        require(depotDeployed[msg.sender] == true);
        require(IERC721(PILOT).ownerOf(_id) == msg.sender);

        takeShipment(_id, _cargo, _job);
        pilotRecord[_id].instructions = _instructions;
        
        IERC721(PILOT).safeTransferFrom(_employer, address(this), _id, "");
        pilotRecord[_id].onChain = false;
        //CCIPMessage
    }

    //CCIP Receive
    function pilotReceive(Pilot calldata _pilot) external {
        //Requires CCIP is msg.sender

        // Check if pilot exists on-chain yet, mint if not
        if (pilotRecord[_pilot.id].level == 0) {
            IPilot(PILOT).instantiate(address(this), _pilot.id);
            }

        // Depot must exist on sender chain, therefore it exists on recipient chain
        depotDeployed[_pilot.employer] = true;

        executeInstructions(_pilot);
        
        IERC721(PILOT).safeTransferFrom(address(this), _pilot.employer, _pilot.id, "");
        
        //todo: check that call is working as intended
        if (_pilot.employer.balance <= 1*1e16) {
            if (address(this).balance >= 1*1e17) {
                if (lastFreeGas[_pilot.employer] < block.timestamp) {
                    lastFreeGas[_pilot.employer] = block.timestamp + 86400;
                    (bool sent, bytes memory data) = _pilot.employer.call{value: 1*1e16}("");
                    require(sent, "Failed to send Ether");
                }
            }
        }
    }


    // Sells all cargo for market price immediately upon landing 
    // "instructions" currently have no function
    function executeInstructions(Pilot calldata _pilot) internal {
        uint[2][] memory emptyHold;
        uint16[] memory noInstructions;
        uint sellPrice = 1;

        pilotRecord[_pilot.id] = _pilot;
        pilotRecord[_pilot.id].onChain = true;

        for (uint i; i < _pilot.cargo.length; i++) {
            sellPrice += getCargoPrice(_pilot.cargo[i][0], _pilot.cargo[i][1]);
        }
        if (_pilot.job == 1) {
            sellPrice /= 10;
        }
        pilotRecord[_pilot.id].coinBalance += sellPrice;
        pilotRecord[_pilot.id].cargo = emptyHold;
        pilotRecord[_pilot.id].job = 0;
        pilotRecord[_pilot.id].instructions = noInstructions;
        
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



    //  UPGRADES // 

    function upgradeShip(uint _id, uint16 ship) public {
        require (pilotRecord[_id].employer == msg.sender);
        require (pilotRecord[_id].onChain == true);
        require (ship >= 0 && ship <= 3);
        uint cost;
        uint holdSize = SHIP1_SIZE;
        if (ship == 1) {
            require (IERC20(STARCOIN).balanceOf(msg.sender) >= 100);
            cost = 100;
            holdSize = SHIP2_SIZE;
        }
        else if (ship == 2) {
            require (IERC20(STARCOIN).balanceOf(msg.sender) >= 500);
            cost = 500;
            holdSize = SHIP3_SIZE;
        }
        else if (ship == 3) {
            require (IERC20(STARCOIN).balanceOf(msg.sender) >= 2500);
            cost = 2500;
            holdSize = SHIP4_SIZE;
        }
        cost *= 1e18;
        require(pilotRecord[_id].coinBalance + IERC20(STARCOIN).balanceOf(msg.sender) >= cost);

        pilotRecord[_id].shipSize = holdSize;

        if (cost >= pilotRecord[_id].coinBalance) {
            cost -= pilotRecord[_id].coinBalance;
            pilotRecord[_id].coinBalance = 0;
            IERC20(STARCOIN).transferFrom(msg.sender, address(this), cost);
        }
        else {
            pilotRecord[_id].coinBalance -= cost;
        }
    }

    function equipMod(uint _id, uint16 slot, uint32 mod) public {
        require (pilotRecord[_id].employer == msg.sender);
        require (pilotRecord[_id].onChain == true);
        require (slot >= 1 && slot <= 4);
        require (mod >= 1 && mod <= 4);
        uint cost;
        if (mod == 1) {
            require (IERC20(STARCOIN).balanceOf(msg.sender) >= 300);
            cost = 300;
        }
        else if (mod == 2) {
            require (IERC20(STARCOIN).balanceOf(msg.sender) >= 900);
            cost = 900;
        }
        else if (mod == 3) {
            require (IERC20(STARCOIN).balanceOf(msg.sender) >= 900);
            cost = 900;
        }
        else if (mod == 4) {
            require (IERC20(STARCOIN).balanceOf(msg.sender) >= 1800);
            cost = 1800;
        }
        cost *= 1e18;
        require(pilotRecord[_id].coinBalance + IERC20(STARCOIN).balanceOf(msg.sender) >= cost);
        pilotRecord[_id].mods[slot] = mod;

        if (cost >= pilotRecord[_id].coinBalance) {
            cost -= pilotRecord[_id].coinBalance;
            pilotRecord[_id].coinBalance = 0;
            IERC20(STARCOIN).transferFrom(msg.sender, address(this), cost);
        }
        else {
            pilotRecord[_id].coinBalance -= cost;
        }
    }
    

    // COMMODITY EXCHANGE //
    //Buy/sell prices variable based on chain and time

    function takeShipment(uint _id, uint[2][] memory _cargo, uint32 _job) internal {
        require(pilotRecord[_id].employer == msg.sender);
        require(_job > 0 && _job <= 2);
        uint totalSize;
        uint shippingCost;
        for (uint i = 0; i < _cargo.length; i++) {

            //check if ship is fitted to carry antimatter
            if (_cargo[i][0] == 5) {
                bool antimatterModule;
                for (uint j = 0; j < pilotRecord[_id].mods.length; j++) {
                    if (pilotRecord[_id].mods[j] == 4) {
                        antimatterModule = true;
                    }
                require(antimatterModule == true);
                }
            }

            totalSize += (calculateSize(_cargo[i][0], _cargo[i][1]));
            
            if (_job == 2) {
                shippingCost += getCargoPrice(_cargo[i][0], _cargo[i][1]);
            }
        }
        require(pilotRecord[_id].shipSize >= totalSize);
        require(pilotRecord[_id].coinBalance + IERC20(STARCOIN).balanceOf(msg.sender) >= shippingCost);

        pilotRecord[_id].cargo = _cargo;
        pilotRecord[_id].job = _job;

        if (shippingCost >= pilotRecord[_id].coinBalance) {
            shippingCost -= pilotRecord[_id].coinBalance;
            pilotRecord[_id].coinBalance = 0;
            IERC20(STARCOIN).transferFrom(msg.sender, address(this), shippingCost);
        }
        else {
            pilotRecord[_id].coinBalance -= shippingCost;
        }
    }

    function calculateSize(uint _cargoType, uint _amount) public pure returns (uint) {
        require(_cargoType > 0 && _cargoType <= 5);
        uint cargoSize;
        if (_cargoType == 1) {
            cargoSize = FOOD_SIZE;
        }
        else if (_cargoType == 2) {
            cargoSize = MEDICINE_SIZE;
        }
        else if (_cargoType == 3) {
            cargoSize = METAL_SIZE;
        }
        else if (_cargoType == 4) {
            cargoSize = TECH_SIZE;
        }
        else if (_cargoType == 5) {
            cargoSize = ANTIMATTER_SIZE;
        }
        return cargoSize * _amount;
    }

    
    function getCargoPrice(uint _cargoType, uint _amount) public view returns (uint) {
        require(_cargoType > 0 && _cargoType <= 5);
        int basePrice;

        if (_cargoType == 1) {
            basePrice = FOOD_PRICE;
        }
        else if (_cargoType == 2) {
            basePrice = MEDICINE_PRICE;
        }
        else if (_cargoType == 3) {
            basePrice = METAL_PRICE;
        }
        else if (_cargoType == 4) {
            basePrice = TECH_PRICE;
        }
        else if (_cargoType == 5) {
            basePrice = ANTIMATTER_PRICE;
        }

        basePrice *= 1e18;

        return _amount * uint(  basePrice + (Trigonometry.sin(block.number * 1e18) * 10)    );
    }


    // WEATHER AND HAZARDS (Global Events) //

    //Automation changes base prices every so often
    function setPrices(int[5] calldata prices) external {
        //may not be secure
        require(msg.sender == WEATHER);
        FOOD_PRICE = prices[0];
        MEDICINE_PRICE = prices[1];
        METAL_PRICE = prices[2];
        TECH_PRICE = prices[3];
        ANTIMATTER_PRICE = prices[4];
    }


    //Are these needed?
    receive() external payable {}
    fallback() external payable {}


}
