# EVEMon Pilot Progression

[🇵🇱 Polski](README-PL.md) | [🇬🇧 English](README-EN.md)

**EVEMon Pilot Progression** dodaje do EVEMon czytelną mapę rozwoju postaci. Projekt służy zarówno nowemu pilotowi, który chce widzieć kolejne praktyczne progi kompetencji, jak i weteranowi z dziesiątkami milionów SP, który chce szybko znaleźć nierówne supporty i dawno pozostawione luki.

Nie jest to zamiennik dla skillplanów. **EvE Modular Skillplans** mówi *co trenować pod konkretną rolę lub statek*. **EVEMon Pilot Progression** pokazuje w Certificate Browser *gdzie pilot jest obecnie*.

## Najważniejsze: kolejność instalacji

1. Pobierz i zainstaluj EVEMon z utrzymywanego repo **mgoeppner/evemon**: https://github.com/mgoeppner/evemon/releases
2. **Uruchom EVEMon co najmniej raz.**
3. Poczekaj na ekran/popup aktualizacji plików danych i **zainstaluj wszystkie oferowane aktualizacje datafiles/SDE**.
4. Zamknij EVEMon całkowicie.
5. Pobierz najnowszą paczkę z **Releases** tego repo.
6. Rozpakuj ZIP i uruchom PowerShell w katalogu paczki:
   ```powershell
   Set-ExecutionPolicy -Scope Process Bypass
   .\Install-EVEMon-Pilot-Progression.ps1
   ```
7. Uruchom EVEMon → **Certificate Browser → EVEMon Pilot Progression**.

> Aktualizacja datafiles przez EVEMon może zastąpić zmodyfikowany plik certyfikatów. Po takiej aktualizacji po prostu uruchom instalator EVEMon Pilot Progression ponownie.

## Zgodny EVEMon

Projekt jest przygotowany i testowany dla **EVEMon 5.0.1** z repo https://github.com/mgoeppner/evemon. Upstream publikuje również nowsze datafiles/SDE niezależnie od wersji programu, dlatego aktualizacja danych **przed** instalacją tego projektu jest obowiązkowym pierwszym krokiem.

## Trzy powiązane projekty

- **EvE Modular Skillplans** — https://github.com/Blizbor/EvE-Modular-Skillplans — role/task-first skillplany i training paths.
- **EVEMon Pilot Progression** — https://github.com/Blizbor/EVEMon-Pilot-Progression — szeroka diagnostyka rozwoju pilota w EVEMon.
- **EVEMon Certificates Enhanced** — https://github.com/Blizbor/EVEMon-Certificates-Enhanced — większa rozdzielczość domyślnych certyfikatów broni, dronów i tanku.

Pilot Progression i Certificates Enhanced mogą być używane razem. Pierwszy projekt daje szeroką mapę kompetencji; drugi doprecyzowuje jakość konkretnych systemów walki.

## Pobieranie paczki

Nie kopiuj pojedynczych plików z repo. Wejdź w **Releases** i pobierz gotowy plik `EVEMon-Pilot-Progression.zip`.

Repo zawiera katalog `package/` oraz workflow budujący dokładnie tę paczkę.

## Dokumentacja

- [Szybki start](docs/PL/Quick-Start.md)
- [Jak czytać poziomy](docs/PL/Levels.md)
- [Nowy pilot](docs/PL/New-Pilot.md)
- [Audyt weterana / 50M+ SP](docs/PL/Veteran-Audit.md)
- [Magic 14 a nasze podejście](docs/PL/Magic-14.md)
- [Relacja między projektami](docs/PL/Project-Relationship.md)
- [Zasady dla kontrybutorów](docs/PL/Contributor-Guide.md)
- [FAQ](docs/PL/FAQ.md)

## Kontakt

Problemy z instalacją, błędy definicji, propozycje zmian i pytania projektowe zgłaszaj przez **Issue tracker**: https://github.com/Blizbor/EVEMon-Pilot-Progression/issues

<p align="center">
  <img src="https://images.evetech.net/characters/91331899/portrait?size=256" width="144" alt="Gazzine TunakTun portrait">
</p>
<p align="center"><strong>Author: Gazzine TunakTun</strong></p>

_EVE Online i powiązane znaki należą do CCP hf. Projekt społecznościowy, niezależny od CCP._
