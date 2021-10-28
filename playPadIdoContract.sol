

contract PlayPadIdoContract is ReentrancyGuard, Ownable {
   
    //Deployed by Main Contract
    MainPlayPadContract deployerContract;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public busdToken; //Stable coin token contract address
    IERC20 public saleToken; //Sale token contract address
    uint256 public hardcapUsd; //hardcap value as usd 
    uint256 public totalSellAmountToken; //total amount to be sold
    uint256 public maxInvestorCount; //max. investor count
    uint256 public maxBuyValue; //max buying value per investor
    bool public contractStatus; //Contract running status
    uint256 public startTime; //IDO participation start time
    uint256 public endTime; //IDO participation end time
    uint256 public totalSoldAmountToken; //total sold amount as token
    uint256 public totalSoldAmountUsd; // total sold amount as usd
    uint256 public lockTime; //unlock date to get claim 
    address[] public whitelistedAddresses; //whitelisted address as array
    uint256[] public claimRoundsDate; //all claim rounds
    
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
        maxInvestorCount = _maxInvestorCount;
        maxBuyValue = _maxBuyValue;
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
    
    
    //return all whitelisted addresses as array
    function getWhitelistedAddresses() public view returns(address[] memory){
        return whitelistedAddresses;
    }
    
     function changeSaleTokenAddress(IERC20 _contractAddress) external onlyOwner nonReentrant {
        saleToken = _contractAddress;
    } 
    
    //change max buy limit
    function changeMaxBuyValue(uint256 _maxBuyValue) external onlyOwner{
        maxBuyValue = _maxBuyValue;
    }
    // change max investor count
    function changeMaxInvestorCount(uint256 _maxInvestorCount) external onlyOwner{
        maxBuyValue = _maxInvestorCount;
    }
    
    //change Start timestamp
    function changeTimestamps(uint256 _startTime, uint256 _endTime) external onlyOwner{
        startTime = _startTime;
        endTime = _endTime;
    }
    
    //calculate token amount according to deposit amount
    function calculateTokenAmount(uint256 amount) public view returns (uint256) {
       return (totalSellAmountToken.mul(amount)).div(hardcapUsd);
    }
    
    //buys token if passing controls
    function buyToken(uint256 busdAmount) external nonReentrant mustNotPaused {
        require(block.timestamp >= startTime);
        require(block.timestamp <= endTime);
        whitelistedInvestorData storage investor = _investorData[msg.sender];
        require(investor.isWhitelisted);
        require(maxBuyValue >= investor.totalBuyingAmountUsd.add(busdAmount), "Opps! You can't buy more than maximum limit.");
        require(investor.totalVesting >= investor.totalBuyingAmountUsd.add(busdAmount), "Oppss! You reached will reach your max vesting with this value, please try again with lower value.");
        require(busdToken.transferFrom(msg.sender, address(this), busdAmount));
        uint256 totalTokenAmount = calculateTokenAmount(busdAmount);
        investor.totalBuyingAmountUsd = investor.totalBuyingAmountUsd.add(busdAmount);
        investor.totalBuyingAmountToken = investor.totalBuyingAmountToken.add(totalTokenAmount);
        investor.investorAddress = msg.sender;
        totalSoldAmountToken = totalSoldAmountToken.add(totalTokenAmount);
        totalSoldAmountUsd = totalSoldAmountUsd.add(busdAmount);
        emit NewBuying(msg.sender, busdAmount, block.timestamp);
    }
    
    //emergency withdraw function in worst cases
    function emergencyWithdrawAllBusd() external payable nonReentrant onlyOwner {
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
    
    //claim tokens according to claim periods 
     function claimTokens() external nonReentrant {
        require(block.timestamp >= lockTime, "bad lock time");
        whitelistedInvestorData storage investor = _investorData[msg.sender];
        require(investor.isWhitelisted, "you are not whitelisted");
        uint256 investorRoundNumber = investor.claimRound;
        roundDatas storage roundDetail = _roundDatas[investorRoundNumber];
        require(roundDetail.roundStartDate != 0 ,"round didn't added yet");
        require(block.timestamp >= roundDetail.roundStartDate ,"round didn't start yet");
        require(investor.totalBuyingAmountToken >= investor.claimedValue.add(investor.totalBuyingAmountToken.mul(roundDetail.roundPercent).div(100)) ,"already you got all your tokens");
        require(saleToken.transfer(msg.sender, investor.totalBuyingAmountToken.mul(roundDetail.roundPercent).div(100)) ,"bad transfer");
        investor.claimRound = investor.claimRound.add(1);
        investor.lastClaimDate = block.timestamp;
        investor.claimedValue = investor.claimedValue.add(investor.totalBuyingAmountToken.mul(roundDetail.roundPercent).div(100));
    }
     
    //add new claim round
    function addNewClaimRound(uint256 _roundNumber, uint256 _roundStartDate, uint256 _claimPercent) external nonReentrant onlyOwner {
    roundDatas storage roundDetail = _roundDatas[_roundNumber];
    roundDetail.roundStartDate = _roundStartDate;
    roundDetail.roundPercent = _claimPercent;
    claimRoundsDate.push(_roundStartDate);
    }
    
   
    /*
    Define users vestings and addresses according to datas taken from javascript. function at javascript controls buy limits and other details
    after that it multiples stake duration time of users with their deposited amounts and converts them to percentage based result and calculate their buying amounts according to tokenomics of IDO
    */
    
    function addUsersToWhitelist(address[] memory _whitelistedAddresses, uint256[] memory _buyingLimits) external onlyOwner nonReentrant{ 
        for(uint256 i = 0;  i < _whitelistedAddresses.length; i++){
             whitelistedInvestorData storage investor = _investorData[_whitelistedAddresses[i]];
             investor.totalVesting = _buyingLimits[i];
             investor.isWhitelisted = true;
             whitelistedAddresses.push(_whitelistedAddresses[i]);
        }
       
    }
 }
