pragma solidity ^0.5.3;

    /**
     * Storage Contract built to 
     * stop collision.
     * Holds ERC20 data and balances.
     */

contract moneyVelocityStorage {
    
        /**
     * Boilerplate variables - 
     * used from ERC20 standard
     */
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint)) allowed;
    address public owner;
    
        /**
     * Captures addresses in an array
     * used to to zero out balances after
     * contract upgrade.
     */
    
    address[] addressList;
    address[] approverAddressList;
    address[ ]approveeAddressList;

        /**
     * Logic contract address 
     * to be proxied
     */
    address public mVImplementation;
    
            /**
     * Boilerplate events - 
     * used from ERC20 standard
     */
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
            /**
     * constructor used to set 
     * contracts state
     */
    
    constructor() public {
        name = "Money Velocity Token";
        symbol = "MVT";
        decimals = 2;
        totalSupply = 100000000;
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
    }
}


        /**
     * Implementation / logic contract
     * this contract stores the Boilerplate
     * ERC20 standard methods.
     */

contract moneyVelocityImplementation1 is moneyVelocityStorage{
    
        /**
     * Push each address involved
     * in the transfer to an array 
     * inorder to keep track of the
     * address that will need to be reset 
     * during the monthly contract update
     */
    
    function transfer(address _to, uint _tokens) 
        public 
        returns (bool success) {
        balances[msg.sender] = balances[msg.sender] - _tokens;
        balances[_to] = balances[_to] + _tokens;
        addressList.push(_to);
        emit Transfer(msg.sender, _to, _tokens);
        return true;
    }
    
        /**
     * Push each address involved
     * in the approve to an array 
     * inorder to keep track of the
     * address that will need to be reset 
     * during the monthly contract update
     */

    function approve(address _spender, uint _tokens) 
        public 
        returns (bool success) {
        allowed[msg.sender][_spender] = _tokens;
        approverAddressList.push(msg.sender);
        approveeAddressList.push(_spender);
        emit Approval(msg.sender, _spender, _tokens);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _tokens) 
        public 
        returns (bool success) {
            balances[_from] = balances[_from] - _tokens;
            allowed[_from][msg.sender] = allowed[_from][msg.sender] - _tokens;
            balances[_to] = balances[_to] + _tokens;
            emit Transfer(_from, _to, _tokens);
            return true;
    }
    
    function allowance(address _tokenOwner, address _spender) 
        public  
        view 
        returns (uint remaining) {
        return allowed[_tokenOwner][_spender];
    }
     
}

    /**
     * Proxy contract is the medium
     * which the users will interact
     * with the logic contract. The proxy 
     * contract also holds the state of each 
     * variable and resets the varibles during 
     * each contract update.
     * 
     * Contract updates will occur monthly - 
     * Updates occur onces the upgradeTo function
     * is called and a new contract address is introduced.
     */


contract Proxy is moneyVelocityStorage {
    
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }
    
    /**
     Upgrades the implementation address
     _newImplementation address of the new implementation
     */
    function upgradeTo(address _newImplementation) 
        external onlyOwner 
    {
        require(mVImplementation != _newImplementation);
        _setImplementation(_newImplementation);
        _resetBalances();
        _resetApprovedBalances();
        totalSupply = 100000000;
        balances[msg.sender] = totalSupply;
        
    }
    
    /**
     * Fallback function allowing to perform a delegatecall 
     * to the given implementation. This function will return 
     * whatever the implementation call returns
     * 
     */
    function () 
        payable 
        external {
            address impl = mVImplementation;
            require(impl != address(0));
            assembly {
                let ptr := mload(0x40)
                calldatacopy(ptr, 0, calldatasize)
                let result := delegatecall(gas, impl, ptr, calldatasize, 0, 0)
                let size := returndatasize
                returndatacopy(ptr, 0, size)
                
                switch result
                case 0 { revert(ptr, size) }
                default { return(ptr, size) }
            }
    }
    
    /**
     * Sets the address of the current implementation
     * _newImp address of the new implementation
     */
    function _setImplementation(address _newImp) 
        internal {
        mVImplementation = _newImp;
    }
    
    /**
     * _resetBalances and _resetApprovedBalances
     * resets the market participants balances to zero
     * once an update is approved by the upgradeTo
     * function.
     */
    
    function _resetBalances() 
        internal {
        for(uint i = 0; i<addressList.length; i++){
            balances[addressList[i]] = 0;
        }
    }
    
    function _resetApprovedBalances() 
        internal {
        for(uint i = 0; i<approveeAddressList.length; i++){
            allowed[approverAddressList[i]][approveeAddressList[i]] = 0;
        }
    }
    
}
