//https://quint.sh/docs/getting-started



// >>> MODEL CHECKING EXAMPLE

// PS ...\formal_verification\versions\00\bank> quint run bank.qnt --invariant=no_negatives
// Fetching Rust evaluator v0.6.0...
//   Downloading Rust evaluator from https://api.github.com/repos/quint-co/quint/releases/assets/385414004...
//   Extracting ...\.quint\rust-evaluator-v0.6.0\quint_evaluator-x86_64-pc-windows-msvc.zip...
//   [ok] Rust evaluator installed at: ...\.quint\rust-evaluator-v0.6.0\quint_evaluator.exe

// An example execution:

// [State 0] { balances: Map("alice" -> 0, "bob" -> 0, "charlie" -> 0) }

// [State 1] { balances: Map("alice" -> -65, "bob" -> 0, "charlie" -> 0) }

// [violation] Found an issue (2957ms at 7 traces/second).
// Use --verbosity=3 to show executions.
// Use --seed=0xd84e559ccfa69bcb --backend=rust to reproduce.
// error: Invariant violated



// >>> MODEL BASED TESTING (MBT) EXAMPLE

// PS ...\formal_verification\versions\00\bank> quint run bank.qnt --invariant=no_negatives --mbt
// An example execution:

// [State 0]
// {
//   balances: Map("alice" -> 0, "bob" -> 0, "charlie" -> 0),
//   mbt::actionTaken: "init",
//   mbt::nondetPicks: { account: None, amount: None }
// }

// [State 1]
// {
//   balances: Map("alice" -> -10, "bob" -> 0, "charlie" -> 0),
//   mbt::actionTaken: "withdraw",
//   mbt::nondetPicks: { account: Some("alice"), amount: Some(10) }
// }

// [violation] Found an issue (90ms at 233 traces/second).
// Use --verbosity=3 to show executions.
// Use --seed=0x829db7629ae79ea9 --backend=rust to reproduce.
// error: Invariant violated



// >>> FIXED VERSION (WITH PRECONDITION) EXAMPLE

// PS ...\formal_verification\versions\00\bank> quint run bank.qnt --invariant=no_negatives
// An example execution:

// [State 0] { balances: Map("alice" -> 0, "bob" -> 0, "charlie" -> 0) }

// [State 1] { balances: Map("alice" -> 0, "bob" -> 0, "charlie" -> 53) }

// [State 2] { balances: Map("alice" -> 91, "bob" -> 0, "charlie" -> 53) }

// [State 3] { balances: Map("alice" -> 91, "bob" -> 10, "charlie" -> 53) }

// [State 4] { balances: Map("alice" -> 91, "bob" -> 100, "charlie" -> 53) }

// [State 5] { balances: Map("alice" -> 91, "bob" -> 100, "charlie" -> 83) }

// [State 6] { balances: Map("alice" -> 91, "bob" -> 89, "charlie" -> 83) }

// [State 7] { balances: Map("alice" -> 64, "bob" -> 89, "charlie" -> 83) }

// [State 8] { balances: Map("alice" -> 64, "bob" -> 146, "charlie" -> 83) }

// [State 9] { balances: Map("alice" -> 64, "bob" -> 146, "charlie" -> 177) }

// [State 10] { balances: Map("alice" -> 98, "bob" -> 146, "charlie" -> 177) }

// [State 11] { balances: Map("alice" -> 110, "bob" -> 146, "charlie" -> 177) }

// [State 12] { balances: Map("alice" -> 110, "bob" -> 81, "charlie" -> 177) }

// [State 13] { balances: Map("alice" -> 167, "bob" -> 81, "charlie" -> 177) }

// [State 14] { balances: Map("alice" -> 182, "bob" -> 81, "charlie" -> 177) }

// [State 15] { balances: Map("alice" -> 188, "bob" -> 81, "charlie" -> 177) }

// [State 16] { balances: Map("alice" -> 148, "bob" -> 81, "charlie" -> 177) }

// [State 17] { balances: Map("alice" -> 148, "bob" -> 148, "charlie" -> 177) }

// [State 18] { balances: Map("alice" -> 156, "bob" -> 148, "charlie" -> 177) }

// [State 19] { balances: Map("alice" -> 156, "bob" -> 148, "charlie" -> 184) }

// [State 20] { balances: Map("alice" -> 156, "bob" -> 243, "charlie" -> 184) }

// [ok] No violation found (1268ms at 7886 traces/second).
// Trace length statistics: max=21, min=21, average=21.00
// You may increase --max-samples and --max-steps.
// Use --verbosity to produce more (or less) output.
// Use --seed=0xd5a1618277f089dd --backend=rust to reproduce.


// >>> MODEL CHECKING VERIFY WITH SERVER EXAMPLE

// PS ...\formal_verification\versions\00\bank> cmd /c verify.cmd bank.qnt no_negatives

// Starting Apalache server on port 8822...
// Running verification for "bank.qnt" with invariant "no_negatives"...
// [ok] No violation found (11239ms).
// You may increase --max-steps.
// Use --verbosity to produce more (or less) output.
// Auto-closing Apalache server on port 8822...



module bank {
    /// A state variable to store the balance of each account
    var balances: str -> int
    
    pure val ADDRESSES = Set("alice", "bob", "charlie")
    
    action deposit(account, amount) = {
        // Increment balance of account by amount
        balances' = balances.setBy(account, curr => curr + amount)
    }
 
//  action withdraw(account, amount) = {
//      // Decrement balance of account by amount
//      balances' = balances.setBy(account, curr => curr - amount)
//  }

    action withdraw(account, amount) = all { // <- all of the following need to hold
        // A precondition, there should be enough to withdraw
        balances.get(account) >= amount,
        // Decrement balance of account by amount
        balances' = balances.setBy(account, curr => curr - amount),
    }
 
    action init = {
        // At the initial state, all balances are zero
        balances' = ADDRESSES.mapBy(_ => 0)
    }
    
    action step = {
        // Non-deterministically pick an address and an amount
        nondet account = ADDRESSES.oneOf()
        nondet amount = 1.to(100).oneOf()
        // Non-deterministically choose to either deposit or withdraw
        any {
        deposit(account, amount),
        withdraw(account, amount),
        }
    }
 
    /// An invariant stating that all accounts should have a non-negative balance
    val no_negatives = ADDRESSES.forall(addr => balances.get(addr) >= 0)
}