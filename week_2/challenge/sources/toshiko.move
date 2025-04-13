module contract::toshiko;

use sui::balance::{Self, Balance};
use sui::url::{Self, Url};
use sui::coin::{Self, Coin, TreasuryCap};
use sui::sui::SUI;

public struct TOSHIKO has drop {}

const TOKEN_SUPPLY: u64 = 1_000_000_000;

// Error codes
const ECoinTooPoor: u64 = 0;

public struct SwapPool has key, store {
    id: UID,
    coins: Balance<TOSHIKO>,
    sui: Balance<SUI>,
    fees: Balance<SUI>,
    treasury_cap: TreasuryCap<TOSHIKO>,
    rate: u64,
    fee_rate: u64,
    max_supply: u64
}

fun init(otw: TOSHIKO, ctx: &mut TxContext) {
    let decimals: u8 = 9;
    let symbol: vector<u8> = b"TOSHIKO";
    let name: vector<u8> = b"TOSHIKO";
    let description: vector<u8> = b"Personal project coin";
    let (treasury_cap, metadata) = coin::create_currency<TOSHIKO>(
        otw,
        decimals,
        symbol,
        name,
        description,
        option::some<Url>(url::new_unsafe_from_bytes(b"https://i.ibb.co/cSFwWPcT/a8906a95-bf84-40d4-9cbd-62c08b5f1560.png")),
        ctx
    );
    let pool = SwapPool{
        id: object::new(ctx),
        coins: balance::zero<TOSHIKO>(),
        treasury_cap,
        sui: balance::zero<SUI>(),
        fees: balance::zero<SUI>(),
        rate: 2,
        fee_rate: 100,
        max_supply: TOKEN_SUPPLY
    };

    transfer::public_transfer(pool, ctx.sender());
    transfer::public_freeze_object(metadata); // Immutable. If there metadata change is needed we will need to create new metadata.
}


public fun exchange_for_sui(pool: &mut SwapPool, mut coin: Coin<SUI>, ctx: &mut TxContext): Coin<TOSHIKO> {
    assert!(coin.value() > 100, ECoinTooPoor);

    let fee = coin.value() * pool.fee_rate / 10000;
    let fee_coin = coin.split(fee, ctx);
    pool.fees.join(fee_coin.into_balance());

    let amount_sui = coin.value();
    pool.sui.join(coin.into_balance());

    let amount_coin = amount_sui * pool.rate;
    pool.treasury_cap.mint(amount_coin, ctx)
}

public fun burn(pool: &mut SwapPool, coin: Coin<TOSHIKO>, ctx: &mut TxContext): Coin<SUI> {
    let amount = pool.treasury_cap.burn(coin);
    let return_amount = amount / pool.rate;
    let mut return_balance = pool.sui.split(return_amount);

    // taking the fee
    let fee_balance = return_balance.split(return_amount * pool.fee_rate / 10000);
    pool.fees.join(fee_balance);
    
    return_balance.into_coin(ctx)
}