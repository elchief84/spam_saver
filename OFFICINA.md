---
natura: { tipo: mobile, stack: android }
human-need: [approvazione]
notifiche: { telegram: ["53341615"] }
limiti: { iterazioni: 3 }
ci: { template: android }
---

# Officina — setup del progetto

Questo progetto è governato da Officina.

- La **natura** (tipo + stack) comanda i comandi di verifica e il template di CI: qui è
  un'applicazione **mobile Android** (Kotlin + Jetpack Compose + Room, `minSdk 29`), quindi la
  verifica gira con `./gradlew` — i test JVM per la logica pura, la build per il resto.
- **Nessuna preferenza di ruolo**: Officina sceglie fra i membri disponibili — gli agenti
  sviluppatori per l'implementazione, la Technical Architect per la review, il tester per le
  verifiche — perché le persone fisiche entrano in gioco solo per `human-need` o su preferenza
  esplicita.
- `human-need: [approvazione]` — **il merge lo fa il titolare**: Officina prepara e notifica,
  poi aspetta. Vale anche per questa pull request.
- `notifiche.telegram` sono i destinatari delle notifiche.
- Il perimetro del progetto e le decisioni prese stanno in `CONTEXT.md` e in `docs/adr/`; la
  spec in issue, i task in ticket con label `ready-for-agent`.
