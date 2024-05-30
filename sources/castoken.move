
/// Module: token
module wecastle::castoken {
    use sui::coin::{Coin, Self, TreasuryCap};
    use sui::tx_context::{TxContext, Self};
    use sui::object::{UID};
    use sui::transfer;
    use sui::url::{Self, Url};

    public struct CASTOKEN has drop {}

    fun init(otw: CASTOKEN, ctx: &mut TxContext) {
        let url = url::new_unsafe_from_bytes(b"https://scontent.xx.fbcdn.net/v/t1.15752-9/442476713_774177418029712_8861215484197828541_n.png?stp=dst-png_s206x206&_nc_cat=104&ccb=1-7&_nc_sid=5f2048&_nc_ohc=_xduWxj7h7wQ7kNvgEhywDV&_nc_ad=z-m&_nc_cid=0&_nc_ht=scontent.xx&oh=03_Q7cD1QGumH0dXHE29BxIyU39tTMK93U8e5ao1oQHx0lUHHzDhA&oe=667FB886");
        let (treasury_cap, metadata) = coin::create_currency<CASTOKEN>(
            otw,
            6,                // decimals
            b"CAS",           // symbol
            b"CASTOKEN",       // name
            b"Coin for wecatle game", // description
            option::some<Url>(url),   // icon url
            ctx
        );

        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(metadata);
    }

    public fun mint(treasury_cap: &mut TreasuryCap<CASTOKEN>, amount: u64, ctx: &mut TxContext): Coin<CASTOKEN> {
        // let coin = coin::mint(treasury_cap, amount, ctx);
        // transfer::public_transfer(coin, receipent);
        coin::mint(treasury_cap, amount, ctx)
    }

}


