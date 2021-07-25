pragma solidity 0.5.16;

import "./storage.sol";

contract Permissions_Proxy is Multi_Sig_Storage {

  address currentAddress;

    //Constructor to set current address of our functional contract so it knows where to foward function calls
  constructor(address _currentAddress) public {
    currentAddress = _currentAddress;
  }

    //Function that allows us to change the fowarding address of our proxy contract for when we launch a new upgraded version of our functional contract
  function upgrade(address _newAddress) public {
    currentAddress = _newAddress;
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
