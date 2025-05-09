module nft_collection::nft {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use std::string::{Self, String};
    use sui::package;
    use sui::display;

    // ====== Errors ======
    const ENotAuthorized: u64 = 0;
    const EInvalidNFTCount: u64 = 1;

    // ====== Constants ======
    const MIN_NFTS: u64 = 3;
    const MAX_NFTS: u64 = 10;

    // ====== Types ======
    /// One-time witness type
    public struct NFT has drop {}

    public struct Collection has key, store {
        id: UID,
        name: String,
        description: String,
        image_url: String
    }

    public struct MintCap has key {
        id: UID
    }

    // ====== Functions ======
    fun init(witness: NFT, ctx: &mut TxContext) {
        let publisher = package::claim(witness, ctx);
        
        // Create basic display without creator field
        let keys = vector[
            string::utf8(b"name"),
            string::utf8(b"description"),
            string::utf8(b"image_url")
        ];

        let values = vector[
            string::utf8(b"{name}"),
            string::utf8(b"{description}"),
            string::utf8(b"{image_url}")
        ];

        let mut display = display::new_with_fields<Collection>(
            &publisher, 
            keys,
            values,
            ctx
        );

        display::update_version(&mut display);

        let mint_cap = MintCap {
            id: object::new(ctx)
        };

        // Transfer objects to sender
        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::public_transfer(display, tx_context::sender(ctx));
        transfer::transfer(mint_cap, tx_context::sender(ctx));
    }

    public entry fun mint_nft(
        cap: &MintCap,
        name: String,
        description: String,
        image_url: String,
        ctx: &mut TxContext
    ) {
        let nft = Collection {
            id: object::new(ctx),
            name,
            description,
            image_url
        };

        transfer::public_transfer(nft, tx_context::sender(ctx));
    }

    // Getters
    public fun name(nft: &Collection): &String {
        &nft.name
    }

    public fun description(nft: &Collection): &String {
        &nft.description
    }

    public fun image_url(nft: &Collection): &String {
        &nft.image_url
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(NFT {}, ctx)
    }
} 