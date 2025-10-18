// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract EnergyTradingNetwork {
    
    struct EnergyProducer {
        address producerAddress;
        uint256 totalEnergyProduced;
        uint256 availableEnergy;
        uint256 pricePerKWh; // Price in wei per kWh
        bool isActive;
    }
    
    struct EnergyTransaction {
        address producer;
        address consumer;
        uint256 energyAmount;
        uint256 pricePerKWh;
        uint256 totalCost;
        uint256 timestamp;
        bool isCompleted;
    }
    
    mapping(address => EnergyProducer) public producers;
    mapping(address => uint256) public consumerBalances;
    EnergyTransaction[] public transactions;
    
    address[] public activeProducers;
    
    event EnergyListed(address indexed producer, uint256 amount, uint256 pricePerKWh);
    event EnergyPurchased(address indexed consumer, address indexed producer, uint256 amount, uint256 totalCost);
    event FundsWithdrawn(address indexed user, uint256 amount);
    
    modifier onlyActiveProducer() {
        require(producers[msg.sender].isActive, "Producer not registered or inactive");
        _;
    }
    
    modifier hasBalance() {
        require(consumerBalances[msg.sender] > 0, "Insufficient balance");
        _;
    }
    
    // Core Function 1: List Energy for Sale
    function listEnergy(uint256 _energyAmount, uint256 _pricePerKWh) external {
        require(_energyAmount > 0, "Energy amount must be greater than 0");
        require(_pricePerKWh > 0, "Price must be greater than 0");
        
        if (!producers[msg.sender].isActive) {
            producers[msg.sender] = EnergyProducer({
                producerAddress: msg.sender,
                totalEnergyProduced: 0,
                availableEnergy: 0,
                pricePerKWh: _pricePerKWh,
                isActive: true
            });
            activeProducers.push(msg.sender);
        }
        
        producers[msg.sender].availableEnergy += _energyAmount;
        producers[msg.sender].totalEnergyProduced += _energyAmount;
        producers[msg.sender].pricePerKWh = _pricePerKWh;
        
        emit EnergyListed(msg.sender, _energyAmount, _pricePerKWh);
    }
    
    // Core Function 2: Purchase Energy
    function purchaseEnergy(address _producer, uint256 _energyAmount) external payable {
        require(producers[_producer].isActive, "Producer not active");
        require(_energyAmount > 0, "Energy amount must be greater than 0");
        require(producers[_producer].availableEnergy >= _energyAmount, "Insufficient energy available");
        
        uint256 totalCost = _energyAmount * producers[_producer].pricePerKWh;
        require(msg.value >= totalCost, "Insufficient payment");
        
        // Update producer's available energy
        producers[_producer].availableEnergy -= _energyAmount;
        
        // Add funds to producer's balance
        consumerBalances[_producer] += totalCost;
        
        // Refund excess payment to consumer
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
        
        // Record transaction
        transactions.push(EnergyTransaction({
            producer: _producer,
            consumer: msg.sender,
            energyAmount: _energyAmount,
            pricePerKWh: producers[_producer].pricePerKWh,
            totalCost: totalCost,
            timestamp: block.timestamp,
            isCompleted: true
        }));
        
        emit EnergyPurchased(msg.sender, _producer, _energyAmount, totalCost);
    }
    
    // Core Function 3: Withdraw Earnings
    function withdrawEarnings() external hasBalance {
        uint256 amount = consumerBalances[msg.sender];
        consumerBalances[msg.sender] = 0;
        
        payable(msg.sender).transfer(amount);
        
        emit FundsWithdrawn(msg.sender, amount);
    }
    
    // View Functions
    function getActiveProducers() external view returns (address[] memory) {
        return activeProducers;
    }
    
    function getProducerInfo(address _producer) external view returns (
        uint256 totalProduced,
        uint256 availableEnergy,
        uint256 pricePerKWh,
        bool isActive
    ) {
        EnergyProducer memory producer = producers[_producer];
        return (
            producer.totalEnergyProduced,
            producer.availableEnergy,
            producer.pricePerKWh,
            producer.isActive
        );
    }
    
    function getTransactionHistory() external view returns (EnergyTransaction[] memory) {
        return transactions;
    }
    
    function getBalance(address _user) external view returns (uint256) {
        return consumerBalances[_user];
    }
    
    // Emergency function to deactivate a producer
    function deactivateProducer() external onlyActiveProducer {
        producers[msg.sender].isActive = false;
        
        // Remove from active producers array
        for (uint i = 0; i < activeProducers.length; i++) {
            if (activeProducers[i] == msg.sender) {
                activeProducers[i] = activeProducers[activeProducers.length - 1];
                activeProducers.pop();
                break;
            }
        }
    }
}



// AUTO-UPDATE-START
Updated on 2025-10-18
// AUTO-UPDATE-END
