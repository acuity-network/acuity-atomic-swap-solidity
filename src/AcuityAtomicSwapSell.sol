// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.12;

contract AcuityAtomicSwapSell {

    /**
     * @dev Mapping of selling address to ACU address.
     */
    mapping (address => bytes32) addressAcuAddress;

    /**
     * @dev Mapping of chainIdAdapterIdAssetId (to buy) to linked list of accounts, starting with the largest.
     */
    mapping (bytes16 => mapping (address => address)) chainIdAdapterIdAssetIdAccountsLL;

    /**
     * @dev Mapping of chainIdAdapterIdAssetId (to buy) to selling address to value.
     */
    mapping (bytes16 => mapping (address => uint)) chainIdAdapterIdAssetIdAccountValue;

    /**
     * @dev
     */
    mapping (bytes32 => uint256) lockIdValue;

    /**
     * @dev
     */
    event AddToOrder(bytes16 orderId, address seller, bytes32 chainIdAdapterIdAssetId, bytes32 foreignAddress, uint256 value);

    /**
     * @dev
     */
    event RemoveFromOrder(bytes16 orderId, uint256 value);

    /**
     * @dev
     */
    event LockSell(bytes16 orderId, bytes32 hashedSecret, uint256 timeout, uint256 value);

    /**
     * @dev
     */
    event UnlockSell(bytes16 orderId, bytes32 secret);

    /**
     * @dev
     */
    event TimeoutSell(bytes16 orderId, bytes32 hashedSecret);

    /**
     * @dev
     */
    function setAcuAddress(bytes32 acuAddress) external {
        addressAcuAddress[msg.sender] = acuAddress;
    }

    /**
     * @dev
     * @param chainIdAdapterIdAssetId
     * @param value Size of deposit to add. Must be greater than 0.
     */
    function addDeposit(bytes16 chainIdAdapterIdAssetId, uint value) internal {
        mapping (address => address) storage accountsLL = chainIdAdapterIdAssetIdAccountsLL[chainIdAdapterIdAssetId];
        mapping (address => uint) storage accountValue = chainIdAdapterIdAssetIdAccountValue[chainIdAdapterIdAssetId];
        // Get new total.
        uint total = accountValue[msg.sender] + value;
        // Search for new previous.
        address prev = address(0);
        while (accountValue[accountsLL[prev]] >= total) {
            prev = accountsLL[prev];
        }
        bool replace = false;
        // Is sender already in the list?
        if (accountValue[msg.sender] > 0) {
            // Search for old previous.
            address oldPrev = address(0);
            while (accountsLL[oldPrev] != msg.sender) {
                oldPrev = accountsLL[oldPrev];
            }
            // Is it in the same position?
            if (prev == oldPrev) {
                replace = true;
            }
            else {
                // Remove sender from current position.
                accountsLL[oldPrev] = accountsLL[msg.sender];
            }
        }
        if (!replace) {
            // Insert into linked list.
            accountsLL[msg.sender] = accountsLL[prev];
            accountsLL[prev] = msg.sender;
        }
        // Update the value deposited.
        accountValue[msg.sender] = total;
    }

    /**
     * @dev
     * @param chainIdAdapterIdAssetId
     * @param value Size of deposit to remove. Must be bigger than or equal to deposit value.
     */
    function removeDeposit(bytes16 chainIdAdapterIdAssetId, uint value) internal {
        mapping (address => address) storage accountsLL = chainIdAdapterIdAssetIdAccountsLL[chainIdAdapterIdAssetId];
        mapping (address => uint) storage accountValue = chainIdAdapterIdAssetIdAccountValue[chainIdAdapterIdAssetId];
        // Get new total.
        uint total = accountValue[msg.sender] - value;
        // Search for old previous.
        address oldPrev = address(0);
        while (accountsLL[oldPrev] != msg.sender) {
            oldPrev = accountsLL[oldPrev];
        }
        // Remove sender from current position.
        accountsLL[oldPrev] = accountsLL[msg.sender];
        // Is it in a different position?
        if (total > 0) {
            // Search for new previous.
            address prev = address(0);
            while (accountValue[accountsLL[prev]] >= total) {
                prev = accountsLL[prev];
            }
            // Insert into linked list.
            accountsLL[msg.sender] = accountsLL[prev];
            accountsLL[prev] = msg.sender;
        }
        // Update the value deposited.
        accountValue[msg.sender] = total;
    }

    /**
     * @dev Deposit funds to be sold for a specific asset.
     * @param chainIdAdapterIdAssetId 4 bytes chainId, 4 bytes adapterId, 8 bytes assetId
     */
    function deposit(bytes16 chainIdAdapterIdAssetId) external payable {
        if (msg.value > 0) {
            addDeposit(chainIdAdapterIdAssetId, msg.value);
        }
    }

    function withdraw(bytes16 chainIdAdapterIdAssetId, uint value) external {
        // Check there is enough.
        require(chainIdAdapterIdAssetIdAccountValue[chainIdAdapterIdAssetId][msg.sender] >= value);
        // Remove the deposit.
        removeDeposit(chainIdAdapterIdAssetId, value);
        // Send the funds back.
        payable(msg.sender).transfer(value);
    }

    /**
     * @dev Create a sell lock. Called by seller.
     * @param chainIdAdapterIdAssetId 4 bytes chainId, 4 bytes adapterId, 8 bytes assetId
     */
    function lockSell(bytes16 chainIdAdapterIdAssetId, bytes32 hashedSecret, address buyer, uint256 timeout, uint256 value) external {
        // Ensure value is not 0.
        require(value > 0, "Value to lock must be greater than 0.");
        // Check there is enough.
        require(chainIdAdapterIdAssetIdAccountValue[chainIdAdapterIdAssetId][msg.sender] >= value, "Deposit not big enough.");
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encodePacked(msg.sender, hashedSecret, buyer, timeout));
        // Ensure lockId is not already in use.
        require(lockIdValue[lockId] == 0, "Sell lock already exists.");
        // Move value into sell lock.
        removeDeposit(chainIdAdapterIdAssetId, value);
        lockIdValue[lockId] = value;
        // Log info.
//        emit LockSell(orderId, hashedSecret, timeout, value);
    }

    /**
     * Called by buyer before lock has timed out.
     */
    function unlockSell(address seller, bytes32 secret, uint256 timeout) external {
        // Check sell lock has not timed out.
        require(timeout > block.timestamp, "Lock timed out.");
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encodePacked(seller, keccak256(abi.encodePacked(secret)), msg.sender, timeout));
        // Get lock value.
        uint256 value = lockIdValue[lockId];
        // Delete lock.
        delete lockIdValue[lockId];
        // Send the funds.
        payable(msg.sender).transfer(value);
        // Log info.
//        emit UnlockSell(orderId, secret);
    }

    /**
     * Called by seller after lock has timed out (if buyer did not reveal secret).
     */
    function timeoutSell(bytes16 chainIdAdapterIdAssetId, bytes32 hashedSecret, address buyer, uint256 timeout) external {
        // Check lock has timed out.
        require(timeout <= block.timestamp, "Lock not timed out.");
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encodePacked(msg.sender, hashedSecret, buyer, timeout));

        require(lockIdValue[lockId] > 0, "Lock does not exist.");

        // Return funds and delete lock.
        addDeposit(chainIdAdapterIdAssetId, lockIdValue[lockId]);
        delete lockIdValue[lockId];
        // Log info.
//        emit TimeoutSell(orderId, hashedSecret);
    }

    /**
     * @dev
     */
    function getAcuAddress(address seller) view external returns (bytes32 acuAddress) {
        acuAddress = addressAcuAddress[seller];
    }

    /**
     * @dev Get a list of deposits for a specific asset.
     * @param chainIdAdapterIdAssetId 4 bytes chainId, 4 bytes adapterId, 8 bytes assetId
     * @param limit Maximum number of deposits to return.
     */
    function getDeposits(bytes16 chainIdAdapterIdAssetId, uint limit) view external returns (address[] memory accounts, uint[] memory values) {
        mapping (address => address) storage accountsLL = chainIdAdapterIdAssetIdAccountsLL[chainIdAdapterIdAssetId];
        mapping (address => uint) storage accountValue = chainIdAdapterIdAssetIdAccountValue[chainIdAdapterIdAssetId];
        // Count how many accounts to return.
        address account = address(0);
        uint _limit = 0;
        while (accountsLL[account] != address(0) && _limit < limit) {
            account = accountsLL[account];
            _limit++;
        }
        // Allocate the arrays.
        accounts = new address[](_limit);
        values = new uint[](_limit);
        // Populate the array.
        account = accountsLL[address(0)];
        for (uint i = 0; i < _limit; i++) {
            accounts[i] = account;
            values[i] = accountValue[account];
            account = accountsLL[account];
        }
    }

    /**
     * @dev
     */
    function getDepositValue(bytes16 chainIdAdapterIdAssetId, address seller) view external returns (uint256 value) {
        value = chainIdAdapterIdAssetIdAccountValue[chainIdAdapterIdAssetId][seller];
    }


    /**
     * @dev
     */
    function getLockValue(address seller, bytes32 hashedSecret, address buyer, uint256 timeout) view external returns (uint256 value) {
        // Calculate lockId.
        bytes32 lockId = keccak256(abi.encodePacked(seller, hashedSecret, buyer, timeout));
        value = lockIdValue[lockId];
    }

    /**
     * @dev
     */
    function getLockValue(bytes32 lockId) view external returns (uint256 value) {
        value = lockIdValue[lockId];
    }

}
