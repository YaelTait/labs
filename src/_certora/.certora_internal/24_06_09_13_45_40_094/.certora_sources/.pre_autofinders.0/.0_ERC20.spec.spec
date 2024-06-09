/**
 * # ERC20 Example
 *
 * This is an example specification for a generic ERC20 contract. It contains several
 * simple rules verifying the integrity of the transfer function.
 * To run, execute the following command in terminal:
 * 
 * certoraRun ERC20.sol --verify ERC20:ERC20.spec --solc solc8.0
 * 
 * One of the rules here is badly phrased, and results in an erroneous fail.
 * Understand the counter example provided by the Prover and then run the fixed
 * spec:
 *
 * certoraRun ERC20.sol --verify ERC20:ERC20Fixed.spec --solc solc8.0
 */

// The methods block below gives various declarations regarding solidity methods.
/// @title Transfer must move `amount` tokens from the caller's account to `recipient`
rule transferSpec(address recipient, uint amount) {

    env e;
    
    // `mathint` is a type that represents an integer of any size
    mathint balance_sender_before = balanceOf(e.msg.sender);
    mathint balance_recip_before = balanceOf(recipient);

    transfer(e, recipient, amount);

    mathint balance_sender_after = balanceOf(e.msg.sender);
    mathint balance_recip_after = balanceOf(recipient);

    address sender = e.msg.sender;  // A convenient alias

    // Operations on mathints can never overflow or underflow. 
    assert recipient != sender => balance_sender_after == balance_sender_before - amount,
        "transfer must decrease sender's balance by amount";

    assert recipient != sender => balance_recip_after == balance_recip_before + amount,
        "transfer must increase recipient's balance by amount";
    
    assert recipient == sender => balance_sender_after == balance_sender_before,
        "transfer must not change sender's balancer when transferring to self";
}