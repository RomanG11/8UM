pragma solidity ^0.4.20;

library SafeMath { //standart library for uint
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0){
        return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

//standart contract to identify owner
contract Ownable {

  address public owner;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function Ownable() public {
    owner = msg.sender;
  }
}


contract ContractReceiver {
  function tokenFallback(address _from, uint _value, bytes _data) public;
}


contract OctaneumToken is Ownable {
    
  using SafeMath for uint;
    
  event Transfer(address indexed _from, address indexed _to, uint256 _value, bytes _data);

  mapping(address => uint) balances;
  
  string public name    = "Octaneum";
  string public symbol  = "UM8";
  uint8 public decimals = 0;
  uint256 public totalSupply = 100000000;
  
  function OctaneumToken() public
  {
    balances[msg.sender] = totalSupply;

    owners[0x1] = true;
    owners[0x2] = true;
    owners[0x3] = true;
    owners[0x4] = true;
    owners[0x5] = true;
  }
  
  // Function to access name of token .
  function name() public view returns (string _name) {
    return name;
  }
  // Function to access symbol of token .
  function symbol() public view returns (string _symbol) {
    return symbol;
  }
  // Function to access decimals of token .
  function decimals() public view returns (uint8 _decimals) {
    return decimals;
  }
  // Function to access total supply of tokens .
  function totalSupply() public view returns (uint256 _totalSupply) {
    return totalSupply;
  }

  mapping (address => bool) owners;
  
  struct Transaction {
    address addr;
    uint amount;
    bool confirm1;
    bool confirm2;
    bool confirm3;
    bool sended;
  }

  Transaction[] public transactions;

  function addNewTransaction (address _address, uint _value) public onlyOwner{
    transactions.push(Transaction(_address,_value,false,false,false,false));
  }

  function approveTransaction (uint _index) public returns(bool) {
    require (owners[msg.sender]);
    require (!transactions[_index].sended);
    
    Transaction memory buffer = transactions[_index];

    if(!buffer.confirm1){
      transactions[_index].confirm1 = true;

      return true;
    }
    if(!buffer.confirm2){
      transactions[_index].confirm2 = true;
      return true;
    }
    if(!buffer.confirm3){
      transactions[_index].confirm3 = true;

      balances[owner] = balances[owner].sub(transactions[_index].amount);
      balances[transactions[_index].addr] = balances[transactions[_index].addr].add(transactions[_index].amount);

      bytes memory empty;
      emit Transfer(owner, transactions[_index].addr, transactions[_index].amount, empty);

      transactions[_index].sended = true;
    }
    return true;
  }

  bool public locked = true;
  function setLockTransfer (bool _bool) public onlyOwner {
    locked = _bool;
  }

  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {
    require(!locked || _to == owner);
    require(msg.sender != owner);    

    if(isContract(_to)) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].sub(_value);
        assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
  }
  
  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
    require(!locked || _to == owner); 
    require(msg.sender != owner);  

    if(isContract(_to)) {
        return transferToContract(_to, _value, _data);
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
  }
  
  // Standard function transfer similar to ERC20 transfer with no _data .
  // Added due to backwards compatibility reasons .
  function transfer(address _to, uint _value) public returns (bool success) {
    require(!locked || _to == owner);
    require(msg.sender != owner);  
    
    //standard function transfer similar to ERC20 transfer with no _data
    //added due to backwards compatibility reasons
    bytes memory empty;
    if(isContract(_to)) {
        return transferToContract(_to, _value, empty);
    }
    else {
        return transferToAddress(_to, _value, empty);
    }
  }

  //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
  function isContract(address _addr) private view returns (bool is_contract) {
    uint length;
    assembly {
      //retrieve the size of the code on target address, this needs assembly
      length := extcodesize(_addr)
    }
    return (length>0);
  }

  //function that is called when transaction target is an address
  function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value, _data);
    return true;
  }
  
  //function that is called when transaction target is a contract
  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    ContractReceiver receiver = ContractReceiver(_to);
    receiver.tokenFallback(msg.sender, _value, _data);
    emit Transfer(msg.sender, _to, _value, _data);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }
}