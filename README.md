# 🚀 Movement Archetypes System

Yo team! This is the movement system for our game. It's built to be modular, fast, and easy to expand. No more spaghetti code for every new ability.

## 🛠 How it Works
The system is **data-driven**. Every class is just a table in a `ModuleScript`. 

- **`MovementService` (Server)**: The brain. It handles the actual physics and cooldowns so people can't cheat.
- **`MovementController` (Client)**: Listens for Q/E inputs and tells the server to fire an ability.
- **`MovementUtil` (Shared)**: A bunch of math and physics helpers (Knockback, Raycasting, etc).

## 🃏 Classes & Rarities
We have 21 classes across 4 tiers: **Common, Rare, Legendary, and Mythic**.
Each class script in `src/Shared/Classes` follows this structure:
- **Passives**: Stat buffs (Speed/Jump) or mechanic flags.
- **Active 1 (Q)**: Your primary mobility/utility move.
- **Active 2 (E)**: Usually your secondary utility or offensive move.

## ➕ Adding a New Class
1. Create a new `ModuleScript` in `src/Shared/Classes`.
2. Copy the template from `QuickStep.lua`.
3. Give it a name, tier, and define the `Active1`/`Active2` logic.
4. The `MovementService` will automatically pick it up—no need to edit the service script!

## ⚠️ Things to Know (Dev Notes)
- **Physics**: We use `LinearVelocity` for smooth dashes and `Explosion` blasts (set to 0 damage) for area-of-effect knockback.
- **Cooldowns**: CDs are enforced on the **Server**. If the client tries to fire early, nothing happens.
- **Wall Kicks**: Some classes (like Accelerator) check for walls. If you find them being wonky, check the `RaycastParams` in `MovementUtil`.
- **Scaling**: For Gear 5 or other size-changing moves, use `character:ScaleTo()`. The system handles mass adjustment, but watch out for clipping!

## 🔗 GitHub
Since we're using Git, remember to pull before you start working so you don't get merge conflicts on the class files.

**Username**: @solopringles
**Repo**: Roblox-Movement

Let's cook! 🍳
