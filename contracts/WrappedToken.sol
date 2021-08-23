// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./ERC20Permit.sol";

contract WrappedToken is ERC20Permit, Pausable, Ownable {
    uint8 private immutable _decimals;

    /**
     *  @notice Construct a new WrappedToken contract
     *  @param _tokenName The EIP-20 token name
     *  @param _tokenSymbol The EIP-20 token symbol
     *  @param decimals_ The The EIP-20 decimals
     */
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint8 decimals_
    ) ERC20(_tokenName, _tokenSymbol) {
        _decimals = decimals_;
    }

    /**
     * @notice Mints `_amount` of tokens to the `_account` address
     * @param _account The address to which the tokens will be minted
     * @param _amount The _amount to be minted
     */
    function mint(address _account, uint256 _amount) public onlyOwner {
        super._mint(_account, _amount);
    }

    /**
     * @notice Burns `_amount` of tokens from the `_account` address
     * @param _account The address from which the tokens will be burned
     * @param _amount The _amount to be burned
     */
    function burnFrom(address _account, uint256 _amount) public onlyOwner {
        uint256 decreasedAllowance = allowance(_account, _msgSender()) -
            _amount;
        require(
            decreasedAllowance >= 0,
            "ERC20: burn amount exceeds allowance"
        );

        _approve(_account, _msgSender(), decreasedAllowance);
        _burn(_account, _amount);
    }

    /// @notice Pauses the contract
    function pause() public onlyOwner {
        super._pause();
    }

    /// @notice Unpauses the contract
    function unpause() public onlyOwner {
        super._unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 _amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, _amount);

        require(!paused(), "WrappedToken: token transfer while paused");
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}
