#!/usr/bin/env python3
"""Craft the Silent's Gems compression recipes in a real crafting table.

Called by tools/e2e.sh with the open game's control socket. Uses the harness's
crafting grid (`ctl screen`: slots 100-108 row-major, result 200), gives the
ingredients, and asserts:

1. nine `silentgems:ruby` (matched through the `#c:gems/ruby` item tag) ->
   one `silentgems:ruby_block` (shaped 3x3), and the crafted stack reaches the
   inventory;
2. eight ruby + one `minecraft:stick` -> an empty result (a deliberately
   unmatched item; a stick is not a gem, so it cannot complete the recipe);
3. nine `silentgems:opal` -> one `silentgems:opal_block` (a second gem, so the
   registry table is exercised rather than one hand-written recipe);
4. one `silentgems:ruby_block` -> nine `silentgems:ruby` (shapeless);
5. one `silentgems:sapphire_block` -> nine `silentgems:sapphire` (a second
   shapeless recipe);
6. one `silentgems:ruby_block` + one stick -> an empty result.

The table is replaced before every case, so a failed/untaken result cannot
leak into the next grid. Exits 1 with the observed result on the first
mismatch.
"""
import json
import subprocess
import sys

RING = [100, 101, 102, 103, 105, 106, 107, 108]
CENTRE = 104
ALL = [100, 101, 102, 103, 104, 105, 106, 107, 108]


def main():
    sock, ctl, x, y, z = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5]

    def run(*args):
        out = subprocess.run([ctl, "--socket", sock, *args], text=True, capture_output=True)
        try:
            return json.loads(out.stdout)
        except json.JSONDecodeError:
            raise SystemExit(f"ctl {' '.join(args)}: {out.stdout}{out.stderr}")

    def wait(ticks=4):
        run("wait", str(ticks))

    def slots():
        screen = run("screen")
        if "slots" not in screen:
            raise SystemExit(f"no menu is open: {screen}")
        return screen["slots"]

    def find(item):
        for slot in slots():
            if slot.get("item") == item:
                return slot["slot"]
        raise SystemExit(f"missing ingredient {item} in the inventory")

    def open_table():
        wait()
        print("debug interact:", run("interact", x, y, z))
        wait(5)

    def result():
        """The result slot's stack, or None: an empty slot has `item: null`."""
        stack = [s for s in slots() if s["slot"] == 200]
        if not stack or not stack[0].get("item"):
            return None
        return stack[0]

    def place(item, mode, targets):
        slot = find(item)
        run("click-slot", str(slot))
        wait(1)
        for target in targets:
            if mode == "right":
                run("click-slot", str(target), "right")
            else:
                run("click-slot", str(target))
            wait(1)
        run("click-slot", str(slot))
        wait(2)

    def setup(items):
        try:
            run("close")
        except SystemExit:
            pass
        wait(5)
        # Replace the table so its block entity, and therefore the crafting
        # grid, is fresh for this case.
        run("setblock", x, y, z, "minecraft:air")
        run("setblock", x, y, z, "minecraft:crafting_table")
        wait(2)
        # The caller's teleport can be swallowed while the inventory screen is
        # still closing (the control `tp` is client-side); a server `/tp`
        # moves the player even then. Y stays an integer.
        print("debug tp:", run("command", f"tp @s {float(x) - 0.5} {y} {float(z) + 0.5}"))
        wait(3)
        run("command", "clear @s")
        for item, count in items:
            run("give", item, str(count))
        wait(3)
        open_table()

    failures = []

    def check(label, items, placements, want_item, want_count):
        setup(items)
        for item, mode, targets in placements:
            place(item, mode, targets)
        got = result()
        print(f"{label} ->", json.dumps(got))
        if not got or got.get("item") != want_item or got.get("count") != want_count:
            failures.append(f"{label}: expected {want_count} {want_item}, got {got}")
            return None
        return got

    def empty_control(label, items, placements):
        setup(items)
        for item, mode, targets in placements:
            place(item, mode, targets)
        got = result()
        print(f"{label} ->", json.dumps(got))
        if got is not None:
            failures.append(f"{label}: control crafted {got['item']}")

    # 1. Nine gems -> one block, with an inventory hand-off.
    setup([("silentgems:ruby", 9)])
    place("silentgems:ruby", "right", [str(slot) for slot in ALL])
    got = result()
    print("9 ruby ->", json.dumps(got))
    if not got or got.get("item") != "silentgems:ruby_block" or got.get("count") != 1:
        failures.append("the ruby compression recipe did not make one block")
    else:
        run("click-slot", "200")
        wait(5)
        run("click-slot", "9")
        wait(3)
        made = run("inventory")["counts"].get("silentgems:ruby_block", 0)
        if made < 1:
            failures.append(f"the crafted ruby block reached the inventory as {made}, not 1")

    # 2. The compression recipe's deliberately unmatched control.
    empty_control(
        "8 ruby + stick",
        [("silentgems:ruby", 8), ("minecraft:stick", 1)],
        [
            ("silentgems:ruby", "right", [str(slot) for slot in RING]),
            ("minecraft:stick", "right", [str(CENTRE)]),
        ],
    )

    # 3. A second gem, so the whole table (not one recipe) is exercised.
    check(
        "9 opal",
        [("silentgems:opal", 9)],
        [("silentgems:opal", "right", [str(slot) for slot in ALL])],
        "silentgems:opal_block",
        1,
    )

    # 4. One block -> nine gems (shapeless).
    check(
        "1 ruby block",
        [("silentgems:ruby_block", 1)],
        [("silentgems:ruby_block", "right", ["100"])],
        "silentgems:ruby",
        9,
    )

    # 5. A second gem's decompression.
    check(
        "1 sapphire block",
        [("silentgems:sapphire_block", 1)],
        [("silentgems:sapphire_block", "right", ["100"])],
        "silentgems:sapphire",
        9,
    )

    # 6. The decompression recipe's control: an extra item must not match.
    empty_control(
        "1 ruby block + stick",
        [("silentgems:ruby_block", 1), ("minecraft:stick", 1)],
        [
            ("silentgems:ruby_block", "right", ["100"]),
            ("minecraft:stick", "right", ["101"]),
        ],
    )

    run("close")
    wait(3)
    if failures:
        for failure in failures:
            print(f"FAIL: {failure}", file=sys.stderr)
        raise SystemExit(1)
    print(
        "recipe PASS: 9 gems -> 1 block and 1 block -> 9 gems craft for two "
        "different gems, and the stick controls leave the result empty"
    )


if __name__ == "__main__":
    main()
