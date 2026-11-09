# Silent's Gems — Horizon port

A port of [Silent's Gems](https://github.com/SilentChaos512/SilentGems) by SilentChaos512 for
Horizon. A content/logic data carry: the 21-gem registry is a test-only Rust module (no injection).

**Status:** the slice below is what works today; the second list is what is
missing. Nothing here claims parity with the original.

## What works

- The 21 gems as items (ruby, carnelian, topaz, citrine, heliodor, moldavite, peridot,
  turquoise, kyanite, sapphire, iolite, alexandrite, ammolite, rose quartz, garnet,
  aquamarine, tanzanite, opal, pearl, black diamond and white diamond) with their own
  textures and rarities.
- Their 21 storage blocks and 42 compression/decompression recipes, with 105 loot tables
  and the mod's own textures, models and language file.
- 84 ore blocks — overworld stone, deepslate, nether and end variants of every gem —
  with their block/item tags.
- Ore worldgen: the mod's own overworld, nether and end ore features, placed features
  and biome modifiers (56 worldgen files).
- A creative tab listing the 126 items of this slice.

## Not yet ported

- Slices 1–2 only: glowrose and other plants, tool/armour sets, lamps, glass, bricks and
  tiles, teleporters, the silver/chaos material line, food and the Silent Gear
  integration are not registered yet.
- An ore always drops one gem: silk touch returns the gem rather than the ore block and
  fortune does not multiply (the pin has no `match_tool`/`apply_bonus`).
- Ore experience is the template's (lapis, 2–5), not upstream's fixed 1–5 provider.
- Gem names use per-gem keys (`item.silentgems.ruby`) rather than upstream's shared `%s`
  template.
- No tooltip shows a gem's colour or harvest tier.

## Install

1. Take `silentgems.hmod` from this repository (or build it below).
2. Put it in the game folder's `horizon-mods` folder — the game folder is the
   one holding `options.txt`.
3. Mods are off by default: enable this one in the game's mod list.

To try it without installing, start the game with
`--dev-mod silentgems.hmod`.

## Build from source

This is a content-only mod: `content/horizon-mod.toml` plus `assets/` and
`data/`.

```sh
cd content && cargo horizon-mod build    # packs content/ into the .hmod and checks it
python3 tools/gen_content.py          # regenerates content/ from the upstream assets
```

`cargo-horizon-mod` comes from the Horizon repository
(`cargo install --git https://github.com/horizon-rust/horizon cargo-horizon-mod`).
`tools/` holds the content generator and the in-game harness. The harness
expects a campaign checkout (`$CAMPAIGN_ROOT`) with the prepared 26.3 resources
(`$HORIZON_RES`, default `~/Desktop/horizon/.local/horizon-client/26.3`).

## Compatibility

- Horizon `1d63e0a` (see `compatibility.json` for the exact revision this
  artifact was built against).
- horizon-mixins `5a64af93`, schema 6.
- Minecraft: Java Edition 26.3.

## Credits

Silent's Gems 5.2.0 by SilentChaos512 — <https://github.com/SilentChaos512/SilentGems>.
The original copyright and licence notices are kept in
[LICENSE](LICENSE); [LICENSE-NOTICE.md](LICENSE-NOTICE.md) records where each
was read from.

This is an unofficial port: Horizon is not affiliated with the original author.

## Licence

MIT — see [LICENSE](LICENSE).

## Contributing

The "Not yet ported" list is the gap list; an issue or a pull request that
closes one item is welcome. Please keep the original notices and say which
slice you are working on.
