module nft_collection::airdrop {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use sui::table::{Self, Table};
    use nft_collection::nft::Collection;

    // ====== Errors ======
    const ENotAuthorized: u64 = 0;
    const EAlreadyClaimed: u64 = 1;
    const EInsufficientFunds: u64 = 2;

    // ====== Types ======
    public struct AirdropPool has key {
        id: UID,
        admin: address,
        amount_per_nft: u64,
        balance: Balance<SUI>,
        claimed: Table<address, bool>
    }

    // ====== Functions ======
    public entry fun create_pool(
        amount_per_nft: u64,
        initial_balance: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let pool = AirdropPool {
            id: object::new(ctx),
            admin: tx_context::sender(ctx),
            amount_per_nft,
            balance: coin::into_balance(initial_balance),
            claimed: table::new(ctx)
        };

        transfer::share_object(pool);
    }

    public entry fun claim_airdrop(
        pool: &mut AirdropPool,
        nft_owner: address,
        ctx: &mut TxContext
    ) {
        let claimer = tx_context::sender(ctx);
        assert!(claimer == nft_owner, ENotAuthorized);
        
        // Check if already claimed
        assert!(!table::contains(&pool.claimed, claimer), EAlreadyClaimed);
        
        // Check if pool has enough balance
        assert!(balance::value(&pool.balance) >= pool.amount_per_nft, EInsufficientFunds);

        // Split coins and transfer to claimer
        let payment = coin::from_balance(balance::split(&mut pool.balance, pool.amount_per_nft), ctx);
        transfer::public_transfer(payment, claimer);

        // Mark as claimed
        table::add(&mut pool.claimed, claimer, true);
    }

    public entry fun add_funds(
        pool: &mut AirdropPool,
        additional_funds: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == pool.admin, ENotAuthorized);
        balance::join(&mut pool.balance, coin::into_balance(additional_funds));
    }

    // ====== View Functions ======
    public fun amount_per_nft(pool: &AirdropPool): u64 {
        pool.amount_per_nft
    }

    public fun remaining_balance(pool: &AirdropPool): u64 {
        balance::value(&pool.balance)
    }

    public fun has_claimed(pool: &AirdropPool, user: address): bool {
        table::contains(&pool.claimed, user)
    }
} 