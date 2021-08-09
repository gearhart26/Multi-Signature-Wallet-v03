pragma solidity 0.5.16;

import "./multiSigStorage_v03.sol";

contract Multi_Sig_Proxy is Multi_Sig_Storage {

  address currentAddress;

    //Function that allows us to change the fowarding address of our proxy contract for when we launch a new upgraded version of our functional contract
  function upgrade(address _newAddress) public {
    currentAddress = _newAddress;
  }

     //Variable to hold contract creator and number of required votes
    address [] private owners;
    uint votesNeeded;
    
        //Constructor to set contract owners, number of required votes, and current address of our upgradable functional contract so it knows where to foward function calls
    constructor(address[] memory _owners, uint _votesNeeded, address _currentAddress) public {
        require(_owners.length >= _votesNeeded, "Not enough _owners for selected number of _votesNeeded");
        require(_votesNeeded >= 1, "Number of _votesNeeded cannot be 0");
        currentAddress = _currentAddress;
        owners = _owners;
        votesNeeded = _votesNeeded;
    }
        
        //Modifier to set owner permissions
    modifier onlyOwners(){
       bool owner = false;
            //Iterating through owners list and checking each against msg.sender.
            //If msg.sender is in owners list then owner variable set to true and function is executed after require
       for (uint i=0; i<owners.length; i++){
           if (owners[i] == msg.sender){
               owner = true;
           }
       }
       require(owner == true);
        _;
    }
    
    //FALLBACK FUNCTION
    //Is triggered when a function is called that does not exist in proxy contract
    //This is a function that will reroute any function calls that do not match any of the function names in our proxy contract
    //This allows us to call functions that we might add in future versions of our upgradable functional contract
    //This prevents us from having to destroy and relaunch our proxy contract just to add functionality
  function () payable external {
    address implementation = currentAddress;
    require(currentAddress != address(0));
    bytes memory data = msg.data;

      //DELEGATECALL EVERY FUNCTION CALL FROM THIS CONTRACT TO AN EXTERNAL CONTRACT
    assembly {
        //NEED to use deligatecall() here because it calls an EXTERNAL FUNCTION using the CURRENT CONTRACT STATE
        //This allows the data to be stored on our proxy contract while we replace and update our functional contract
      let result := delegatecall(gas, implementation, add(data, 0x20), mload(data), 0, 0)
      let size := returndatasize
      let ptr := mload(0x40)
      returndatacopy(ptr, 0, size)
      switch result
      case 0 {revert(ptr, size)}
      default {return(ptr, size)}
    }
  }
}
