pragma solidity 0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    function add(Role storage role, address account) internal {
        require(!has(role, account));
        role.bearer[account] = true;
    }

    function remove(Role storage role, address account) internal {
        require(has(role, account));
        role.bearer[account] = false;
    }

    function has(Role storage role, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0));
        return role.bearer[account];
    }
}

contract ApproverRole {
    using Roles for Roles.Role;

    event ApproverAdded(address indexed account);
    event ApproverRemoved(address indexed account);

    Roles.Role private _approvers;

    address firstSignAddress;
    address secondSignAddress;

    mapping(address => bool) signed; // Signed flag

    constructor() internal {
        _addApprover(msg.sender);

        firstSignAddress = 0xfA198959854514d80EaDec68533F289f93AB9cc6; // You should change this address to your first sign address
        secondSignAddress = 0x4d7AB40b8601af760927624200BC5bcD2837BB41; // You should change this address to your second sign address
    }

    modifier onlyApprover() {
        require(isApprover(msg.sender));
        _;
    }

    function sign() external {
        require(
            msg.sender == firstSignAddress || msg.sender == secondSignAddress
        );
        require(!signed[msg.sender]);
        signed[msg.sender] = true;
    }

    function isApprover(address account) public view returns (bool) {
        return _approvers.has(account);
    }

    function addApprover(address account) external onlyApprover {
        require(signed[firstSignAddress] && signed[secondSignAddress]);
        _addApprover(account);

        signed[firstSignAddress] = false;
        signed[secondSignAddress] = false;
    }

    function removeApprover(address account) external onlyApprover {
        require(signed[firstSignAddress] && signed[secondSignAddress]);
        _removeApprover(account);

        signed[firstSignAddress] = false;
        signed[secondSignAddress] = false;
    }

    function renounceApprover() external {
        require(signed[firstSignAddress] && signed[secondSignAddress]);
        _removeApprover(msg.sender);

        signed[firstSignAddress] = false;
        signed[secondSignAddress] = false;
    }

    function _addApprover(address account) internal {
        _approvers.add(account);
        emit ApproverAdded(account);
    }

    function _removeApprover(address account) internal {
        _approvers.remove(account);
        emit ApproverRemoved(account);
    }
}



abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

  
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

library SafeMath {
  
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "SafeERC20: decreased allowance below zero"
            );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata =
            address(token).functionCall(
                data,
                "SafeERC20: low-level call failed"
            );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


contract PlayPadIdoFactory is Ownable, ReentrancyGuard {
    
    using SafeERC20 for IERC20;
    
    address[] public newIdo;
    event NewIdoCreated(
        address IdoAddress,
        IERC20 _busdAddress,
        IERC20 _saleToken,
        bool _contractStatus,
        uint256 _hardcapUsd,
        uint256 _totalSellAmountToken,
        uint256 _maxInvestorCount,
        uint256 _maxBuyValue,
        uint256 _minBuyValue,
        uint256 _startTime,
        uint256 _endTime
    );
    
       
    
       // creates new IDO contract following datas as below
       function createIDO(
        IERC20 _busdAddress,
        IERC20 _saleToken,
        bool _contractStatus,
        uint256 _hardcapUsd,
        uint256 _totalSellAmountToken,
        uint256 _maxInvestorCount,
        uint256 _maxBuyValue,
        uint256 _minBuyValue,
        uint256 _startTime,
        uint256 _endTime
    ) external nonReentrant onlyOwner{
         PlayPadIdoContract newIdoContract = new PlayPadIdoContract(
            _busdAddress,
            _saleToken,
            _contractStatus,
            _hardcapUsd,
            _totalSellAmountToken,
            _maxInvestorCount,
            _maxBuyValue,
            _minBuyValue,
            _startTime,
            _endTime
        );
        newIdoContract.transferOwnership(msg.sender);
        newIdo.push(address(newIdoContract)); // Adding All IDOs
        emit NewIdoCreated(address(newIdoContract), _busdAddress, _saleToken, _contractStatus, _hardcapUsd, _totalSellAmountToken, _maxInvestorCount, _maxBuyValue, _minBuyValue, _startTime, _endTime);
    }
    

    function getIdos() public view returns (address[] memory) {
        return newIdo;
    }
}





contract PlayPadIdoContract is ReentrancyGuard, Ownable {
   
    //Deployed by Main Contract
    PlayPadIdoFactory deployerContract;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public immutable busdToken; //Stable coin token contract address
    IERC20 public saleToken; //Sale token contract address
    uint256 public immutable hardcapUsd; //hardcap value as usd 
    uint256 public immutable totalSellAmountToken; //total amount to be sold
    uint256 public maxBuyValue; //max buying value per investor
    uint256 public minBuyValue; //min buying value per investor
    bool public contractStatus; //Contract running status
    uint256 public immutable startTime; //IDO participation start time
    uint256 public immutable endTime; //IDO participation end time
    uint256 public totalSoldAmountToken; //total sold amount as token
    uint256 public totalSoldAmountUsd; // total sold amount as usd
    uint256 public lockTime; //unlock date to get claim 
    address[] public whitelistedAddresses; //whitelisted address as array
    uint256[] public claimRoundsDate; //all claim rounds
    uint256 public totalClaimPercent;
    
    
   //whitelisted user data per user
    struct whitelistedInvestorData {
        uint256 totalBuyingAmountUsd;
        uint256 totalBuyingAmountToken;
        uint claimRound;
        bool isWhitelisted;
        uint256 lastClaimDate;
        uint256 claimedValue;
        address investorAddress;
        uint256 totalVesting;
        bool iWillBuy;
    }
    //claim round periods
    struct roundDatas {
        uint256 roundStartDate;
        uint256 roundPercent;
    }
    //mappings to reach relevant information
    mapping(address => whitelistedInvestorData) public _investorData;
    mapping(uint256 => roundDatas) public _roundDatas;

    
    
   
    constructor(
        IERC20 _busdAddress,
        IERC20 _saleToken,
        bool _contractStatus,
        uint256 _hardcapUsd,
        uint256 _totalSellAmountToken,
        uint256 _maxInvestorCount,
        uint256 _maxBuyValue,
        uint256 _minBuyValue,
        uint256 _startTime,
        uint256 _endTime
    ) public {
        require(
            _startTime < _endTime,
            "start block must be less than finish block"
        );
        require(
            _endTime > block.timestamp,
            "finish block must be more than current block"
        );
        busdToken = _busdAddress;
        saleToken = _saleToken;
        contractStatus = _contractStatus;
        hardcapUsd = _hardcapUsd;
        totalSellAmountToken = _totalSellAmountToken;
        maxBuyValue = _maxBuyValue;
        minBuyValue= _minBuyValue;
        startTime = _startTime;
        endTime = _endTime;
    }
      
    event NewBuying(address indexed investorAddress, uint256 amount, uint256 timestamp);
    
    //modifier to change contract status
    modifier mustNotPaused() {
        require(!contractStatus, "Paused!");
        _;
    }
    
    // function to change status of contract
    function changePause(bool _contractStatus) public onlyOwner nonReentrant{
        contractStatus = _contractStatus;
    }
    
     function changeSaleTokenAddress(IERC20 _contractAddress) external onlyOwner nonReentrant {
        saleToken = _contractAddress;
    } 
    
    //return all whitelisted addresses as array
    function getWhitelistedAddresses() public view returns(address[] memory){
        return whitelistedAddresses;
    }
    
    //calculate token amount according to deposit amount
    function calculateTokenAmount(uint256 amount) public view returns (uint256) {
       return (totalSellAmountToken.mul(amount)).div(hardcapUsd);
    }
    
    function returnUserInfo(address _addresss) public view returns (uint256, uint256, uint, bool, uint256, uint256, address, uint256, bool){
        whitelistedInvestorData storage investor = _investorData[msg.sender];
        return (investor.totalBuyingAmountUsd, investor.totalBuyingAmountToken, investor.claimRound, investor.isWhitelisted, investor.lastClaimDate, investor.claimedValue, investor.investorAddress, investor.totalVesting, investor.iWillBuy);
    }
    
      
    
    //buys token if passing controls
    function buyToken(uint256 busdAmount) external nonReentrant mustNotPaused {
        require(block.timestamp >= startTime);
        require(block.timestamp <= endTime);
        whitelistedInvestorData storage investor = _investorData[msg.sender];
        require(investor.isWhitelisted);
        require(busdAmount >= minBuyValue);
        require(maxBuyValue >= investor.totalBuyingAmountUsd.add(busdAmount));
        require(busdToken.transferFrom(msg.sender, address(this), busdAmount));
        uint256 totalTokenAmount = calculateTokenAmount(busdAmount);
        investor.totalBuyingAmountUsd = investor.totalBuyingAmountUsd.add(busdAmount);
        investor.totalBuyingAmountToken = investor.totalBuyingAmountToken.add(totalTokenAmount);
        totalSoldAmountToken = totalSoldAmountToken.add(totalTokenAmount);
        totalSoldAmountUsd = totalSoldAmountUsd.add(busdAmount);
        emit NewBuying(msg.sender, busdAmount, block.timestamp);
    }
    
    //emergency withdraw function in worst cases
    function emergencyWithdrawAllBusd() external nonReentrant onlyOwner {
        require(busdToken.transferFrom(address(this), msg.sender, busdToken.balanceOf(address(this))));
    }
    //change lock time to prevent missing values
    function changeLockTime(uint256 _lockTime) external nonReentrant onlyOwner {
        lockTime = _lockTime;
    }
    //emergency withdraw for tokens in worst cases
     function withdrawTokens() external nonReentrant onlyOwner {
        require(saleToken.transfer(msg.sender, saleToken.balanceOf(address(this))));
    }
    
    // Change iWillBuy
    function iWillBuy(bool _value) external nonReentrant {
         whitelistedInvestorData storage investor = _investorData[msg.sender];
         investor.iWillBuy = _value;
    }
    
    //claim tokens according to claim periods 
     function claimTokens() external nonReentrant {
        require(block.timestamp >= lockTime, "bad lock time");
        whitelistedInvestorData storage investor = _investorData[msg.sender];
        require(investor.isWhitelisted, "you are not whitelisted");
        uint256 investorRoundNumber = investor.claimRound;
        roundDatas storage roundDetail = _roundDatas[investorRoundNumber];
        require(roundDetail.roundStartDate != 0, "Claim rounds are not available yet.");
        require(block.timestamp >= roundDetail.roundStartDate ,"round didn't start yet");
        require(investor.totalBuyingAmountToken >= investor.claimedValue.add(investor.totalBuyingAmountToken.mul(roundDetail.roundPercent).div(100)) ,"already you got all your tokens");
        saleToken.safeTransferFrom(address(this), msg.sender, investor.totalBuyingAmountToken.mul(roundDetail.roundPercent).div(100));
        investor.claimRound = investor.claimRound.add(1);
        investor.lastClaimDate = block.timestamp;
        investor.claimedValue = investor.claimedValue.add(investor.totalBuyingAmountToken.mul(roundDetail.roundPercent).div(100));
    }
     
    //add new claim round
    function addNewClaimRound(uint256 _roundNumber, uint256 _roundStartDate, uint256 _claimPercent) external nonReentrant onlyOwner {
    require(_claimPercent.add(totalClaimPercent) <= 100);
    require(_claimPercent > 0);
    totalClaimPercent = totalClaimPercent.add(_claimPercent);
    roundDatas storage roundDetail = _roundDatas[_roundNumber];
    roundDetail.roundStartDate = _roundStartDate;
    roundDetail.roundPercent = _claimPercent;
    claimRoundsDate.push(_roundStartDate);
    }
    
   function changeMaxMinBuyLimit(uint256 _maxBuyLimit, uint256 _minBuyLimit) external onlyOwner nonReentrant {
       maxBuyValue = _maxBuyLimit;
       minBuyValue = _minBuyLimit;
   }
   
   function changeDataOfUser(address _user, uint256 _buyingLimits, bool _whitelistStatus) external onlyOwner nonReentrant {
             whitelistedInvestorData storage investor = _investorData[_user];
             investor.totalVesting = _buyingLimits;
             investor.isWhitelisted = _whitelistStatus;
   }
   
    /*
    Define users vestings and addresses according to datas taken from javascript. function at javascript controls buy limits and other details
    after that it multiples stake duration time of users with their deposited amounts and converts them to percentage based result and calculate their buying amounts according to tokenomics of IDO
    */
    
    function addUsersToWhitelist(address[] memory _whitelistedAddresses, uint256[] memory _buyingLimits) external onlyOwner nonReentrant{ 
        for(uint256 i = 0;  i < _whitelistedAddresses.length; i++){
             whitelistedInvestorData storage investor = _investorData[_whitelistedAddresses[i]];
             require(investor.isWhitelisted != true);
             investor.totalVesting = _buyingLimits[i];
             investor.isWhitelisted = true;
             whitelistedAddresses.push(_whitelistedAddresses[i]);
        }
        
    }
       
    }
