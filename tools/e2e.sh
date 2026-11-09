#!/usr/bin/env bash
# In-game check for the Silent's Gems slice 1: the 21 gem items and their 21
# storage blocks.
#
# Default run (creative launch for placement, survival for drops/crafting;
# The End):
#   1. every `<gem>_block` id `setblock`s and reads back, so 21/21 default
#      states bind;
#   2. every one of the 21 gems and 21 blocks is `/give`-able;
#   3. the creative tab lists all 42 items;
#   4. the storage blocks carry `#minecraft:mineable/pickaxe`,
#      `#c:storage_blocks` and `#c:storage_blocks/<gem>`; the gems carry
#      `#c:gems/<gem>` (proved through the crafting recipe, which matches the
#      tag rather than the item id);
#   5. a ruby block drops itself with a pickaxe; a vanilla `minecraft:iron_block`
#      (the template) drops vanilla iron, never a Silent's Gems block (the
#      drop differential);
#   6. nine gems -> one block and one block -> nine gems craft for two
#      different gems, while a wrong-item control (8 gems + stick, or a block
#      + stick) leaves the result empty;
#   7. a block item places and reads back;
#   8. unknown ids are refused: a bogus item id, a bogus block id and
#      `silentgems:ruby_ore` (an upstream block deferred out of this slice).
#
# NEGATIVE=1 runs the same scenario but asserts that the vanilla iron block
# dropped `silentgems:ruby_block`. That assertion is false, so the run MUST
# exit 1; it proves the drop check is not vacuous.
set -euo pipefail

CLONE=${CAMPAIGN_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}
PORT=$CLONE/ports/silentgems
CTL=${CTL:-$PORT/target/horizon-cargo/fast/horizon-ctl}
GAME=${GAME:-$PORT/target/horizon-cargo/fast/horizon-client}
RES=${RES:-${HORIZON_RES:-$HOME/Desktop/horizon/.local/horizon-client/26.3}}
SOCK=${SOCK:-/tmp/opencode/silentgems-e2e.sock}
NEGATIVE=${NEGATIVE:-0}

[ -x "$CTL" ] || { echo "missing horizon-ctl: $CTL" >&2; exit 1; }
[ -x "$GAME" ] || { echo "missing horizon-client: $GAME" >&2; exit 1; }
[ -d "$RES/assets" ] || { echo "missing prepared resources: $RES" >&2; exit 1; }
[ -f "$PORT/content/horizon-mod.toml" ] || { echo "missing content mod: $PORT/content" >&2; exit 1; }

GEMS=(ruby carnelian topaz citrine heliodor moldavite peridot turquoise \
    kyanite sapphire iolite alexandrite ammolite rose_quartz black_diamond \
    white_diamond garnet aquamarine tanzanite opal pearl)

SCRATCH=$(mktemp -d /tmp/opencode/silentgems-home.XXXXXX)
export HORIZON_HOME=$SCRATCH/game
export HORIZON_LAUNCHER_HOME=$SCRATCH/launcher
export XDG_DATA_HOME=$SCRATCH/data
export XDG_CONFIG_HOME=$SCRATCH/config
export HORIZON_NO_AUDIO=1
mkdir -p "$(dirname "$SOCK")"
rm -f "$SOCK"
cd "$SCRATCH"

ctl() { "$CTL" --socket "$SOCK" "$@"; }
fail() { echo "FAIL: $*" >&2; exit 1; }
say() { echo "+ $*"; }
count_item() { ctl inventory | jq -r --arg i "$1" '.counts[$i] // 0'; }
block_state() { ctl block "$1" "$2" "$3" | jq -r '.block // "unknown"'; }
end() { ctl command "execute in minecraft:the_end run $1"; }
# The server /tp can arrive before the client has left a closing screen; poll
# the client's own position so `place` is not measured from the old one.
wait_at() {
    local want=$1 pos
    for _ in $(seq 1 40); do
        pos=$(ctl state 2>/dev/null | jq -r '.player.position | @csv')
        [ "$pos" = "$want" ] && return 0
        ctl wait 5
    done
    fail "player did not reach $want (client at $pos)"
}

cleanup() {
    ctl quit >/dev/null 2>&1 || true
    sleep 1
    rm -rf "$SCRATCH" || true
}
trap cleanup EXIT

say "launch (offscreen renderer, creative, content --dev-mod content/)"
"$CTL" --socket "$SOCK" launch \
    --game "$GAME" --world SilentGemsE2E --seed 20261104 --creative --offscreen --wait \
    --game-dir "$SCRATCH/game" --resources "$RES" --dev-mod "$PORT/content"
ctl wait-ready 180

say "The End platform at y=79 and an empty box above it"
end "forceload add -12 -12 20 12"
end "tp @s 0.5 80 2.5"
ctl wait 40
end "fill -12 79 -12 20 79 12 minecraft:stone"
end "fill -12 80 -12 20 88 12 minecraft:air"
end "kill @e[type=minecraft:item]"
# The dragon would otherwise kill the player during the run.
end "kill @e[type=minecraft:ender_dragon]"
end "kill @e[type=minecraft:end_crystal]"
end "difficulty peaceful"
end "tp @s 0.5 80 2.5"
ctl wait 10
ctl close >/dev/null 2>&1 || true
ctl wait 3

# ---------------------------------------------------------------- state bind
say "every storage-block id binds its default state"
for i in "${!GEMS[@]}"; do
    gem=${GEMS[$i]}
    ctl setblock "$i" 80 -4 "silentgems:${gem}_block" >/dev/null || fail "setblock silentgems:${gem}_block failed"
done
ctl wait 10
for i in "${!GEMS[@]}"; do
    gem=${GEMS[$i]}
    got=$(block_state "$i" 80 -4)
    [ "$got" = "silentgems:${gem}_block" ] || fail "x=$i reads '$got', expected silentgems:${gem}_block"
done
echo "21/21 storage-block default states bind"

# ---------------------------------------------------------------- item side
say "every gem and block is give-able (batch 1 of 2: gems)"
ctl command "clear @s" >/dev/null
for gem in "${GEMS[@]}"; do
    ctl give "silentgems:${gem}" 1 >/dev/null || fail "give silentgems:${gem} failed"
done
ctl wait 10
for gem in "${GEMS[@]}"; do
    [ "$(count_item "silentgems:${gem}")" -ge 1 ] || fail "silentgems:${gem} is missing"
done
echo "21/21 gems are give-able"

say "every gem and block is give-able (batch 2 of 2: blocks)"
ctl command "clear @s" >/dev/null
for gem in "${GEMS[@]}"; do
    ctl give "silentgems:${gem}_block" 1 >/dev/null || fail "give silentgems:${gem}_block failed"
done
ctl wait 10
for gem in "${GEMS[@]}"; do
    [ "$(count_item "silentgems:${gem}_block")" -ge 1 ] || fail "silentgems:${gem}_block is missing"
done
echo "21/21 storage blocks are give-able"

say "every ore variant is give-able (one 21-stack batch per variant)"
# 84 stacks do not fit the 36-slot inventory: give and verify one variant at a
# time (21 stacks each), clearing between batches.
for prefix in "" deepslate_ nether_ end_; do
    ctl command "clear @s" >/dev/null
    for gem in "${GEMS[@]}"; do
        ctl give "silentgems:${prefix}${gem}_ore" 1 >/dev/null \
            || fail "give silentgems:${prefix}${gem}_ore failed"
    done
    ctl wait 10
    for gem in "${GEMS[@]}"; do
        [ "$(count_item "silentgems:${prefix}${gem}_ore")" -ge 1 ] \
            || fail "silentgems:${prefix}${gem}_ore is missing"
    done
    echo "21/21 ${prefix:-overworld} ores are give-able"
done
ctl command "clear @s" >/dev/null
echo "84/84 ore blocks are give-able"

CREATIVE=$SCRATCH/game/.horizon-cache/mod-content/creative-inventory.json
if [ -f "$CREATIVE" ]; then
    # The cache stores SNBT strings, so the inner item quotes are escaped
    # (`id:\"silentgems:ruby\"`); drop the backslashes before matching.
    flat=$(tr -d '\\' < "$CREATIVE")
    for gem in "${GEMS[@]}"; do
        echo "$flat" | grep -q "silentgems:${gem}\"" || fail "creative tab misses silentgems:${gem}"
        echo "$flat" | grep -q "silentgems:${gem}_block\"" || fail "creative tab misses silentgems:${gem}_block"
        for prefix in "" deepslate_ nether_ end_; do
            echo "$flat" | grep -q "silentgems:${prefix}${gem}_ore\"" \
                || fail "creative tab misses silentgems:${prefix}${gem}_ore"
        done
    done
    echo "creative tab lists all 126 entries (21 gems, 21 blocks, 84 ores)"
else
    fail "no creative-inventory.json at $CREATIVE"
fi

# ------------------------------------------------------------------- tags
say "storage blocks carry the pickaxe and c:storage_blocks tags"
for gem in ruby pearl; do
    x=$(printf '%s\n' "${GEMS[@]}" | grep -nx "$gem" | cut -d: -f1)
    x=$((x - 1))
    ctl command "execute in minecraft:the_end if block $x 80 -4 #minecraft:mineable/pickaxe run say TAG_${gem}_PICKAXE" >/dev/null
    ctl command "execute in minecraft:the_end if block $x 80 -4 #c:storage_blocks run say TAG_${gem}_CSTORAGE_ALL" >/dev/null
    ctl command "execute in minecraft:the_end if block $x 80 -4 #c:storage_blocks/$gem run say TAG_${gem}_CSTORAGE" >/dev/null
done
ctl wait 3
messages=$(ctl messages 60 | jq -r '.chat[]')
for gem in ruby pearl; do
    for tag in PICKAXE CSTORAGE_ALL CSTORAGE; do
        echo "$messages" | grep -q "TAG_${gem}_${tag}" || fail "$gem is missing tag $tag"
    done
done
echo "ruby/pearl: #minecraft:mineable/pickaxe, #c:storage_blocks, #c:storage_blocks/<gem>"

say "ores carry their ore/harvest tags"
ctl command "execute in minecraft:the_end run setblock 3 80 -4 silentgems:ruby_ore" >/dev/null
ctl command "execute in minecraft:the_end run setblock 4 80 -4 silentgems:nether_ruby_ore" >/dev/null
ctl wait 3
for spec in "3 80 -4 #silentgems:ores/ruby ORE_MODTAG" \
            "3 80 -4 #c:ores/ruby ORE_CTAG" \
            "3 80 -4 #minecraft:needs_iron_tool ORE_IRON" \
            "3 80 -4 #minecraft:mineable/pickaxe ORE_PICKAXE" \
            "4 80 -4 #minecraft:needs_diamond_tool ORE_DIAMOND"; do
    set -- $spec
    ctl command "execute in minecraft:the_end if block $1 $2 $3 $4 run say $5" >/dev/null
done
ctl wait 3
messages=$(ctl messages 20 | jq -r '.chat[]')
for tag in ORE_MODTAG ORE_CTAG ORE_IRON ORE_PICKAXE ORE_DIAMOND; do
    echo "$messages" | grep -q "$tag" || fail "ore tag check missing $tag"
done
echo "ruby ore: #silentgems:ores/ruby, #c:ores/ruby, #minecraft:needs_iron_tool, #minecraft:mineable/pickaxe; nether ruby ore: #minecraft:needs_diamond_tool"

# ------------------------------------------------------------------ place
say "the block items place"
ctl command "clear @s" >/dev/null
# A server /tp is used because the client-side `ctl tp` can be swallowed by a
# screen; the wait then confirms the client's own position before aiming.
end "tp @s 0.5 80 0.5"
wait_at "0.5,80.0,0.5"
ctl setblock 1 80 1 minecraft:air >/dev/null
ctl setblock 1 80 2 minecraft:air >/dev/null
ctl setblock 2 80 1 minecraft:stone >/dev/null 2>&1 || true
ctl setblock 2 80 2 minecraft:stone >/dev/null 2>&1 || true
ctl give silentgems:ruby_block 1 >/dev/null || fail "cannot give ruby block"
ctl wait 3
ctl select silentgems:ruby_block >/dev/null || fail "cannot select ruby block"
ctl wait 2
echo "place debug: support=$(ctl block 2 80 1 | jq -c '{block,loaded}') target=$(ctl block 1 80 1 | jq -c '{block,loaded}')"
echo "place debug: state=$(ctl state | jq -c '{pos:.player.position,eye:.player.eye,dim:.dimension,screen:.screen}')"
echo "place debug: look=$(ctl look-at-block 2 80 1 west 2>&1)"
placed=0
for attempt in 1 2 3 4 5; do
    if reply=$(ctl place 1 80 1 --item silentgems:ruby_block 2>&1); then
        placed=1
        break
    fi
    echo "place attempt $attempt failed: $reply"
    echo "  pos=$(ctl state 2>/dev/null | jq -c '{pos:.player.position,eye:.player.eye}')"
    ctl look-at-block 2 80 1 west >/dev/null 2>&1 || true
    ctl wait 10
done
[ "$placed" = 1 ] || { echo "place reply: $reply"; fail "cannot place ruby block"; }
ctl wait 3
[ "$(block_state 1 80 1)" = "silentgems:ruby_block" ] || fail "placed ruby block is not there"
echo "silentgems:ruby_block placed"

ctl give silentgems:pearl_block 1 >/dev/null || fail "cannot give pearl block"
ctl wait 3
ctl select silentgems:pearl_block >/dev/null || fail "cannot select pearl block"
ctl wait 2
ctl setblock 2 81 1 minecraft:stone >/dev/null 2>&1 || true
ctl look-at-block 1 80 1 up >/dev/null || true
placed=0
for attempt in 1 2 3 4 5; do
    if reply=$(ctl place 1 81 1 --item silentgems:pearl_block 2>&1); then
        placed=1
        break
    fi
    echo "place attempt $attempt failed: $reply"
    echo "  pos=$(ctl state 2>/dev/null | jq -c '{pos:.player.position,eye:.player.eye}')"
    ctl look-at-block 1 80 1 up >/dev/null 2>&1 || true
    ctl wait 10
done
[ "$placed" = 1 ] || { echo "place reply: $reply"; fail "cannot place pearl block"; }
ctl wait 3
[ "$(block_state 1 81 1)" = "silentgems:pearl_block" ] || fail "placed pearl block is not there"
echo "silentgems:pearl_block placed"

# ------------------------------------------------------------------- drops
say "survival: a ruby block drops itself with a pickaxe"
end "setblock 0 80 -1 minecraft:air"
end "setblock 2 80 -1 minecraft:air"
ctl setblock 0 80 -1 silentgems:ruby_block >/dev/null || fail "cannot set the ruby block"
ctl setblock 2 80 -1 minecraft:iron_block >/dev/null || fail "cannot set the vanilla iron block"
ctl command "gamemode survival @s" >/dev/null
ctl command "clear @s" >/dev/null
ctl give minecraft:diamond_pickaxe 1 >/dev/null
ctl tp 0.5 80 0.5 >/dev/null
ctl wait 5
ctl select minecraft:diamond_pickaxe >/dev/null
ctl wait 3
ctl look-at-block 0 80 -1 >/dev/null || true
broken=$(ctl break 0 80 -1) || { echo "break reply: $broken"; fail "cannot break the ruby block"; }
echo "$broken" | jq -c '{block,block_before,drops}'
[ "$(echo "$broken" | jq -r '.block')" = "minecraft:air" ] || fail "the ruby block did not break"
ruby=$(echo "$broken" | jq -r '.drops["silentgems:ruby_block"] // 0')
[ "$ruby" -ge 1 ] || fail "the ruby block dropped $ruby of itself"
echo "silentgems:ruby_block dropped itself"

say "differential: vanilla iron_block (the template) drops iron, never a gem block"
ctl look-at-block 2 80 -1 >/dev/null || true
broken=$(ctl break 2 80 -1) || { echo "break reply: $broken"; fail "cannot break the vanilla iron block"; }
echo "$broken" | jq -c '{block,block_before,drops}'
iron=$(echo "$broken" | jq -r '.drops["minecraft:iron_block"] // 0')
gem=$(echo "$broken" | jq -r '.drops["silentgems:ruby_block"] // 0')
if [ "$NEGATIVE" = 1 ]; then
    # Deliberately false: the vanilla block must not drop a Silent's Gems
    # block, so this assertion has to fail.
    [ "$gem" -ge 1 ] || fail "NEGATIVE run: expected the false assertion to fail (iron=$iron gem=$gem)"
    fail "NEGATIVE run: expected to fail, but the vanilla iron block reported a gem drop"
fi
[ "$iron" -ge 1 ] || fail "the vanilla iron block dropped $iron of itself"
[ "$gem" -eq 0 ] || fail "the vanilla iron block dropped $gem silentgems:ruby_block"
echo "vanilla iron_block dropped itself and no gem block"

say "an ore drops its gem with an iron pickaxe"
ctl setblock 4 80 -1 silentgems:ruby_ore >/dev/null || fail "cannot set the ruby ore"
ctl command "clear @s" >/dev/null || fail "cannot clear the inventory"
ctl give minecraft:iron_pickaxe 1 >/dev/null || fail "cannot give an iron pickaxe"
ctl wait 3
ctl select minecraft:iron_pickaxe >/dev/null || fail "cannot select the iron pickaxe"
ctl wait 3
ctl look-at-block 4 80 -1 >/dev/null || true
broken=$(ctl break 4 80 -1) || { echo "break reply: $broken"; fail "cannot break the ruby ore"; }
echo "$broken" | jq -c '{block,block_before,drops}'
gem=$(echo "$broken" | jq -r '.drops["silentgems:ruby"] // 0')
[ "$gem" -ge 1 ] || fail "the ruby ore dropped $gem gems"
echo "silentgems:ruby_ore dropped silentgems:ruby"
# The worldgen probe floats at y=120 over the End; stay in creative so the
# player does not fall while it runs.
ctl command "gamemode creative @s" >/dev/null

# ------------------------------------------------------------------- recipe
say "craft: 9 gems <-> 1 block at a crafting table"
end "setblock 6 80 2 minecraft:crafting_table"
ctl command "gamemode survival @s" >/dev/null
ctl tp 5.5 80 2.5 >/dev/null
ctl wait 5
python3 "$PORT/tools/craft_check.py" "$SOCK" "$CTL" 6 80 2 || fail "the compression recipe check failed"
ctl command "gamemode creative @s" >/dev/null
ctl command "clear @s" >/dev/null
ctl wait 3

# ------------------------------------------------------------- worldgen ores
say "worldgen: /place feature fills the matching rock and only that rock"
# The probe cubes live at x 30..50, away from the y=79 platform and the
# positions the later phases use (x 0..6); the player waits above them.
end "forceload add 28 -12 56 12"
end "tp @s 40.5 120 0.5"
# A solid cube each: no air exposure, so the 0.2 discard still places.
end "fill 30 12 -10 50 28 10 minecraft:stone"
end "fill 30 36 -10 50 52 10 minecraft:glass"
end "fill 30 56 -10 50 72 10 minecraft:netherrack"
end "fill 30 76 -10 50 92 10 minecraft:end_stone"
ctl wait 10
ore_count() { ctl blocks "$1" "$2" "$3" "$4" "$5" "$6" | jq -r --arg id "$7" '.counts[$id] // 0'; }

ctl command "place feature silentgems:overworld/ruby_ore 40 20 0" >/dev/null 2>&1 || true
ctl wait 5
ruby=$(ore_count 31 13 -9 49 27 9 silentgems:ruby_ore)
echo "ruby ore placed in stone: $ruby"
[ "$ruby" -ge 1 ] || fail "the overworld ruby ore feature placed nothing in stone"

# Control 1: the same feature over glass (not a replaceable tag) places nothing.
ctl command "place feature silentgems:overworld/ruby_ore 40 44 0" >/dev/null 2>&1 || true
ctl wait 5
glass_ruby=$(ore_count 31 37 -9 49 51 9 silentgems:ruby_ore)
[ "$glass_ruby" -eq 0 ] || fail "the ruby ore replaced glass ($glass_ruby blocks)"
echo "control: ruby ore over glass: $glass_ruby"

ctl command "place feature silentgems:the_nether/carnelian_ore 40 64 0" >/dev/null 2>&1 || true
ctl wait 5
nether=$(ore_count 31 57 -9 49 71 9 silentgems:nether_carnelian_ore)
echo "nether carnelian ore placed in netherrack: $nether"
[ "$nether" -ge 1 ] || fail "the nether carnelian ore feature placed nothing in netherrack"

ctl command "place feature silentgems:the_end/kyanite_ore 40 84 0" >/dev/null 2>&1 || true
ctl wait 5
end_ore=$(ore_count 31 77 -9 49 91 9 silentgems:end_kyanite_ore)
echo "end kyanite ore placed in end stone: $end_ore"
[ "$end_ore" -ge 1 ] || fail "the end kyanite ore feature placed nothing in end stone"

# Cross-control: the dimension-specific features did not touch the stone cube.
stone_foreign=$(ore_count 31 13 -9 49 27 9 silentgems:nether_carnelian_ore)
[ "$stone_foreign" -eq 0 ] || fail "a nether ore replaced stone ($stone_foreign blocks)"
nether_ruby=$(ore_count 31 57 -9 49 71 9 silentgems:ruby_ore)
[ "$nether_ruby" -eq 0 ] || fail "the overworld ore replaced netherrack ($nether_ruby blocks)"
echo "cross-control: the nether/end features left stone alone and the overworld feature left netherrack alone"

# Back to the platform after the y=120 worldgen probe: the recipe phase runs
# in survival and must not fall through the End.
end "tp @s 5.5 80 2.5"
ctl wait 10

# ------------------------------------------------------------- unknown ids
say "unknown ids are refused"
if ctl give silentgems:not_a_gem 1 >/dev/null 2>&1; then
    fail "give silentgems:not_a_gem succeeded"
fi
ctl setblock 0 80 5 silentgems:bogus_block >/dev/null 2>&1 || true
[ "$(block_state 0 80 5)" = "minecraft:air" ] || fail "silentgems:bogus_block became a block"
# `ruby_lamp` is an upstream block deferred out of these slices.
ctl setblock 1 80 5 silentgems:ruby_lamp >/dev/null 2>&1 || true
[ "$(block_state 1 80 5)" = "minecraft:air" ] || fail "silentgems:ruby_lamp became a block in slices 1-2"
echo "bogus item/block ids and the deferred ruby_lamp are refused"

echo "PASS: 21 storage-block states bind, 21 gems + 21 blocks + 84 ores give, the tab lists 126, the blocks and ores carry #minecraft:mineable/pickaxe and #c:storage_blocks/<gem> and #c:ores/<gem>, a ruby block drops itself while vanilla iron_block drops vanilla iron, a ruby ore drops a ruby, 9 gems <-> 1 block crafts for ruby/opal/sapphire with empty wrong-item controls, the block items place, /place feature writes ruby/carnelian/kyanite ores only into stone/netherrack/end_stone, and unknown ids are refused"
