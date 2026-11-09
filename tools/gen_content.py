#!/usr/bin/env python3
"""Generate the Silent's Gems slice-1 content from the upstream checkout.

Slice 1 is the 21 gem items and their 21 storage blocks: block/item
declarations, 26.3 blockstates/models/item definitions, textures, lang, the
compression recipes (9 gems <-> 1 block), self-drop loot tables, the
`c:gems/*` / `c:storage_blocks/*` convention tags, `minecraft:mineable/pickaxe`
and `minecraft:beacon_payment_items`, and one creative tab. The gem list,
colours and rarities are the upstream `Gems` enum
(`src/main/java/net/silentchaos512/gems/setup/Gems.java:38-165`); the English
names are `src/main/resources/assets/silentgems/lang/en_us.json`.

Textures, models and lang are the upstream MIT assets, copied byte for byte
(the port is local-only until the maintainer approves publishing). Data files
are rewritten into the 26.3 formats the pinned Horizon loader reads; every
rewrite is noted in ../notes.md.

Usage:
    python3 tools/gen_content.py --upstream ../_shared/upstream/silentgems
"""

from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path

# (name, English title, RGB, upstream Rarity)
GEMS = [
    ("ruby", "Ruby", 0xE61D1D, "common"),
    ("carnelian", "Carnelian", 0xE04D1D, "uncommon"),
    ("topaz", "Topaz", 0xE6711D, "common"),
    ("citrine", "Citrine", 0xC78B03, "uncommon"),
    ("heliodor", "Heliodor", 0xE6C51D, "common"),
    ("moldavite", "Moldavite", 0xA6D923, "uncommon"),
    ("peridot", "Peridot", 0x29DB18, "common"),
    ("turquoise", "Turquoise", 0x3DF4BD, "rare"),
    ("kyanite", "Kyanite", 0x41C4F3, "rare"),
    ("sapphire", "Sapphire", 0x1D60E5, "common"),
    ("iolite", "Iolite", 0x7543F5, "uncommon"),
    ("alexandrite", "Alexandrite", 0xAB37E5, "uncommon"),
    ("ammolite", "Ammolite", 0xDB2BFF, "rare"),
    ("rose_quartz", "Rose Quartz", 0xFF4EAB, "rare"),
    ("black_diamond", "Black Diamond", 0x5F524C, "epic"),
    ("white_diamond", "White Diamond", 0xD5C1D2, "epic"),
    ("garnet", "Garnet", 0x970000, "uncommon"),
    ("aquamarine", "Aquamarine", 0x6EE9F4, "uncommon"),
    ("tanzanite", "Tanzanite", 0x3D00B9, "uncommon"),
    ("opal", "Opal", 0xDDFFE4, "rare"),
    ("pearl", "Pearl", 0xD3CBBF, "rare"),
]

# `GemsBlocks.register(gem.getName() + "_block", ...)` uses
# `.strength(4, 30).sound(SoundType.METAL)` and never calls
# `requiresCorrectToolForDrops` (`Gems.java:436-443`).
BLOCK_PROPERTIES = {
    "hardness": 4.0,
    "explosion_resistance": 30.0,
    "requires_tool": False,
    # SoundType.METAL; the content schema names a vanilla block for sounds.
    "sounds": "minecraft:iron_block",
}

# The four ore variants `Gems.registerBlocks` declares for every gem:
# (id prefix, English prefix, template, hardness, explosion resistance, sound).
# `strength(x)` sets both destroy time and blast resistance to `x`; the
# deepslate variant is `ofFullCopy(ore).strength(4.5, 3)`. The template supplies
# the harvest tier and the ore's own block behaviour (the loot table is ours).
ORE_VARIANTS = [
    ("", "", "minecraft:lapis_ore", 3.0, 3.0, "minecraft:stone"),
    ("deepslate_", "Deepslate ", "minecraft:deepslate_lapis_ore", 4.5, 3.0, "minecraft:deepslate"),
    ("nether_", "Nether ", "minecraft:nether_quartz_ore", 4.0, 4.0, "minecraft:nether_quartz_ore"),
    ("end_", "End ", "minecraft:lapis_ore", 6.0, 6.0, "minecraft:stone"),
]

# Upstream's generated worldgen directories and the biome tag each dimension's
# features are added to (`GemsWorldGen` / `data/silentgems/neoforge/biome_modifier`).
DIMENSIONS = [
    ("overworld", "#minecraft:is_overworld"),
    ("the_nether", "#minecraft:is_nether"),
    ("the_end", "#minecraft:is_end"),
]


def write(path: Path, value) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2) + "\n")


def copy_png(source: Path, target: Path) -> None:
    if not source.is_file():
        raise SystemExit(f"missing upstream asset: {source}")
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, target)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--upstream", type=Path, required=True)
    args = parser.parse_args()
    upstream = args.upstream.resolve()
    root = Path(__file__).resolve().parents[1]
    content = root / "content"
    assets = content / "assets/silentgems"
    data = content / "data"

    texture_block = upstream / "src/main/resources/assets/silentgems/textures/block"
    texture_item = upstream / "src/main/resources/assets/silentgems/textures/item"
    worldgen = upstream / "src/generated/resources/data/silentgems/worldgen"

    block_ids = []
    gem_ids = []
    lang = {"itemGroup.silentgems": "Silent's Gems"}

    for name, title, _color, rarity in GEMS:
        block = f"{name}_block"
        block_ids.append(f"silentgems:{block}")
        gem_ids.append(f"silentgems:{name}")

        # Declarations: a plain metal-sounding full block and a plain item.
        write(
            data / f"silentgems/horizon/block/{block}.json",
            {
                "template": "minecraft:iron_block",
                "properties": BLOCK_PROPERTIES,
                "item": True,
            },
        )
        write(
            data / f"silentgems/horizon/item/{name}.json",
            {"template": "minecraft:diamond", "rarity": rarity},
        )

        # 26.3 blockstate + cube_all block model + both item definitions.
        write(
            assets / f"blockstates/{block}.json",
            {"variants": {"": {"model": f"silentgems:block/{block}"}}},
        )
        write(
            assets / f"models/block/{block}.json",
            {
                "parent": "minecraft:block/cube_all",
                "textures": {"all": f"silentgems:block/{block}"},
            },
        )
        write(
            assets / f"items/{block}.json",
            {"model": {"type": "minecraft:model", "model": f"silentgems:block/{block}"}},
        )
        write(
            assets / f"models/item/{name}.json",
            {
                "parent": "minecraft:item/generated",
                "textures": {"layer0": f"silentgems:item/{name}"},
            },
        )
        write(
            assets / f"items/{name}.json",
            {"model": {"type": "minecraft:model", "model": f"silentgems:item/{name}"}},
        )

        copy_png(texture_block / f"{block}.png", assets / f"textures/block/{block}.png")
        copy_png(texture_item / f"{name}.png", assets / f"textures/item/{name}.png")

        # Upstream `block.silentgems.gem_block` / `item.silentgems.gem` are
        # printf-style templates; content items resolve a per-id key, so the
        # same text is written out per gem.
        lang[f"block.silentgems.{block}"] = f"Block of {title}"
        lang[f"item.silentgems.{name}"] = title

        # 9 gems -> block (shaped); block -> 9 gems (shapeless).
        write(
            data / f"silentgems/recipe/{block}.json",
            {
                "type": "minecraft:crafting_shaped",
                "category": "building",
                "key": {"#": f"#c:gems/{name}"},
                "pattern": ["###", "###", "###"],
                "result": {"id": f"silentgems:{block}", "count": 1},
            },
        )
        write(
            data / f"silentgems/recipe/{name}_from_block.json",
            {
                "type": "minecraft:crafting_shapeless",
                "ingredients": [f"silentgems:{block}"],
                "result": {"id": f"silentgems:{name}", "count": 9},
            },
        )

        write(
            data / f"silentgems/loot_table/blocks/{block}.json",
            {
                "type": "minecraft:block",
                "pools": [
                    {
                        "condition": {"type": "minecraft:survives_explosion"},
                        "entries": [
                            {"type": "minecraft:item", "name": f"silentgems:{block}"}
                        ],
                        "rolls": 1,
                    }
                ],
                "random_sequence": f"silentgems:blocks/{block}",
            },
        )

    # ---------------------------------------------------------------- ores
    # Slice 2: every gem's four ore variants. The block declarations, loot and
    # tags are the port's; the worldgen configured/placed features are the
    # upstream generated data (MIT, carried over) for the dimensions whose
    # config enables them, normalised to the 26.3 block-state JSON shape.
    ore_ids = []
    ore_iron = []
    ore_diamond = []
    for name, title, _color, _rarity in GEMS:
        for prefix, label, template, hardness, resistance, sound in ORE_VARIANTS:
            ore = f"{prefix}{name}_ore"
            ore_ids.append(f"silentgems:{ore}")
            if prefix in ("", "deepslate_"):
                ore_iron.append(f"silentgems:{ore}")
            else:
                ore_diamond.append(f"silentgems:{ore}")

            # `Gems.registerBlocks`: strength(3) overworld / (4.5, 3) deepslate
            # / (4) nether / (6) end, all `requiresCorrectToolForDrops` and a
            # stone-family sound. The template supplies the harvest tier and
            # the block-entity-free ore behaviour; the loot table is ours.
            write(
                data / f"silentgems/horizon/block/{ore}.json",
                {
                    "template": template,
                    "properties": {
                        "hardness": hardness,
                        "explosion_resistance": resistance,
                        "requires_tool": True,
                        "sounds": sound,
                    },
                    "item": True,
                },
            )
            write(
                assets / f"blockstates/{ore}.json",
                {"variants": {"": {"model": f"silentgems:block/{ore}"}}},
            )
            write(
                assets / f"models/block/{ore}.json",
                {
                    "parent": "minecraft:block/cube_all",
                    "textures": {"all": f"silentgems:block/{ore}"},
                },
            )
            write(
                assets / f"items/{ore}.json",
                {"model": {"type": "minecraft:model", "model": f"silentgems:block/{ore}"}},
            )
            copy_png(texture_block / f"{ore}.png", assets / f"textures/block/{ore}.png")
            # `en_us.json`: `%s Ore` / `Deepslate %s Ore` / `Nether %s Ore` /
            # `End %s Ore` expanded per gem, as the slice-1 names are.
            lang[f"block.silentgems.{ore}"] = f"{label}{title} Ore"

            # Upstream's table is silk-touch -> self, otherwise one gem with
            # fortune `ore_drops` and `explosion_decay`. The pin's loot engine
            # reads `condition` (singular) and has no `match_tool`,
            # `apply_bonus` or `explosion_decay`, so the same intent is
            # expressed in the subset it reads: one gem.
            write(
                data / f"silentgems/loot_table/blocks/{ore}.json",
                {
                    "type": "minecraft:block",
                    "pools": [
                        {
                            "entries": [
                                {"type": "minecraft:item", "name": f"silentgems:{name}"}
                            ],
                            "rolls": 1,
                        }
                    ],
                    "random_sequence": f"silentgems:blocks/{ore}",
                },
            )

    write(assets / "lang/en_us.json", lang)

    # Tags. 26.3 ships no `c:` tags, so the port supplies the convention tags
    # upstream's datagen writes (`GemsBlockTagsProvider.java:33-54`,
    # `GemsItemTagsProvider.java:42-52`).
    write(
        data / "minecraft/tags/block/mineable/pickaxe.json",
        {"values": block_ids + ore_ids},
    )
    write(data / "minecraft/tags/block/needs_iron_tool.json", {"values": ore_iron})
    # Upstream puts the end ores in the NeoForge-only `needs_netherite_tool`
    # tag; 26.3 has no such tag, so they join `needs_diamond_tool` (the
    # nether ores' own tier) instead.
    write(
        data / "minecraft/tags/block/needs_diamond_tool.json",
        {"values": ore_diamond},
    )
    # The copied end/nether features target NeoForge's convention tags; 26.3
    # ships neither, so the port defines them (as it does for `c:gems`).
    write(data / "c/tags/block/netherracks.json", {"values": ["minecraft:netherrack"]})
    write(data / "c/tags/block/end_stones.json", {"values": ["minecraft:end_stone"]})
    for name, _title, _color, _rarity in GEMS:
        ids = [f"silentgems:{prefix}{name}_ore" for prefix, *_ in ORE_VARIANTS]
        write(data / f"silentgems/tags/block/ores/{name}.json", {"values": ids})
        write(data / f"silentgems/tags/item/ores/{name}.json", {"values": ids})
        write(data / f"c/tags/block/ores/{name}.json", {"values": [f"#silentgems:ores/{name}"]})
        write(data / f"c/tags/item/ores/{name}.json", {"values": [f"#silentgems:ores/{name}"]})
    write(
        data / "c/tags/block/ores.json",
        {"values": [f"#c:ores/{name}" for name, *_ in GEMS]},
    )
    write(
        data / "c/tags/item/ores.json",
        {"values": [f"#silentgems:ores/{name}" for name, *_ in GEMS]},
    )

    # Worldgen: upstream's generated configured/placed feature for each
    # dimension, carried over only where its ore config is enabled (count and
    # size above zero). The 26.2 datagen writes `{"Name": id}` states; the
    # pin's block-state codec reads 26.3's string/`{"id": ...}` shape.
    for dimension, biomes in DIMENSIONS:
        features = []
        for name, _title, _color, _rarity in GEMS:
            stem = f"{name}_ore"
            configured = worldgen / "configured_feature" / dimension / f"{stem}.json"
            placed = worldgen / "placed_feature" / dimension / f"{stem}.json"
            if not configured.is_file() or not placed.is_file():
                continue
            spec = json.loads(configured.read_text())
            placement = json.loads(placed.read_text())
            size = spec.get("config", {}).get("size", 0)
            count = next(
                (
                    step.get("count", 0)
                    for step in placement.get("placement", [])
                    if step.get("type") == "minecraft:count"
                ),
                0,
            )
            if size <= 0 or count <= 0:
                continue
            # The pin's feature bundle is the *flattened* config: `type`
            # plus the config's own fields at the top level (that is how
            # `worldgen/features.json` stores vanilla's features), not the
            # data-pack `{"type": ..., "config": {...}}` wrapper 26.2 writes.
            config = spec.pop("config", None)
            if isinstance(config, dict):
                spec.update(config)
            for target in spec.get("targets", []):
                state = target.get("state")
                if isinstance(state, dict) and "Name" in state:
                    target["state"] = state["Name"]
            write(
                data / f"silentgems/worldgen/configured_feature/{dimension}/{stem}.json",
                spec,
            )
            write(
                data / f"silentgems/worldgen/placed_feature/{dimension}/{stem}.json",
                placement,
            )
            features.append(f"silentgems:{dimension}/{stem}")
        write(
            data / f"silentgems/neoforge/biome_modifier/{dimension}_features.json",
            {
                "type": "neoforge:add_features",
                "biomes": biomes,
                "features": features,
                "step": "underground_ores",
            },
        )
    write(
        data / "minecraft/tags/item/beacon_payment_items.json",
        {"values": gem_ids},
    )
    write(data / "c/tags/block/storage_blocks.json", {"values": block_ids})
    write(data / "c/tags/item/storage_blocks.json", {"values": block_ids})
    write(data / "c/tags/item/gems.json", {"values": gem_ids})
    for name, _title, _color, _rarity in GEMS:
        write(
            data / f"c/tags/block/storage_blocks/{name}.json",
            {"values": [f"silentgems:{name}_block"]},
        )
        write(
            data / f"c/tags/item/storage_blocks/{name}.json",
            {"values": [f"silentgems:{name}_block"]},
        )
        write(
            data / f"c/tags/item/gems/{name}.json",
            {"values": [f"silentgems:{name}"]},
        )

    write(
        data / "silentgems/horizon/creative_tab/tab.json",
        {
            "icon": "silentgems:ruby",
            "items": gem_ids + block_ids + ore_ids,
            "title": "itemGroup.silentgems",
        },
    )

    print(
        f"generated {len(GEMS)} gems, {len(GEMS)} storage blocks and "
        f"{len(ore_ids)} ore blocks under {content}"
    )


if __name__ == "__main__":
    main()
