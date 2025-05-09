module nft_collection::escrow {
    // use sui::object::{Self, UID};
    // use sui::transfer;
    // use sui::tx_context::{Self, TxContext};

    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use nft_collection::nft::Collection;

    // ====== Errors ======
    const EWrongAmount: u64 = 0;
    const EWrongOwner: u64 = 1;
    const EEscrowClosed: u64 = 2;

    // ====== Types ======
    public struct Escrow has key {
        id: UID,
        nft: Collection,
        seller: address,
        price: u64,
        is_active: bool
    }

    // ====== Functions ======
    public entry fun create_escrow(
        nft: Collection,
        price: u64,
        ctx: &mut TxContext
    ) {
        let escrow = Escrow {
            id: object::new(ctx),
            nft,
            seller: tx_context::sender(ctx),
            price,
            is_active: true
        };

        transfer::share_object(escrow);
    }

    public entry fun buy_nft(
        escrow: Escrow,
        payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        assert!(escrow.is_active, EEscrowClosed);
        assert!(coin::value(&payment) == escrow.price, EWrongAmount);

        let Escrow { id, nft, seller, price: _, is_active: _ } = escrow;

        // Transfer payment to seller
        transfer::public_transfer(payment, seller);

        // Transfer NFT to buyer
        let buyer = tx_context::sender(ctx);
        transfer::public_transfer(nft, buyer);

        // Delete escrow object
        object::delete(id);
    }

    public entry fun cancel_escrow(
        escrow: Escrow,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(sender == escrow.seller, EWrongOwner);

        let Escrow { id, nft, seller, price: _, is_active: _ } = escrow;

        // Return NFT to seller
        transfer::public_transfer(nft, seller);

        // Delete escrow object
        object::delete(id);
    }

    // ====== View Functions ======
    public fun price(escrow: &Escrow): u64 {
        escrow.price
    }

    public fun seller(escrow: &Escrow): address {
        escrow.seller
    }

    public fun is_active(escrow: &Escrow): bool {
        escrow.is_active
    }
}