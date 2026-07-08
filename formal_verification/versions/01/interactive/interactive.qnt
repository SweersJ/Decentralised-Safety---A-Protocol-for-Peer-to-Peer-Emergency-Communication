module interactive {
    var x: int
    var y: int

    action init = all {
        x' = 0,
        y' = 1
    }

    action step = {
        nondet amount = 1.to(100).oneOf()
        all {
            x' = x + x + amount,
            y' = y + amount,
        }
    }

    val invariant = x == y
}