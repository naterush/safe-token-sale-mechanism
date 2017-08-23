pragma solidity ^0.4.11;

import "./StandardToken.sol";

contract SafeToken is StandardToken {
  uint sale_price;
  uint purchase_price;

  address sale_administrator;
  modifier only_administrator() {
    require (msg.sender == sale_administrator);
    _;
  }

  mapping (address => uint) eth_balance;
  uint outstanding_eth;

  function SafeToken(uint starting_sale_price, uint starting_purchase_price) {
    require (starting_sale_price >= starting_purchase_price);
    sale_administrator = msg.sender;
  }

  function purchase_tokens() payable {
    uint num_tokens_bought = msg.value / sale_price;
    totalSupply += num_tokens_bought;
    balances[msg.sender] += num_tokens_bought;
    // then refund for any rounding error
    uint rounding_error = msg.value - num_tokens_bought * sale_price;
    msg.sender.transfer(rounding_error);
  }

  function sell_tokens(uint amount_to_sell) {
    require (balances[msg.sender] >= amount_to_sell);
    balances[msg.sender] -= amount_to_sell;
    totalSupply -= amount_to_sell;
    msg.sender.transfer(amount_to_sell * purchase_price);
  }

  function claim_revenue() {
    require (eth_balance[msg.sender] > 0);
    outstanding_eth -= eth_balance[msg.sender];
    uint to_send = eth_balance[msg.sender];
    eth_balance[msg.sender] = 0;
    msg.sender.transfer(to_send);
  }

  /* ADMINISTRATOR ONLY BEYOND THIS POINT :~) */

  function move_ceiling(uint new_sale_price) only_administrator() {
    require (new_sale_price >= purchase_price); // else contract will be drained
    sale_price = new_sale_price;
  }

  function move_floor(uint new_purchase_price) only_administrator() {
    require (new_purchase_price <= sale_price); // else contract will be drained
    require ((((this.balance - outstanding_eth) / new_purchase_price) - totalSupply) > 0);
    purchase_price = new_purchase_price;
  }

  function allocate_funds_to_beneficiary(address beneficiary, uint amount) only_administrator() {
    //Make sure the contract will still have the ability to repay all outstanding debts
    outstanding_eth = outstanding_eth - eth_balance[beneficiary] + amount;
    require ((((this.balance - outstanding_eth) / purchase_price) - totalSupply) > 0);
    eth_balance[beneficiary] = amount;
  }
}
