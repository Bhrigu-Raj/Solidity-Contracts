// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Ownable.sol";

contract TokenSale is Ownable {
    IERC20 public token;

    // Sale phases
    enum SalePhase {
        Presale,
        PublicSale
    }
    SalePhase public currentPhase = SalePhase.Presale;

    // Presale details
    uint256 public presaleCap;
    uint256 public presaleMinContribution;
    uint256 public presaleMaxContribution;
    uint256 public presaleRaised;

    // Public sale details
    uint256 public publicSaleCap;
    uint256 public publicSaleMinContribution;
    uint256 public publicSaleMaxContribution;
    uint256 public publicSaleRaised;

    // Mapping to track contributions of each participant
    mapping(address => uint256) public contributions;

    event TokensPurchased(address indexed buyer, uint256 amount);

    constructor(
        IERC20 _token,
        uint256 _presaleCap,
        uint256 _presaleMinContribution,
        uint256 _presaleMaxContribution,
        uint256 _publicSaleCap,
        uint256 _publicSaleMinContribution,
        uint256 _publicSaleMaxContribution
    )
        Ownable(msg.sender) // Set the deployer as the initial owner
    {
        token = _token;
        presaleCap = _presaleCap;
        presaleMinContribution = _presaleMinContribution;
        presaleMaxContribution = _presaleMaxContribution;
        publicSaleCap = _publicSaleCap;
        publicSaleMinContribution = _publicSaleMinContribution;
        publicSaleMaxContribution = _publicSaleMaxContribution;
    }

    modifier inPresalePhase() {
        require(currentPhase == SalePhase.Presale, "Presale is not active");
        _;
    }

    modifier inPublicSalePhase() {
        require(
            currentPhase == SalePhase.PublicSale,
            "Public sale is not active"
        );
        _;
    }

    function contributeToPresale() external payable inPresalePhase {
        require(
            msg.value >= presaleMinContribution,
            "Contribution below minimum amount"
        );
        require(
            msg.value <= presaleMaxContribution,
            "Contribution exceeds maximum amount"
        );
        require(
            presaleRaised + msg.value <= presaleCap,
            "Presale cap exceeded"
        );

        contributions[msg.sender] += msg.value;
        presaleRaised += msg.value;

        // Distribute tokens immediately upon contribution
        uint256 tokensToDistribute = calculateTokens(msg.value);
        require(
            token.transfer(msg.sender, tokensToDistribute),
            "Token transfer failed"
        );

        emit TokensPurchased(msg.sender, tokensToDistribute);
    }

    function contributeToPublicSale() external payable inPublicSalePhase {
        require(
            msg.value >= publicSaleMinContribution,
            "Contribution below minimum amount"
        );
        require(
            msg.value <= publicSaleMaxContribution,
            "Contribution exceeds maximum amount"
        );
        require(
            publicSaleRaised + msg.value <= publicSaleCap,
            "Public sale cap exceeded"
        );

        contributions[msg.sender] += msg.value;
        publicSaleRaised += msg.value;

        // Distribute tokens immediately upon contribution
        uint256 tokensToDistribute = calculateTokens(msg.value);
        require(
            token.transfer(msg.sender, tokensToDistribute),
            "Token transfer failed"
        );

        emit TokensPurchased(msg.sender, tokensToDistribute);
    }

    function distributeTokens(
        address _recipient,
        uint256 _amount
    ) external onlyOwner {
        require(
            currentPhase == SalePhase.PublicSale,
            "Cannot distribute tokens outside of public sale"
        );
        require(_amount > 0, "Amount must be greater than zero");
        require(
            publicSaleRaised + _amount <= publicSaleCap,
            "Public sale cap exceeded"
        );

        // Distribute tokens to the specified address
        require(token.transfer(_recipient, _amount), "Token transfer failed");

        publicSaleRaised += _amount;

        emit TokensPurchased(_recipient, _amount);
    }

    function claimRefund() external {
        require(
            currentPhase == SalePhase.PublicSale,
            "Refunds are only available during public sale"
        );
        require(publicSaleRaised < publicSaleCap, "Refunds are not available");

        uint256 contribution = contributions[msg.sender];
        require(contribution > 0, "No contribution found");

        // Refund the contributor
        contributions[msg.sender] = 0;
        payable(msg.sender).transfer(contribution);
    }

    function switchToPublicSale() external onlyOwner {
        require(currentPhase == SalePhase.Presale, "Invalid phase transition");
        currentPhase = SalePhase.PublicSale;
    }

    function calculateTokens(uint256 _amount) internal view returns (uint256) {
        // Customize this function based on your token price or conversion rate
        // For simplicity, assuming 1 Ether = 1 Token
        return _amount;
    }
}
