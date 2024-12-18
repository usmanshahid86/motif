contract AppMetricsTracker is OwnableUpgradeable {
    struct UserActivity {
        uint256 lastInteractionBlock;
        uint256 consecutiveEpochs;
        uint256 totalInteractions;
    }
    
    // app -> user -> activity data
    mapping(address => mapping(address => UserActivity)) public userActivity;
    
    // Track active users per epoch
    mapping(address => mapping(uint256 => mapping(address => bool))) public epochActiveUsers;
    
    // Add transaction tracking
    struct TransactionMetrics {
        uint256 epoch;
        uint256 totalTransactions;
        uint256 uniqueUsers;
        mapping(address => bool) usersInEpoch;
    }
    
    // app -> epoch -> transaction metrics
    mapping(address => mapping(uint256 => TransactionMetrics)) public txMetrics;
    
    // Event to track all app interactions
    event AppInteraction(
        address indexed app,
        address indexed user,
        bytes4 indexed functionSelector,
        uint256 epoch
    );
    
    // Hook called by BitcoinPodManager during pod operations
    function recordPodActivity(
        address app, 
        address user, 
        bytes4 functionSelector
    ) external onlyPodManager {
        uint256 currentEpoch = block.number / EPOCH_LENGTH;
        UserActivity storage activity = userActivity[app][user];
        
        // If first interaction in this epoch
        if (!epochActiveUsers[app][currentEpoch][user]) {
            epochActiveUsers[app][currentEpoch][user] = true;
            
            // Check if user was active in previous epoch
            if (activity.lastInteractionBlock > 0 && 
                block.number - activity.lastInteractionBlock <= EPOCH_LENGTH) {
                activity.consecutiveEpochs++;
            } else {
                activity.consecutiveEpochs = 1;
            }
        }
        
        activity.lastInteractionBlock = block.number;
        activity.totalInteractions++;
    }
    
    function getRetentionScore(address app) public view returns (uint256) {
        uint256 currentEpoch = block.number / EPOCH_LENGTH;
        uint256 totalUsers = 0;
        uint256 retainedUsers = 0;
        
        // Look at last 4 epochs
        for (uint256 i = 0; i < 4; i++) {
            uint256 epochToCheck = currentEpoch - i;
            mapping(address => bool) storage epochUsers = epochActiveUsers[app][epochToCheck];
            
            // Count users with consecutive activity
            for (address user in epochUsers) {
                if (userActivity[app][user].consecutiveEpochs >= 2) {
                    retainedUsers++;
                }
                totalUsers++;
            }
        }
        
        if (totalUsers == 0) return 0;
        return (retainedUsers * 10000) / totalUsers;
    }
    
    // Called by proxy to record all transactions to registered apps
    function recordAppTransaction(
        address app,
        address user,
        bytes4 functionSelector
    ) external {
        require(IBitDSMRegistry(registry).isAppRegistered(app), "Not registered app");
        
        uint256 currentEpoch = block.number / EPOCH_LENGTH;
        TransactionMetrics storage metrics = txMetrics[app][currentEpoch];
        
        // Update transaction count
        metrics.totalTransactions++;
        
        // Track unique users per epoch
        if (!metrics.usersInEpoch[user]) {
            metrics.usersInEpoch[user] = true;
            metrics.uniqueUsers++;
        }
        
        emit AppInteraction(app, user, functionSelector, currentEpoch);
    }
    
    function getEpochMetrics(address app, uint256 epoch) public view returns (
        uint256 transactions,
        uint256 uniqueUsers
    ) {
        TransactionMetrics storage metrics = txMetrics[app][epoch];
        return (metrics.totalTransactions, metrics.uniqueUsers);
    }
}
