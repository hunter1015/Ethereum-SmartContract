/**
*@dev 请注意，本合约实现了ERC20标准的基本token功能，未加入更严格的权限控制内容，请勿直接用于生产！
*在本合约中，实现了token初始化、转账、批准、蒸发几个基本功能，下个合约应用实践中会引入更严格的安全控制，同时还将增加众筹、增发、冻结等功能，提升合约应用多样性
*@author yyh  stubbornyang@qq.com
*/
pragma solidity ^0.4.24;
import "./ERC20 BASIC Interface.sol";
import "./SafeMath.sol";
contract YYHToken is ERC20BasicToken{
    string public name;
    string public symbol;
    uint8 public decimals = 8;  // decimals 1个token可被分割的最小代币单位。设置为8以为 1token=10**8份最小单位
    uint256 public totalSupply_;
    
    // 映射地址对应的余额
    mapping (address => uint256)  balances;
    // 存储地址和地址间授权的花费额度
    mapping (address => mapping (address => uint256)) internal allowed;
	
    // 通知transfer发生 event
    event Transfer(address indexed from, address indexed to, uint256 value);
    // 通知burn发生 event
    event Burn(address indexed from, uint256 value);
	//引入safemath库 减少上下溢出风险
	
	//如有必要可以增加对uint8、uint16等其余整形的safemath库（应对struct中的短整形操作）
    using SafeMath for uint256;


    /**
     * 基础的初始化构造，设置token供应总量，名称和标识符。尽管构建函数由合约构建者才能做一次性调用，但为安全起见还应加入
	 * owner检测内容来进一步增加安全控制。下个高级合约中将会实现
     */
    function YYHToken(uint256 initialSupply, string tokenName, string tokenSymbol) public {
        totalSupply_ = initialSupply * 10 ** uint256(decimals);  // 供应的份额，份额跟最小的代币单位有关，份额 = 币数 * 10 ** decimals。
        balances[msg.sender] = totalSupply_;                // 创建者拥有所有的代币
        name = tokenName;                                   // 代币名称
        symbol = tokenSymbol;                               // 代币符号
    }

    /**
    * @dev 现存系统中的所有token供应总量（请注意，会伴随burn交易而减少）
    */
    function totalSupply() public view returns (uint256) {
    return totalSupply_;
    }
    
    /**
    * @dev 向某地址转账，触发Transfer事件做日志保存（由于不涉及以太坊eth的消耗，所以无需带payable）
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    /**
    * @dev 获取某地址的token数量，请注意使用view减少gas消耗（实际上合约内部调用是不消耗gas）
    */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
  
    /**
    * @dev 从某个地址转账到另一个地址，请注意msg.sender的使用一定程度上保护了本函数不被随意滥用
    */
    function transferFrom(
    address _from,
    address _to,
    uint256 _value
    )
    public
    returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    /**
    * @dev 批准目标地址可以代替当前操作账户花费固定数量的token，请注意approve方法存在一个批准前后顺序被故意调换的风险，所以在批准前请务必将之前批准清零。这里没有实现
    */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    /**
    * @dev 查看A地址批准B地址花费的token数量
    */
    function allowance(
    address _owner,
    address _spender
    )
    public
    view
    returns (uint256)
    {
        return allowed[_owner][_spender];
    }
    
    /**
    * @dev 增加批准额度
    */
    function increaseApproval(
    address _spender,
    uint _addedValue
    )
    public
    returns (bool)
    {
        allowed[msg.sender][_spender] = (
          allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    /**
    * @dev 减少批准额度
    */
    function decreaseApproval(
    address _spender,
    uint _subtractedValue
    )
    public
    returns (bool)
    {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
          allowed[msg.sender][_spender] = 0;
        } else {
          allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    /**
    * @dev token主人可自我选择蒸发掉一些token，本方法为public。具体实现方法被设置为internal，减少滥用可能
    */
    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }
    /**
    * @dev 蒸发自我token的实现
    */
    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
}

