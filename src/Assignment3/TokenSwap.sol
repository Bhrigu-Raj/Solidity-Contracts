// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./TokenABC.sol";
import "./TokenXYZ.sol";

contract TokenSwap {
    using SafeERC20 for IERC20;

    address payable admin;
    uint256 ratioAX;
    bool AcheaperthenX;
    uint256 fees;
    TokenABC public tokenABC;
    TokenXYZ public tokenXYZ;

    event SwapTokenXToY(address indexed from, uint256 amountX, uint256 amountY);
    event SwapTokenYToX(address indexed from, uint256 amountY, uint256 amountX);

    constructor(address _tokenABC, address _tokenXYZ) {
        admin = payable(msg.sender);
        tokenABC = TokenABC(_tokenABC);
        tokenXYZ = TokenXYZ(_tokenXYZ);

        tokenABC.approve(address(this), tokenABC.totalSupply());
        tokenXYZ.approve(address(this), tokenABC.totalSupply());
    }

    modifier onlyAdmin() {
        require(
            payable(msg.sender) == admin,
            "Only admin can call this function"
        );
        _;
    }

    function setRatio(uint256 _ratio) public onlyAdmin {
        ratioAX = _ratio;
    }

    function getRatio() public view onlyAdmin returns (uint256) {
        return ratioAX;
    }

    function setFees(uint256 _fees) public onlyAdmin {
        fees = _fees;
    }

    function getFees() public view onlyAdmin returns (uint256) {
        return fees;
    }

    function swapTKA(uint256 amountTKA) public returns (uint256) {
        require(amountTKA > 0, "amountTKA must be greater than zero");
        require(
            tokenABC.balanceOf(msg.sender) >= amountTKA,
            "Sender doesn't have enough Tokens"
        );

        uint256 exchangeA = amountTKA * ratioAX;
        uint256 exchangeAmount = exchangeA -
            uint256((mul(exchangeA, fees)) / 100);

        require(
            exchangeAmount > 0,
            "Exchange amount must be greater than zero"
        );
        require(
            tokenXYZ.balanceOf(address(this)) > exchangeAmount,
            "Insufficient XYZ Tokens in the exchange"
        );

        tokenABC.transferFrom(msg.sender, address(this), amountTKA);
        tokenXYZ.approve(address(msg.sender), exchangeAmount);
        tokenXYZ.transferFrom(
            address(this),
            address(msg.sender),
            exchangeAmount
        );

        emit SwapTokenXToY(msg.sender, amountTKA, exchangeAmount);
        return exchangeAmount;
    }

    function swapTKX(uint256 amountTKX) public returns (uint256) {
        require(amountTKX > 0, "amountTKX must be greater than zero");
        require(
            tokenXYZ.balanceOf(msg.sender) >= amountTKX,
            "Sender doesn't have enough Tokens"
        );

        uint256 exchangeA = amountTKX / ratioAX;
        uint256 exchangeAmount = exchangeA - (exchangeA * fees) / 100;

        require(
            exchangeAmount > 0,
            "Exchange amount must be greater than zero"
        );
        require(
            tokenABC.balanceOf(address(this)) >= exchangeAmount,
            "Insufficient ABC Tokens in the exchange"
        );

        tokenXYZ.transferFrom(msg.sender, address(this), amountTKX);
        tokenABC.approve(address(msg.sender), exchangeAmount);
        tokenABC.transferFrom(
            address(this),
            address(msg.sender),
            exchangeAmount
        );

        emit SwapTokenYToX(msg.sender, amountTKX, exchangeAmount);
        return exchangeAmount;
    }

    function buyTokensABC(uint256 amount) public payable onlyAdmin {
        tokenABC.buyTokens{value: msg.value}(amount);
    }

    function buyTokensXYZ(uint256 amount) public payable onlyAdmin {
        tokenXYZ.buyTokens{value: msg.value}(amount);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}
