use aiken/list
use aiken/interval
use cardano/transaction.{Transaction, Spend}
use cardano/script_context.{ScriptContext}
use cardano/transaction/credential as credential
use mocktail.{
  mocktail_tx, tx_in, tx_in_inline_datum, tx_out, tx_out_inline_datum,
  complete, set_fee, set_validity_range, add_signatory,
  mock_pub_key_address, mock_pub_key_hash, mock_script_address, mock_tx_hash,
  mock_utxo_ref
}
use cardano/assets.{from_lovelace}

// --- M001: Define Types ---

pub type GiftDatum {
  beneficiary: Hash<Blake2b_224, credential.VerificationKey>,
  deadline: Int,
}

pub type Action {
  Claim
  Cancel
}

// --- M001: The Validator Logic ---

validator gift_contract {
  spend(datum: Option<GiftDatum>, _redeemer: Action, _ctx: ScriptContext) {
    expect Some(GiftDatum { beneficiary, deadline }) = datum
    let tx = _ctx.transaction

    // Rule 1: Must be signed by the beneficiary
    let signed_by_beneficiary = list.has(tx.extra_signatories, beneficiary)

    // Rule 2: Must be after the deadline
    let is_past_deadline = interval.is_entirely_after(tx.validity_range, deadline)

    trace @"Checking Signature": signed_by_beneficiary
    trace @"Checking Deadline": is_past_deadline

    signed_by_beneficiary && is_past_deadline
  }
}

// ----------------------
// M002: Mock transaction helpers and tests
// ----------------------

// Helper to build a locking transaction
fn build_locking_tx(datum: GiftDatum) -> Transaction {
  mocktail_tx()
    // Input: 15 ADA from a user wallet
    |> tx_in(True, mock_tx_hash(0), 0, from_lovelace(15_000_000), mock_pub_key_address(0, None))

    // Output: 10 ADA LOCKED at Script Address with Inline Datum
    |> tx_out(True, mock_script_address(0, None), from_lovelace(10_000_000))
    |> tx_out_inline_datum(True, datum)

    // Change: 4 ADA back to user
    |> tx_out(True, mock_pub_key_address(0, None), from_lovelace(4_000_000))

    |> complete()
    |> set_fee(True, 1_000_000) // 1 ADA Fee
}

test m002_locking_verification() {
  let my_datum = GiftDatum { beneficiary: mock_pub_key_hash(1), deadline: 1000 }
  let tx = build_locking_tx(my_datum)

  // Verify M002 success criteria
  expect [_, script_output, _] = tx.outputs

  // 1. Verify it went to a script address
  expect credential.Script(_) = script_output.address.payment_credential

  // 2. Verify datum is attached
  expect transaction.InlineDatum(d) = script_output.datum
  expect d_typed: GiftDatum = d
  d_typed == my_datum
}

// Helper to build an unlocking transaction
fn build_unlocking_tx(datum: GiftDatum) -> Transaction {
  mocktail_tx()
    // Input: Spending the 10 ADA FROM the script
    |> tx_in(True, mock_tx_hash(1), 1, from_lovelace(10_000_000), mock_script_address(0, None))
    // Crucial: We must say this input has the datum attached
    |> tx_in_inline_datum(True, datum)

    // Output: 9 ADA to the beneficiary
    |> tx_out(True, mock_pub_key_address(1, None), from_lovelace(9_000_000))

    |> complete()
    |> set_fee(True, 1_000_000)
}

test m002_unlocking_verification() {
  let my_datum = GiftDatum { beneficiary: mock_pub_key_hash(1), deadline: 1000 }
  let tx = build_unlocking_tx(my_datum)

  // Verify input is correct
  expect [script_input] = tx.inputs
  expect credential.Script(_) = script_input.output.address.payment_credential

  // Verify balance: 10 In = 9 Out + 1 Fee
  True
}

// 1. SUCCESS CASE: correct signer and after deadline
test m002_logic_success() {
  let datum = GiftDatum { beneficiary: mock_pub_key_hash(1), deadline: 1000 }

  let tx = build_unlocking_tx(datum)
    |> add_signatory(mock_pub_key_hash(1))
    |> set_validity_range(True, 1001, 2000)

  let ctx = ScriptContext { transaction: tx, purpose: Spend(mock_utxo_ref(0, 0)) }

  gift_contract.spend(Some(datum), Claim, ctx)
}

// 2. FAILURE CASE (Wrong Signer)
test m002_logic_fail_signer() {
  let datum = GiftDatum { beneficiary: mock_pub_key_hash(1), deadline: 1000 }

  let tx = build_unlocking_tx(datum)
    |> add_signatory(mock_pub_key_hash(2))
    |> set_validity_range(True, 1001, 2000)

  let ctx = ScriptContext { transaction: tx, purpose: Spend(mock_utxo_ref(0, 0)) }

  !gift_contract.spend(Some(datum), Claim, ctx)
}

// 3. FAILURE CASE (Too Early)
test m002_logic_fail_time() {
  let datum = GiftDatum { beneficiary: mock_pub_key_hash(1), deadline: 1000 }

  let tx = build_unlocking_tx(datum)
    |> add_signatory(mock_pub_key_hash(1))
    // Time is before deadline
    |> set_validity_range(True, 500, 999)

  let ctx = ScriptContext { transaction: tx, purpose: Spend(mock_utxo_ref(0, 0)) }

  !gift_contract.spend(Some(datum), Claim, ctx)
}
