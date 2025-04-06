module challenge_1::cat_object {
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use std::string::String;

    // Challenge: make this struct transferable
    public struct Cat has key, store {
        id: UID,
        // Challenge: make the `name` and `color` fields a String type instead of vector<u8>
        name: String,
        color: String
    }

    // Challenge: make this function return the object instead of transfering it
    public fun new(name: String, color: String, ctx: &mut TxContext): Cat {
        Cat {
            id: object::new(ctx),
            name,
            color
        }
    }

    public fun tchau(cat: Cat) {
        // Challenge: denote that the cat_name and cat_color variables are not going to be used at all in this block
        let Cat {id, name: _cat_name, color: _cat_color } = cat;
        object::delete(id);
    }

    // Challenge: the cat is here is being returned to the caller.
    // Delete the line that transfers the cat back and fix the code.
    // The resulting code should only have one line, the line that changes the color.
    public fun paint(mut cat: Cat, new_color: String, _ctx: &mut TxContext): Cat {
        cat.color = new_color;
        cat
    }
}
