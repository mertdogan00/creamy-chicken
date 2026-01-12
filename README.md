# 🍗 Creamy Chicken (Server Kit)

> For people who don’t want to marry the cloud
> One command to set up, back up, move, and restore
> Quiet Bash scripts > noisy cloud dashboards

**Creamy Chicken** is a **modular Bash toolkit** designed for fast, repeatable server setup, backup, migration, and restore.
Built for Ubuntu and Debian-based systems, with plans to expand support in the future.

Big cloud providers love shiny dashboards, friendly wizards, and words like _“simple”_ and _“managed”_.
What they don’t love is you leaving.

This project isn’t about hating the cloud.
It’s about **not becoming dependent on it**.

If AWS, Azure, and Google Cloud are the loud neighbors with flashing lights,
Kremali Tavuk is the cook in the back alley quietly making things work.

---

## 🧠 Philosophy

- The server is **yours**
- Setup must be **repeatable**
- Backup must be **one command**
- Restore must work **under pressure**
- “Click in the cloud console” is not a strategy

Kremali Tavuk:

- Breaks the _“I’ll remember how I set this up”_ illusion
- Turns servers into **portable assets**
- Keeps everything at the **file + Bash** level

Simple. Transparent. No magic.

---

## 🚀 What It Does

- Runs **profile-based** server setups
- Executes **only the modules you enable**
- Standardizes:

  - users
  - SSH
  - firewall
  - system updates

- Handles **backup and restore flows**
- Optionally:

  - installs **Dockge**
  - prepares container setups for migration

---

## 🧩 Project Structure

```
.
├── run.sh                # Main entry point
├── config/
│   └── global.conf       # Global settings
├── profiles/
│   └── setup.conf        # Scenario-based profiles
├── modules/
│   ├── users.sh
│   ├── ssh.sh
│   ├── firewall.sh
│   ├── updates.sh
│   └── backup.sh
├── core/                 # Framework logic
└── cli/                  # CLI handling
```

- **Profiles** define _what_ happens
- **Modules** define _how_ it happens
- **Core** decides _when and in what order_

No monolith. No lock-in. Just composable pieces.

---

## ⚡ Quick Start

1. Edit global configuration:

```bash
nano config/global.conf
```

2. Choose or create a profile:

```bash
nano profiles/setup.conf
```

3. Run:

```bash
./run.sh --profile setup
```

That’s it.

No dashboards.
No wizards.
No surprises.

---

## 🔁 Backup & Restore Logic

- **Backup** turns a live server into a portable package
- **Restore** turns a blank machine into a working system in minutes

The goal is simple:

> Never say “the server is gone” again.

---

## 🧨 Who Is This For?

- VPS or bare-metal users
- People who want **control, not convenience traps**
- Engineers who prefer scripts over panels
- Anyone who has ever restored a server at 3 AM

---

## ❌ Who Is This NOT For?

- Click-ops enthusiasts
- Vendor lock-in enjoyers
- People afraid of Bash
- “Just use the cloud console” believers

---

## 🤝 Contributing

- Fork → build → PR
- New module? Great.
- Better architecture? Even better.
- Smarter backup logic? Absolutely.

This project is meant to **grow over time**.

---

## 📜 License

[MIT License](LICENSE)

Do whatever you want.
Just don’t blame the cloud when you lose control.
