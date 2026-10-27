# Development notes

Version: `0.1.0-alpha`. Interface: `11509`. Scope: Classic Era carried bags `0..4`.

## Source verification

Checked 2026-10-27 against the `classic_era` mirror of Blizzard UI sources:

- [Client version](https://github.com/Gethe/wow-ui-source/blob/classic_era/version.txt): `1.15.9.70003`.
- [Container API declarations](https://github.com/Gethe/wow-ui-source/blob/classic_era/Interface/AddOns/Blizzard_APIDocumentationGenerated/ContainerDocumentation.lua): structured `C_Container.GetContainerItemInfo`, bag/slot access, cooldowns, pickup, use.
- [Item API declarations](https://github.com/Gethe/wow-ui-source/blob/classic_era/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua): `C_Item.GetItemGUID`, `GetItemInfoInstant`, item data loading.
- [Classic container handling](https://github.com/Gethe/wow-ui-source/blob/classic_era/Interface/AddOns/Blizzard_UIPanels_Game/Classic/ContainerFrame_Shared.lua): native bag button identities, modified clicks, refund/buyback handling and `ContainerFrame_Update`.
- [Classic bag templates](https://github.com/Gethe/wow-ui-source/blob/classic_era/Interface/AddOns/Blizzard_UIPanels_Game/Classic/ContainerFrame.xml): native frames and item button names.
- [Era merchant handling](https://github.com/Gethe/wow-ui-source/blob/classic_era/Interface/AddOns/Blizzard_UIPanels_Game/Vanilla/MerchantFrame.lua): native refund state.

The mirror is a source snapshot, not a guarantee that every region or installation has the identical build. At startup the addon reads `GetBuildInfo()` and reports an interface mismatch. In-game validation is outstanding.

## Structure

| File | Responsibility |
| --- | --- |
| Model.lua | Pure database, identity, label CRUD, matching and vendor policy |
| Inventory.lua | WoW inventory adapter, scan/refresh, native bag action dispatch |
| UI.lua | Inventory window, per-item editor, label prompts and appearance settings |
| Integrations.lua | Tooltip hooks, Blizzard bag overlays and minimap button |
| Core.lua | Initialization, event wiring, slash commands, explicit unlock dialogs |

No external addon libraries, bundled art, global container API replacements, automatic selling, sorting, external network requests or telemetry are used. Art uses client textures. The custom window's unmodified/modified click paths delegate to the current client's native container handlers so client refund and buyback behavior remains owned by Blizzard.

Data: account-wide tag definitions, character-indexed item records and settings; schema version `1`. Equipment keys are `guid:<physical item GUID>`. Other keys are `item:<item ID>`. No equipment slot/link fallback is used while GUID resolution is pending. Tagging is manual. Definition deletion removes only the label and never the independent lock.

Appearance filtering does not move real inventory items. Native frames are only annotated/dimmed. A transparent mouse overlay is active only for Alt editing or merchant protection of a locked/unresolved item, and is hidden in combat. It uses fresh slot reads and checks its rendered snapshot before acting. Frames reused for bank bags have overlays removed. The native integration does not attach adapters to Bagnon, ElvUI or other bag replacements.

## Tests

Use an existing Lua 5.1 interpreter:

```text
lua tests/spec.lua
```

Or use the supplied Python stdlib-only runner with an existing Lua 5.1/LuaJIT shared library:

```text
python tests/run_lua.py --lua-dll "path/to/lua51.dll"
```

The runner first compiles every `.lua` file, then runs the suite with an explicit WoW boundary mock. On the development workstation it uses the Lua 5.1 DLL already installed with OBS Studio, read-only, in a separate process. No new interpreter was installed and no game or OBS files were changed.

Result: **50 tests passed**. In addition to pure model tests, the suite loads the real addon files in TOC order, creates the actual UI objects through a mock, invokes real UI callbacks, and checks item-action calls. Tests cover race conditions caused by item moves, recycling native frames for bank bags, distinct same-ID equipment, lock/type scope, no automatic sell on unlock, keyboard bag toggles, and numeric `.count` required by Blizzard's refund flow.

The mock does not render the real WoW client and does not implement secure execution/taint. It cannot establish production compatibility. Follow the in-game test sequence in `README.md` before relying on this alpha for normal inventory use.

## Deferred scope

- Specific adapters and protection behavior for third-party bag/auto-sell addons.
- Separate bank inventory view; editing equipment directly on the character sheet.
- Automatic categorization rules and import/export of profiles.
- One-click set equipping (labels are classifications, not equipment-manager sets).
- Generic protection against deletion, mail, auction or trade.

These are not advertised as implemented features of this package.
