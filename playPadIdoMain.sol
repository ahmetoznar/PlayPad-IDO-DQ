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

contract MainPlayPadContract is Ownable, ApproverRole, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public immutable stakingToken; //staking token
    IERC20 public immutable rewardToken; // reward token contract address for investors
    uint256 public startBlock; // start block number to decide vestings and distrubute prizes 
    uint256 public lastRewardBlock; //last reward block to distrubute reward tokens.
    uint256 public immutable finishBlock; //Finish block number for staking deposits.
    uint256 public allStakedAmount; //total staked value as tokens.
    uint256 public allPaidReward; //total distrubuted tokens value.
    uint256 public allRewardDebt; //total pending reward value.
    uint256 public immutable poolTokenAmount; //total prize to be distrubuted for period.
    uint256 public immutable rewardPerBlock; //reward value per block.
    uint256 public accTokensPerShare; // Accumulated tokens per share.
    uint256 public participants; //Count of participants.
    bool public immutable isPenalty; //penalty status for each deposit.
    uint256 public immutable penaltyRate; //penaltyRate for pool.
    uint256 public immutable penaltyBlockLength; //penalty block duration as block number.
    address public immutable penaltyAddress; //Penalty address.
    uint256 public limitForPrize; // limit token count to get vesting from IDOs.
    address[] public newIdo; // All deployed IDO addresses.
    address[] public allInvestors; //return all investor

    // Info of each investor.
    struct UserInfo {
        uint256 amount; // How many tokens the user has staked.
        uint256 rewardDebt; // Reward debt
        uint256[] userPoolIds; // User Deposits
        bool stakeStatus; //User Stake Status.
        uint256 stakeStartDate; // first date of deposit of user above limit for vesting.
        bool onlyPrize; // Only prize, No vesting.
        address userAddress;
    }
    
    
    struct UserPoolInfo {
        uint256 blockNumber; //start block number of deposit..
        uint256 penaltyEndBlockNumber; // penalty end block number for deposit.
        uint256 amount; //amount of deposit.
        address owner; //deposited by
    }
    
    //mappings to reach datas of investors and pools.
    mapping(address => UserInfo) public userInfo;
    mapping(uint256 => UserPoolInfo) public userPoolInfo;
    mapping(uint256 => bool) public availablePools;
    mapping(address => bool) public isIdoDeployed;

    //live events for contract
    event FinishBlockUpdated(uint256 newFinishBlock);
    event PoolReplenished(uint256 amount);
    event TokensStaked(address indexed user, uint256 amount, uint256 reward);
    event StakeWithdrawn(address indexed user, uint256 amount, uint256 reward);
    event WithdrawAllPools(address indexed user, uint256 amount);
    event WithdrawPoolRemainder(address indexed user, uint256 amount);
    event NewIdoCreated(address indexed idoUser);
    event ChangePrizeLimit(uint256 amount);
    
    constructor(
        IERC20 _stakingToken,
        IERC20 _poolToken,
        uint256 _startBlock,
        uint256 _finishBlock,
        uint256 _poolTokenAmount,
        bool _isPenalty,
        uint256 _penaltyRate,
        address _penaltyAddress,
        uint256 _penaltyBlockLength,
        uint256 _limitForPrize
    ) public {
        stakingToken = _stakingToken;
        rewardToken = _poolToken;
        require(
            _startBlock < _finishBlock,
            "start block must be less than finish block"
        );
        require(
            _finishBlock > block.number,
            "finish block must be more than current block"
        );
        require(
            _finishBlock.sub(_penaltyBlockLength) < _finishBlock,
            "finish block must be more than penalty block"
        );
        require(
            _startBlock.add(_penaltyBlockLength) > _startBlock,
            "penalty block must be more than start block"
        );
        penaltyAddress = _penaltyAddress;
        isPenalty = _isPenalty;
        penaltyRate = _penaltyRate;
        penaltyBlockLength = _penaltyBlockLength;
        startBlock = _startBlock;
        lastRewardBlock = startBlock;
        finishBlock = _finishBlock;
        poolTokenAmount = _poolTokenAmount;
        rewardPerBlock = _poolTokenAmount.div(_finishBlock.sub(_startBlock));
        limitForPrize = _limitForPrize;
    }

    function getMultiplier(uint256 _from, uint256 _to)
        internal
        view
        returns (uint256)
    {
        if (_from >= _to) {
            return 0;
        }
        if (_to <= finishBlock) {
            return _to.sub(_from);
        } else if (_from >= finishBlock) {
            return 0;
        } else {
            return finishBlock.sub(_from);
        }
    }

    // View function to see pending Reward on frontend.
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 tempAccTokensPerShare = accTokensPerShare;
        if (block.number > lastRewardBlock && allStakedAmount != 0) {
            uint256 multiplier = getMultiplier(lastRewardBlock, block.number);
            uint256 reward = multiplier.mul(rewardPerBlock);
            tempAccTokensPerShare = accTokensPerShare.add(
                reward.mul(1e18).div(allStakedAmount)
            );
        }
        return
            user.amount.mul(tempAccTokensPerShare).div(1e18).sub(
                user.rewardDebt
            );
    }
  
    
    function getUserPoolInfo(uint256 _poolId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            address
        )
    {
        UserPoolInfo storage poolInfo = userPoolInfo[_poolId];
        return (
            poolInfo.blockNumber,
            poolInfo.penaltyEndBlockNumber,
            poolInfo.amount,
            poolInfo.owner
        );
    }
    //returns contract addresses of all deployed IDOs
     function getIdos() external view returns (address[] memory)  {
        return newIdo;
    }
    
    function getInvestors() external view returns (uint256[] memory, uint256[] memory, bool[] memory, address[] memory) {
     
     address[] memory _userAddress = new address[](allInvestors.length);
     uint256[] memory _amount = new uint256[](allInvestors.length);
     uint256[] memory _stakeStartDate = new uint256[](allInvestors.length);
     bool[] memory _onlyPrize = new bool[](allInvestors.length);
     
        for (uint256 i = 0; i < allInvestors.length; i++) {
            UserInfo storage userData = userInfo[allInvestors[i]];
            _userAddress[i] = userData.userAddress;
            _amount[i] = userData.amount;
            _stakeStartDate[i] = userData.stakeStartDate;
            _onlyPrize[i] = userData.onlyPrize;
        }
        
        return(_amount, _stakeStartDate, _onlyPrize, _userAddress);
  
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        if (block.number <= lastRewardBlock) {
            return;
        }
        if (allStakedAmount == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = getMultiplier(lastRewardBlock, block.number);
        uint256 reward = multiplier.mul(rewardPerBlock);
        accTokensPerShare = accTokensPerShare.add(
            reward.mul(1e18).div(allStakedAmount)
        );
        lastRewardBlock = block.number;
    }
    
    
      
    
    function changePrizeLimit(uint256 _amountToStake) external nonReentrant onlyApprover {
        limitForPrize = _amountToStake;
        emit ChangePrizeLimit(limitForPrize);
    }
    
     function getUserInfo(address _user)
        external
        view
        returns (
            uint256,
            uint256,
            uint256[] memory,
            bool,
            uint256,
            bool
        )
    {
        UserInfo storage user = userInfo[_user];
        return (user.amount, user.rewardDebt, user.userPoolIds, user.stakeStatus, user.stakeStartDate, user.onlyPrize);
    }

    
    //stake tokens with controls
    function stakeTokens(uint256 _amountToStake) external nonReentrant {
        updatePool();
        uint256 pending = 0;
        uint256 randomPoolId =
            uint256(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        now,
                        block.number,
                        _amountToStake
                    )
                )
            );
        require(!availablePools[randomPoolId], "Pool id already created");
        UserInfo storage user = userInfo[msg.sender];
        UserPoolInfo storage poolInfo = userPoolInfo[randomPoolId];
        if (user.amount > 0) {
            pending = transferPendingReward(user);
        } else if (_amountToStake > 0) {
            participants += 1;
        }

        if (_amountToStake > 0) {
            stakingToken.safeTransferFrom(
                msg.sender,
                address(this),
                _amountToStake
            );
            if(user.userAddress == address(0x0000000000000000000000000000000000000000)){
                allInvestors.push(msg.sender);
            }
            availablePools[randomPoolId] = true;
            poolInfo.blockNumber = block.number;
            poolInfo.amount = _amountToStake;
            poolInfo.owner = msg.sender;
            poolInfo.penaltyEndBlockNumber = block.number.add(
                penaltyBlockLength
            );
            
            if(user.amount.add(_amountToStake) > limitForPrize && user.stakeStartDate != 0){
                user.onlyPrize = false;
                user.stakeStartDate = block.timestamp;
            }else{
                user.onlyPrize = true;
            }
            user.stakeStatus = true;
            user.userAddress = msg.sender;
            user.userPoolIds.push(randomPoolId);
            user.amount = user.amount.add(_amountToStake);
            allStakedAmount = allStakedAmount.add(_amountToStake);
           
        }

        allRewardDebt = allRewardDebt.sub(user.rewardDebt);
        user.rewardDebt = user.amount.mul(accTokensPerShare).div(1e18);
        allRewardDebt = allRewardDebt.add(user.rewardDebt);
        emit TokensStaked(msg.sender, _amountToStake, pending);
    }

    // Leave the pool. Claim back your tokens.
    // Unclocks the staked + gained tokens and burns pool shares
    function withdrawStake(uint256 _amount, uint256 _poolId)
        external
        nonReentrant
    {
        UserInfo storage user = userInfo[msg.sender];
        UserPoolInfo storage poolInfo = userPoolInfo[_poolId];
        require(user.amount >= _amount, "withdraw: not good");
        require(poolInfo.amount >= _amount, "withdraw: not good");
        require(poolInfo.owner == msg.sender, "you are not owner");
        require(block.number > finishBlock, "date is not good");
        updatePool();
        uint256 pending = transferPendingReward(user);
        uint256 penaltyAmount = 0;
        
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            poolInfo.amount = poolInfo.amount.sub(_amount);
            
            if (isPenalty) {
                if (block.number < finishBlock) {
                    if (block.number <= poolInfo.penaltyEndBlockNumber) {
                        penaltyAmount = penaltyRate.mul(_amount).div(1e6);
                        stakingToken.safeTransferFrom(address(this), penaltyAddress, penaltyAmount);
                    }
                }
            }

            stakingToken.safeTransfer(msg.sender, _amount.sub(penaltyAmount));
            if (user.amount == 0) {
                participants -= 1;
                user.onlyPrize = true;
                user.stakeStartDate = 0;
            }
            
            if(user.amount > limitForPrize){
                user.onlyPrize = false;
            }else{
                user.onlyPrize = true;
                user.stakeStartDate = 0;
            }
            
        }
        
          
            
        allRewardDebt = allRewardDebt.sub(user.rewardDebt);
        user.rewardDebt = user.amount.mul(accTokensPerShare).div(1e18);
        allRewardDebt = allRewardDebt.add(user.rewardDebt);
        allStakedAmount = allStakedAmount.sub(_amount);

        emit StakeWithdrawn(msg.sender, _amount, pending);
    }

    function transferPendingReward(UserInfo memory user)
        private
        returns (uint256)
    {
        uint256 pending =
            user.amount.mul(accTokensPerShare).div(1e18).sub(user.rewardDebt);

        if (pending > 0) {
            rewardToken.safeTransfer(msg.sender, pending);
            allPaidReward = allPaidReward.add(pending);
        }

        return pending;
    }


    function withdrawPoolRemainder() external onlyApprover nonReentrant {
        updatePool();
        uint256 pending =
            allStakedAmount.mul(accTokensPerShare).div(1e18).sub(allRewardDebt);
        uint256 returnAmount = poolTokenAmount.sub(allPaidReward).sub(pending);
        allPaidReward = allPaidReward.add(returnAmount);

        rewardToken.safeTransfer(msg.sender, returnAmount);
        emit WithdrawPoolRemainder(msg.sender, returnAmount);
    }
}

