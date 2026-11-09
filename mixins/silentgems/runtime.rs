// Silent's Gems for Horizon — the gem registry (pure).
//
// Ported from Silent's Gems 5.2.0 (SilentChaos512/SilentGems, MIT) for
// Minecraft Java 26.2 NeoForge; ATM10 ships 5.1.3 for 1.21.1 and the gem set
// is unchanged (5.1.2 added the last five gems). Slice 1 is content-only: the
// items and storage blocks are declared in ../content, and this model is the
// single place the 21 gem ids, colours, rarities and id shapes are spelled out
// (`setup/Gems.java:38-165`).
//
// The whole module is test-only: the injected copy is empty in a normal game
// build and adds no dead code. There is no gameplay hook to fake.

#[cfg(test)]
mod tests {
    /// The upstream `net.minecraft.world.item.Rarity` of a gem item.
    #[derive(Clone, Copy, Debug, PartialEq, Eq)]
    pub enum Rarity {
        Common,
        Uncommon,
        Rare,
        Epic,
    }

    /// One Silent's Gems gem and the values its declarations use.
    #[derive(Clone, Copy, Debug, PartialEq, Eq)]
    pub struct Gem {
        /// The serialized name used in item, block and tag ids.
        pub name: &'static str,
        /// The English display name from `gem.silentgems.<name>`.
        pub title: &'static str,
        /// The RGB value from the upstream `Gems` enum constant.
        pub color: u32,
        /// The item rarity upstream passes to `Item.Properties.rarity`.
        pub rarity: Rarity,
    }

    /// How many gems a storage block is made from (`compressionRecipes`).
    pub const GEMS_PER_BLOCK: u32 = 9;

    /// The 21 gems, in upstream enum order.
    pub const GEMS: &[Gem] = &[
        Gem {
            name: "ruby",
            title: "Ruby",
            color: 0xE6_1D_1D,
            rarity: Rarity::Common,
        },
        Gem {
            name: "carnelian",
            title: "Carnelian",
            color: 0xE0_4D_1D,
            rarity: Rarity::Uncommon,
        },
        Gem {
            name: "topaz",
            title: "Topaz",
            color: 0xE6_71_1D,
            rarity: Rarity::Common,
        },
        Gem {
            name: "citrine",
            title: "Citrine",
            color: 0xC7_8B_03,
            rarity: Rarity::Uncommon,
        },
        Gem {
            name: "heliodor",
            title: "Heliodor",
            color: 0xE6_C5_1D,
            rarity: Rarity::Common,
        },
        Gem {
            name: "moldavite",
            title: "Moldavite",
            color: 0xA6_D9_23,
            rarity: Rarity::Uncommon,
        },
        Gem {
            name: "peridot",
            title: "Peridot",
            color: 0x29_DB_18,
            rarity: Rarity::Common,
        },
        Gem {
            name: "turquoise",
            title: "Turquoise",
            color: 0x3D_F4_BD,
            rarity: Rarity::Rare,
        },
        Gem {
            name: "kyanite",
            title: "Kyanite",
            color: 0x41_C4_F3,
            rarity: Rarity::Rare,
        },
        Gem {
            name: "sapphire",
            title: "Sapphire",
            color: 0x1D_60_E5,
            rarity: Rarity::Common,
        },
        Gem {
            name: "iolite",
            title: "Iolite",
            color: 0x75_43_F5,
            rarity: Rarity::Uncommon,
        },
        Gem {
            name: "alexandrite",
            title: "Alexandrite",
            color: 0xAB_37_E5,
            rarity: Rarity::Uncommon,
        },
        Gem {
            name: "ammolite",
            title: "Ammolite",
            color: 0xDB_2B_FF,
            rarity: Rarity::Rare,
        },
        Gem {
            name: "rose_quartz",
            title: "Rose Quartz",
            color: 0xFF_4E_AB,
            rarity: Rarity::Rare,
        },
        Gem {
            name: "black_diamond",
            title: "Black Diamond",
            color: 0x5F_52_4C,
            rarity: Rarity::Epic,
        },
        Gem {
            name: "white_diamond",
            title: "White Diamond",
            color: 0xD5_C1_D2,
            rarity: Rarity::Epic,
        },
        Gem {
            name: "garnet",
            title: "Garnet",
            color: 0x97_00_00,
            rarity: Rarity::Uncommon,
        },
        Gem {
            name: "aquamarine",
            title: "Aquamarine",
            color: 0x6E_E9_F4,
            rarity: Rarity::Uncommon,
        },
        Gem {
            name: "tanzanite",
            title: "Tanzanite",
            color: 0x3D_00_B9,
            rarity: Rarity::Uncommon,
        },
        Gem {
            name: "opal",
            title: "Opal",
            color: 0xDD_FF_E4,
            rarity: Rarity::Rare,
        },
        Gem {
            name: "pearl",
            title: "Pearl",
            color: 0xD3_CB_BF,
            rarity: Rarity::Rare,
        },
    ];

    impl Gem {
        /// The gem with this serialized name, if it is a Silent's Gems gem.
        pub fn from_name(name: &str) -> Option<&'static Gem> {
            GEMS.iter().find(|gem| gem.name == name)
        }

        /// The gem's 0-based position in the upstream enum.
        pub fn index(self) -> Option<usize> {
            GEMS.iter().position(|gem| *gem == self)
        }

        /// The gem item id, `silentgems:<name>`.
        pub fn item_id(self) -> String {
            format!("silentgems:{}", self.name)
        }

        /// The storage block id, `silentgems:<name>_block`.
        pub fn block_id(self) -> String {
            format!("silentgems:{}_block", self.name)
        }

        /// The convention item tag the recipes use, `c:gems/<name>`.
        pub fn gem_tag(self) -> String {
            format!("c:gems/{}", self.name)
        }

        /// The convention storage-block tag, `c:storage_blocks/<name>`.
        pub fn storage_block_tag(self) -> String {
            format!("c:storage_blocks/{}", self.name)
        }

        /// How many gem items one storage block compresses.
        pub fn gems_per_block(self) -> u32 {
            GEMS_PER_BLOCK
        }
    }

    /// The exact upstream English names, in `Gems.java` order.
    const NAMES: [&str; 21] = [
        "ruby",
        "carnelian",
        "topaz",
        "citrine",
        "heliodor",
        "moldavite",
        "peridot",
        "turquoise",
        "kyanite",
        "sapphire",
        "iolite",
        "alexandrite",
        "ammolite",
        "rose_quartz",
        "black_diamond",
        "white_diamond",
        "garnet",
        "aquamarine",
        "tanzanite",
        "opal",
        "pearl",
    ];

    /// The exact upstream RGB constants (`Gems.java:39-165`).
    const COLOURS: [(&str, u32); 21] = [
        ("ruby", 0xE6_1D_1D),
        ("carnelian", 0xE0_4D_1D),
        ("topaz", 0xE6_71_1D),
        ("citrine", 0xC7_8B_03),
        ("heliodor", 0xE6_C5_1D),
        ("moldavite", 0xA6_D9_23),
        ("peridot", 0x29_DB_18),
        ("turquoise", 0x3D_F4_BD),
        ("kyanite", 0x41_C4_F3),
        ("sapphire", 0x1D_60_E5),
        ("iolite", 0x75_43_F5),
        ("alexandrite", 0xAB_37_E5),
        ("ammolite", 0xDB_2B_FF),
        ("rose_quartz", 0xFF_4E_AB),
        ("black_diamond", 0x5F_52_4C),
        ("white_diamond", 0xD5_C1_D2),
        ("garnet", 0x97_00_00),
        ("aquamarine", 0x6E_E9_F4),
        ("tanzanite", 0x3D_00_B9),
        ("opal", 0xDD_FF_E4),
        ("pearl", 0xD3_CB_BF),
    ];

    #[test]
    fn registry_has_the_twenty_one_gems_in_upstream_order() {
        assert_eq!(GEMS.len(), 21);
        let names: Vec<&str> = GEMS.iter().map(|gem| gem.name).collect();
        assert_eq!(names, NAMES);
    }

    #[test]
    fn every_gem_has_a_unique_lowercase_name() {
        let mut names: Vec<&str> = GEMS.iter().map(|gem| gem.name).collect();
        names.sort_unstable();
        names.dedup();
        assert_eq!(names.len(), 21, "duplicate gem names");
        for gem in GEMS {
            assert_eq!(
                gem.name,
                gem.name.to_lowercase(),
                "{} is not lower case",
                gem.name
            );
        }
    }

    #[test]
    fn index_round_trips_every_gem() {
        assert_eq!(GEMS.len(), 21);
        for (position, gem) in GEMS.iter().enumerate() {
            assert_eq!(
                gem.index(),
                Some(position),
                "{} has the wrong index",
                gem.name
            );
        }
    }

    #[test]
    fn from_name_is_exact_and_rejects_unknown_names() {
        assert_eq!(Gem::from_name("ruby").map(|gem| gem.name), Some("ruby"));
        assert_eq!(
            Gem::from_name("black_diamond").map(|gem| gem.name),
            Some("black_diamond")
        );
        assert_eq!(Gem::from_name("Ruby"), None, "names are lower case");
        assert_eq!(Gem::from_name("ruby_block"), None);
        assert_eq!(Gem::from_name(""), None);
        assert_eq!(Gem::from_name("diamond"), None, "vanilla is not a gem");
    }

    #[test]
    fn colours_match_the_upstream_enum_constants() {
        for (name, color) in COLOURS {
            let gem = Gem::from_name(name).unwrap_or_else(|| panic!("{name} is registered"));
            assert_eq!(gem.color, color, "{name} has the wrong colour");
        }
        let mut colours: Vec<u32> = GEMS.iter().map(|gem| gem.color).collect();
        colours.sort_unstable();
        colours.dedup();
        assert_eq!(colours.len(), 21, "two gems share a colour");
        for gem in GEMS {
            assert!(gem.color <= 0xFF_FF_FF, "{} is not RGB", gem.name);
        }
    }

    #[test]
    fn rarities_match_the_upstream_enum() {
        let count = |rarity: Rarity| GEMS.iter().filter(|gem| gem.rarity == rarity).count();
        assert_eq!(count(Rarity::Common), 5);
        assert_eq!(count(Rarity::Uncommon), 8);
        assert_eq!(count(Rarity::Rare), 6);
        assert_eq!(count(Rarity::Epic), 2);
        let by = |name: &str| Gem::from_name(name).map(|gem| gem.rarity);
        assert_eq!(by("ruby"), Some(Rarity::Common));
        assert_eq!(by("garnet"), Some(Rarity::Uncommon));
        assert_eq!(by("opal"), Some(Rarity::Rare));
        assert_eq!(by("white_diamond"), Some(Rarity::Epic));
    }

    #[test]
    fn titles_match_the_upstream_lang_file() {
        assert_eq!(GEMS.len(), 21);
        for gem in GEMS {
            let key = format!("gem.silentgems.{}", gem.name);
            assert_eq!(
                gem.title,
                expected_title(gem.name),
                "{key} has the wrong English name"
            );
        }
    }

    /// The `gem.silentgems.*` values from `en_us.json`.
    fn expected_title(name: &str) -> &'static str {
        match name {
            "alexandrite" => "Alexandrite",
            "ammolite" => "Ammolite",
            "aquamarine" => "Aquamarine",
            "black_diamond" => "Black Diamond",
            "carnelian" => "Carnelian",
            "citrine" => "Citrine",
            "garnet" => "Garnet",
            "heliodor" => "Heliodor",
            "iolite" => "Iolite",
            "kyanite" => "Kyanite",
            "moldavite" => "Moldavite",
            "opal" => "Opal",
            "pearl" => "Pearl",
            "peridot" => "Peridot",
            "rose_quartz" => "Rose Quartz",
            "ruby" => "Ruby",
            "sapphire" => "Sapphire",
            "tanzanite" => "Tanzanite",
            "topaz" => "Topaz",
            "turquoise" => "Turquoise",
            "white_diamond" => "White Diamond",
            other => panic!("no expected title for {other}"),
        }
    }

    #[test]
    fn item_block_and_tag_ids_are_namespaced_by_gem() {
        let rose = Gem::from_name("rose_quartz").expect("rose_quartz is registered");
        assert_eq!(rose.item_id(), "silentgems:rose_quartz");
        assert_eq!(rose.block_id(), "silentgems:rose_quartz_block");
        assert_eq!(rose.gem_tag(), "c:gems/rose_quartz");
        assert_eq!(rose.storage_block_tag(), "c:storage_blocks/rose_quartz");
        let ruby = Gem::from_name("ruby").expect("ruby is registered");
        assert_eq!(ruby.item_id(), "silentgems:ruby");
        assert_eq!(ruby.block_id(), "silentgems:ruby_block");
        assert_eq!(ruby.gem_tag(), "c:gems/ruby");
        assert_eq!(ruby.storage_block_tag(), "c:storage_blocks/ruby");
    }

    #[test]
    fn every_gem_compresses_nine_to_one_storage_block() {
        assert_eq!(GEMS_PER_BLOCK, 9);
        assert_eq!(GEMS.len(), 21);
        for gem in GEMS {
            assert_eq!(gem.gems_per_block(), 9, "{} has the wrong ratio", gem.name);
        }
    }
}
