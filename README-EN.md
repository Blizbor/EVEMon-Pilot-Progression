# EVEMon Pilot Progression

[🇵🇱 Polski](README-PL.md) | [🇬🇧 English](README-EN.md)

**EVEMon Pilot Progression** adds a readable pilot-development map to EVEMon. It is useful both for a new pilot who wants clear practical competence steps and for a veteran with tens of millions of SP who wants to expose uneven support skills and old gaps immediately.

It is not a replacement for skill plans. **EvE Modular Skillplans** tells you *what to train for a role or ship*. **EVEMon Pilot Progression** shows in Certificate Browser *where the pilot currently stands*.

## Most important: installation order

1. Download and install EVEMon from the maintained **mgoeppner/evemon** repository: https://github.com/mgoeppner/evemon/releases
2. **Start EVEMon at least once.**
3. When EVEMon shows its datafile/SDE update screen or popup, **install all offered datafile updates**.
4. Close EVEMon completely.
5. Download the newest package from this repository's **Releases** page.
6. Extract the ZIP and run PowerShell in the package directory:
   ```powershell
   Set-ExecutionPolicy -Scope Process Bypass
   .\Install-EVEMon-Pilot-Progression.ps1
   ```
7. Start EVEMon → **Certificate Browser → EVEMon Pilot Progression**.

> An EVEMon datafile update may replace the modified certificates file. After such an update, simply run the EVEMon Pilot Progression installer again.

## Compatible EVEMon

The project is prepared and tested for **EVEMon 5.0.1** from https://github.com/mgoeppner/evemon. The upstream project also publishes newer SDE/datafiles independently from application releases, which is why updating the datafiles **before** applying this project is mandatory.

## The three related projects

- **EvE Modular Skillplans** — https://github.com/Blizbor/EvE-Modular-Skillplans — role/task-first skill plans and training paths.
- **EVEMon Pilot Progression** — https://github.com/Blizbor/EVEMon-Pilot-Progression — broad pilot-development diagnostics inside EVEMon.
- **EVEMon Certificates Enhanced** — https://github.com/Blizbor/EVEMon-Certificates-Enhanced — higher-resolution default certificates for weapons, drones and tank.

Pilot Progression and Certificates Enhanced are designed to coexist. Pilot Progression gives the broad map; Certificates Enhanced adds depth inside specific combat systems.

## Downloading the package

Do not manually pick individual files from the repository. Open **Releases** and download `EVEMon-Pilot-Progression.zip`.

The repository contains a `package/` directory and a workflow that builds this exact archive.

## Documentation

- [Quick start](docs/EN/Quick-Start.md)
- [Understanding levels](docs/EN/Levels.md)
- [New pilot](docs/EN/New-Pilot.md)
- [Veteran / 50M+ SP audit](docs/EN/Veteran-Audit.md)
- [Magic 14 and this approach](docs/EN/Magic-14.md)
- [Project relationship](docs/EN/Project-Relationship.md)
- [Contributor guide](docs/EN/Contributor-Guide.md)
- [FAQ](docs/EN/FAQ.md)

## Contact

Installation problems, definition bugs, change proposals and project questions belong in the **Issue tracker**: https://github.com/Blizbor/EVEMon-Pilot-Progression/issues

<p align="center">
  <img src="https://images.evetech.net/characters/91331899/portrait?size=256" width="144" alt="Gazzine TunakTun portrait">
</p>
<p align="center"><strong>Author: Gazzine TunakTun</strong></p>

_EVE Online and related marks are property of CCP hf. This is a player-made project and is not affiliated with CCP._
