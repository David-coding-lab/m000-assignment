// Setup notes and challanges:
// -------------------------------------------
// Setup experience: This setup was a bit tiring — I installed the Rust
// toolchain (`rustup`/`cargo`), built and installed the `aiken` CLI, fixed
// the PATH, and then initialized the project layout. There were a few
// long compile steps and extra config work, so it felt like a lot of small
// steps in a row. But everything is now in place and the tests run.
// -------------------------------------------
// eUTxO vs UTxO :
// - UTxO (cash outputs): A transaction consumes unspent outputs
//   and creates new ones. Each UTxO is like a sealed envelope containing
//   a value. Simple wallets and Bitcoin use this model.
// - eUTxO (extended UTxO): Adds three things so scripts can be more
//   expressive while staying predictable:
//     Datum: extra data attached to a UTxO (like a label on the envelope)
//       — it stores state or information the script can read when the UTxO
//       is spent.
//     Redeemer: the input provided when spending the UTxO (like a note
//       inside the envelope explaining why you're opening it). It proves
//       or instructs the script how to allow the spend.
//     Script Context: the full transaction environment the validator sees
//       (what other inputs/outputs exist, fees, time range, signers, etc.).
//       This lets the validator make decisions using the full picture.
//   How it works together: when you try to spend a script-locked UTxO the
//   validator receives the datum (attached state), the redeemer (your
//   intent/proof), and the script context (the transaction details). The
//   validator returns true to allow the spend or false to deny it.
// Why native assets matter on Cardano (simple):
// - Native assets are tokens that exist alongside ADA as first-class
//   ledger values. That means you can send and receive custom tokens
//   directly, without needing a separate smart contract to represent them.
// - Benefits: lower complexity, lower costs, clearer accounting, easier
//   token transfers, and native support for NFTs and multi-asset wallets.
// -------------------------------------------

//Boolean test 
test bool_test(){
    let x = True
    let y = False
    x && !y 
}

//Interger test
test int_test(){
    let x = 10
    let y = 5
    // restore correct expectation
    x > y
}

//String test
test string_test(){
    let greeting = @"hello"
    greeting == @"hello"
}

// Questions 
// 1. what does the && operator do
// 2. what happens when you use ! before a boolean ?
// 3. how are strings represeted in Aiken?

//Answers
// 1. The && operator is a logical AND operator that returns True if both operands are True.
// 2. The ! operator is a logical NOT operator that negates the boolean value, turning True to False and vice versa.
// 3. Strings in Aiken are represented using the @ symbol followed by double quotes, like @"string".



// Exercise 4

// trace messages
test with_trace(){
    trace @"Starting test"
    let result = 5 * 5
    trace @"Calculation completed"
    result == 25
}

test trace_values(){
    let x = 100
    trace @"Value of x"
    x == 100
}

test trace_result(){
    let a = 7
    let b = 3
    let sum = a + b
    trace @"Sum calculated"
    sum == 10
}

test trace_conditions(){
    let condition = True
    trace @"Checking condition"
    condition == True
}

test trace_strings(){
    let name = @"Aiken"
    trace @"Name variable set"
    name == @"Aiken"
}

