# Call Guard — Traceability Matrix

**Document ID:** CG-TRM-001
**Version:** 0.1.0
**Status:** Draft
**Service:** `call-guard`
**Last Updated:** 2026-10-11
**Trace Parents:** CG-UC-001 · CG-UN-001 · CG-RSK-001 · CG-SRS-001 · CG-TP-001 · CG-SDS-001

---

## Document Control

| Role | Name | Date | Signature |
|---|---|---|---|
| Author | Aldo (PM) | 2026-10-11 | |
| Reviewer | — | — | |
| Approver (QA/RA) | — | — | |

### Change Log

| Version | Date | Author | Summary of Change |
|---|---|---|---|
| 0.1.0 | 2026-10-11 | Aldo (PM) | Initial draft: matrice compilata da CG-UC-001, CG-UN-001, CG-RSK-001, CG-SRS-001, CG-TP-001, CG-SDS-001 |

---

## Purpose

Questa matrice dimostra la copertura end-to-end di Call Guard (app Android-only per filtro chiamate sconosciute con rifiuto automatico + SMS + triage):

1. Ogni **User Need (UN-101…UN-114)** è radicato in almeno uno **Use Case (UC-01…UC-08)**.
2. Ogni **requisito SRS (SRS-101…SRS-1005, 37 requisiti)** deriva da almeno un UN e, dove applicabile, implementa un controllo di **rischio (RSK-101…RSK-109)**.
3. Ogni **SRS** è verificato da almeno un **Test Case (TP-101…TP-1203)** di CG-TP-001.
4. Ogni **SRS** è implementato da almeno una **Software Unit (SU-*)** di CG-SDS-001.

Nota di adattamento: Call Guard non è un dispositivo medico; ISO 13485 / IEC 62304 / ISO 14971 sono usati come modello di rigore (come da CG-RSK-001 §3), non come obbligo regolatorio. Nessun dato lascia il dispositivo; nessun PII nei log.

---

## Document Map

| Document ID | Document Title | Role in Chain |
|---|---|---|
| CG-UC-001 | Use Cases | Obiettivi attore (UC-01…UC-08) e confini di sistema |
| CG-UN-001 | User Needs | Bisogni stakeholder (UN-101…UN-114) derivati dagli UC |
| CG-RSK-001 | Risk Analysis (ISO 14971, adattata) | Pericoli RSK-101…RSK-109; i controlli confluiscono negli SRS |
| CG-SRS-001 | Software Requirements Specifications | 37 requisiti atomici testabili (SRS-101…SRS-1005), mappati su RF-1…RF-10 |
| CG-TP-001 | Test Plan | Casi TP-101…TP-1203 che verificano ogni SRS |
| CG-SDS-001 | Software Design Specification | Software Unit SU-DOM-*, SU-APP-*, SU-INF-* che implementano ogni SRS |

Riferimento RF (brief) → SRS: RF-1=SRS-201/202/301/1001/1004 · RF-2=SRS-302/303/304 · RF-3=SRS-401/402/403/801 · RF-4=SRS-305/501/902 · RF-5=SRS-302/303/703 · RF-6=SRS-103/306/502/703 · RF-7=SRS-601/602/603/604/704 · RF-8=SRS-701/702/704/705/801/802 · RF-9=SRS-101/102/503 · RF-10=SRS-307/603/604.

Testo SMS di default (SRS-101): "La chiamata è stata automaticamente rifiutata dal ricevente perché il suo numero è sconosciuto, le preghiamo di inviare un sms con le informazioni necessarie alla sua identificazione."

---

## 1. Forward Traceability — UC → UN → SRS → Test → SU

> Lettura da sinistra a destra: dagli obiettivi attore fino a implementazione e verifica. Una riga per SRS (37 righe). Test Status = Not Run (nessun TER ancora emesso).

| UC | UC Title | UN | UN Summary | RSK | SRS | SRS Summary | Test Cases | Software Unit | Test Status |
|---|---|---|---|---|---|---|---|---|---|
| UC-08 | Configurare il testo SMS automatico | UN-105 | Risposta SMS automatica che chiede identificazione | — | SRS-101 | Default SMS precompilato al primo avvio | TP-101, TP-1102 | SU-DOM-04-01, SU-APP-07-01, SU-INF-05-01 | Not Run |
| UC-08 | Configurare il testo SMS automatico | UN-105 | Risposta SMS automatica che chiede identificazione | RSK-106 | SRS-102 | Testo SMS personalizzato persiste e viene usato | TP-102, TP-1201 | SU-APP-07-01, SU-INF-05-01 | Not Run |
| UC-04 | Inviare l'SMS automatico al numero rifiutato | UN-103 | Numeri bloccati sempre rifiutati | RSK-105, RSK-107 | SRS-103 | Toggle "Invia SMS ai blacklist", default OFF, persistito | TP-103, TP-502 | SU-DOM-02-02, SU-APP-03-01, SU-INF-05-01 | Not Run |
| UC-01 | Attivare la protezione anti-sconosciuti | UN-101, UN-109 | Rifiuto automatico sconosciuti; gate di filtro | RSK-102 | SRS-201 | Screening solo nel nativo Kotlin, Android 10+, ruolo screening | TP-201 | SU-INF-01-01, SU-APP-01-01 | Not Run |
| UC-01 | Attivare la protezione anti-sconosciuti | UN-101 | Rifiuto automatico sconosciuti | RSK-102 | SRS-202 | Stato bloccante se ruolo screening mancante, con azione singola | TP-202, TP-1004 | SU-APP-08-01, SU-INF-07-01, SU-INF-01-01 | Not Run |
| UC-01 | Attivare la protezione anti-sconosciuti | UN-101, UN-109 | Rifiuto automatico; gate permessi | RSK-105 | SRS-203 | Permessi sensibili minimi con feature-gate esplicito | TP-203, TP-1203 | SU-APP-08-01, SU-INF-02-01, SU-INF-03-01, SU-INF-04-01 | Not Run |
| UC-02 | Rifiutare automaticamente chiamata sconosciuta | UN-101, UN-114 | Rifiuto automatico; screening tempestivo non intrusivo | RSK-102 | SRS-301 | Intercettazione prima dello squillo entro timeout, solo lookup locali | TP-301, TP-1202 | SU-APP-01-01, SU-INF-01-01 | Not Run |
| UC-02 | Rifiutare automaticamente chiamata sconosciuta | UN-101, UN-102 | Rifiuto sconosciuti; noti sempre passanti | RSK-101, RSK-102 | SRS-302 | Rifiuto sse visibile E non rubrica E non whitelist E ruolo attivo | TP-302, TP-1101 | SU-DOM-01-01, SU-DOM-02-01, SU-APP-01-01 | Not Run |
| UC-02 | Rifiutare automaticamente chiamata sconosciuta | UN-102 | Fidati sempre passanti | RSK-101 | SRS-303 | Contatti passano senza log né SMS | TP-303, TP-1101 | SU-DOM-02-01, SU-INF-02-01, SU-APP-01-01 | Not Run |
| UC-02 | Rifiutare automaticamente chiamata sconosciuta | UN-101 | Rifiuto automatico sconosciuti | — | SRS-304 | Anonimi/vuoti passano, mai SMS | TP-304 | SU-DOM-01-01, SU-DOM-02-01, SU-DOM-02-02 | Not Run |
| UC-04 | Inviare l'SMS automatico al numero rifiutato | UN-105 | Risposta SMS automatica | RSK-107 | SRS-305 | Mai SMS a short code / alfanumerici / non composti | TP-305 | SU-DOM-01-01, SU-DOM-02-02, SU-INF-03-01 | Not Run |
| UC-02 | Rifiutare automaticamente chiamata sconosciuta | UN-103 | Bloccati sempre rifiutati | — | SRS-306 | Blacklist rifiuta sempre, anche sopra rubrica | TP-306, TP-703 | SU-DOM-02-01, SU-APP-01-01 | Not Run |
| UC-07 | Gestire whitelist, blacklist e profilo | UN-108 | Decisioni effettive subito | — | SRS-307 | Decisione attiva dalla chiamata successiva, senza restart | TP-307, TP-603, TP-604, TP-704 | SU-APP-05-01, SU-INF-05-01, SU-INF-01-01 | Not Run |
| UC-03 | Registrare il tentativo rifiutato | UN-104, UN-110 | Record consultabile; retention locale | RSK-106 | SRS-401 | Un record per rifiuto: numero, data/ora, esito, stato SMS, note | TP-401 | SU-DOM-03-01, SU-APP-02-01, SU-INF-05-01 | Not Run |
| UC-03 | Registrare il tentativo rifiutato | UN-104 | Record consultabile | — | SRS-402 | Stato SMS aggiornato (sent/failed/skipped+motivo), solo template-ref | TP-402 | SU-APP-02-01, SU-APP-03-01, SU-INF-05-01 | Not Run |
| UC-03 | Registrare il tentativo rifiutato | UN-110 | Retention locale | RSK-106 | SRS-403 | Cronologia persiste a riavvio/update, ordine discendente | TP-403, TP-1201 | SU-INF-05-01, SU-INF-07-01 | Not Run |
| UC-04 | Inviare l'SMS automatico al numero rifiutato | UN-105 | Risposta SMS automatica | RSK-107 | SRS-501 | Esattamente un SMS per rifiuto (idempotenza), salve eccezioni | TP-501, TP-1102 | SU-APP-03-01, SU-INF-03-01, SU-DOM-02-02 | Not Run |
| UC-04 | Inviare l'SMS automatico al numero rifiutato | UN-103 | Bloccati sempre rifiutati | — | SRS-502 | Skip SMS blacklist se toggle OFF, stato skipped/blacklisted | TP-502 | SU-DOM-02-02, SU-APP-03-01 | Not Run |
| UC-08 | Configurare il testo SMS automatico | UN-105 | Risposta SMS automatica | — | SRS-503 | Editor testo SMS: validazione non-vuoto + limite dichiarato | TP-503, TP-1102 | SU-DOM-04-01, SU-APP-07-01, SU-INF-07-01 | Not Run |
| UC-06 | Classificare un numero dalla risposta SMS | UN-106 | Triage risposte all'apertura | RSK-109 | SRS-601 | All'apertura: vista dedicata SMS da numeri rifiutati non classificati | TP-601, TP-1104 | SU-APP-04-01, SU-INF-04-01, SU-INF-07-01 | Not Run |
| UC-06 | Classificare un numero dalla risposta SMS | UN-106 | Triage risposte all'apertura | RSK-108 | SRS-602 | Esattamente due CTA: Accetta (whitelist) / Rifiuta (blacklist) | TP-602, TP-1103 | SU-INF-07-01 | Not Run |
| UC-06 | Classificare un numero dalla risposta SMS | UN-108, UN-106 | Effetto immediato; triage | RSK-108 | SRS-603 | Accetta → whitelist con source+timestamp, pendenza rimossa | TP-603 | SU-APP-05-01, SU-DOM-03-02, SU-INF-05-01 | Not Run |
| UC-06 | Classificare un numero dalla risposta SMS | UN-108, UN-106 | Effetto immediato; triage | RSK-108 | SRS-604 | Rifiuta → blacklist con source+timestamp, pendenza rimossa | TP-604 | SU-APP-05-01, SU-DOM-03-02, SU-INF-05-01 | Not Run |
| UC-07 | Gestire whitelist, blacklist e profilo | UN-107 | Liste gestibili + profili | — | SRS-701 | CRUD liste + profilo (numero, nome, note, categoria, data, source) | TP-701 | SU-DOM-03-02, SU-APP-06-01, SU-INF-05-01 | Not Run |
| UC-07 | Gestire whitelist, blacklist e profilo | UN-107 | Liste gestibili | — | SRS-702 | Mutua esclusione whitelist/blacklist con move registrato | TP-702 | SU-DOM-03-02, SU-APP-06-01 | Not Run |
| UC-02 | Rifiutare automaticamente chiamata sconosciuta | UN-102, UN-103 | Fidati passano; bloccati rifiutati | — | SRS-703 | Precedenza: blacklist > contatti/whitelist-pass > reject | TP-703, TP-306 | SU-DOM-02-01, SU-APP-01-01 | Not Run |
| UC-05 | Consultare la cronologia bloccate | UN-104, UN-106 | Record consultabile; triage | — | SRS-704 | Promozione diretta dalla cronologia con singola azione | TP-704 | SU-APP-05-01, SU-INF-07-01 | Not Run |
| UC-07 | Gestire whitelist, blacklist e profilo | UN-107, UN-110 | Liste gestibili; retention | RSK-106 | SRS-705 | Liste persistenti a restart e update | TP-705, TP-1201 | SU-INF-05-01 | Not Run |
| UC-05 | Consultare la cronologia bloccate | UN-104, UN-107 | Record + liste leggibili | — | SRS-801 | Tre liste con filtro sottostringa + sort discendente | TP-801 | SU-INF-07-01, SU-INF-05-01 | Not Run |
| UC-07 | Gestire whitelist, blacklist e profilo | UN-107 | Profili modificabili | — | SRS-802 | Dettaglio profilo: storico collegato + edit nome/note/categoria | TP-802 | SU-INF-07-01, SU-DOM-03-02 | Not Run |
| UC-02 | Rifiutare automaticamente chiamata sconosciuta | UN-112, UN-113 | Errori consistenti; log senza PII | RSK-103 | SRS-901 | Errori con azione correttiva, no PII extra né stack trace | TP-901 | SU-INF-07-01, SU-INF-08-01, SU-APP-08-01 | Not Run |
| UC-04 | Inviare l'SMS automatico al numero rifiutato | UN-112, UN-105 | Errori consistenti; SMS | RSK-107 | SRS-902 | SMS fallito: un solo retry manuale, mai auto-retry background | TP-902 | SU-APP-03-01, SU-INF-07-01 | Not Run |
| UC-01 | Attivare la protezione anti-sconosciuti | UN-114, UN-111 | Tempestivo; privacy on-device | RSK-102, RSK-104 | SRS-1001 | Decisione screening solo on-device, nessuna chiamata rete | TP-1001 | SU-APP-01-01, SU-INF-01-01 | Not Run |
| UC-03 | Registrare il tentativo rifiutato | UN-111 | Privacy on-device | RSK-104 | SRS-1002 | Tutto lo storage on-device, nessuna sync/analytics/backup con PII | TP-1002 | SU-INF-05-01, SU-INF-08-01 | Not Run |
| UC-03 | Registrare il tentativo rifiutato | UN-113, UN-111 | Log tracciabili senza PII; privacy | RSK-103 | SRS-1003 | No PII (numeri/corpi SMS) nei log; solo hash/prefissi troncati | TP-1003, TP-901 | SU-INF-08-01 | Not Run |
| UC-01 | Attivare la protezione anti-sconosciuti | UN-112, UN-101 | Errori consistenti; protezione | RSK-102 | SRS-1004 | Degrado graceful: fail-open chiamate, notifica, nessuno stato parziale | TP-1004, TP-1202 | SU-APP-08-01, SU-APP-01-01, SU-INF-07-01 | Not Run |
| UC-01 | Attivare la protezione anti-sconosciuti | UN-109 | Gate di filtro / piattaforma | — | SRS-1005 | Solo Android 10+: messaggio incompatibilità sotto API 29 | TP-1005 | SU-APP-08-01, SU-INF-07-01 | Not Run |

---

## 2. Backward Traceability — SRS → UC / UN / RSK / Test / SU

> "Questo requisito esiste per [UC + UN], controlla [RSK], è verificato da [TP] ed è implementato in [SU]." Speculare alla §1; nessun SRS orfano, nessun TP senza SRS.

| SRS | SRS Summary | UC | UN | RSK | Test Cases | Software Unit | Test Status |
|---|---|---|---|---|---|---|---|
| SRS-101 | Default SMS precompilato | UC-08 | UN-105 | — | TP-101, TP-1102 | SU-DOM-04-01, SU-APP-07-01, SU-INF-05-01 | Not Run |
| SRS-102 | Persistenza testo SMS | UC-08 | UN-105 | RSK-106 | TP-102, TP-1201 | SU-APP-07-01, SU-INF-05-01 | Not Run |
| SRS-103 | Toggle SMS blacklist default OFF | UC-04 | UN-103 | RSK-105, RSK-107 | TP-103, TP-502 | SU-DOM-02-02, SU-APP-03-01, SU-INF-05-01 | Not Run |
| SRS-201 | Screening nativo Kotlin Android 10+ | UC-01 | UN-101, UN-109 | RSK-102 | TP-201 | SU-INF-01-01, SU-APP-01-01 | Not Run |
| SRS-202 | Stato bloccante se ruolo mancante | UC-01 | UN-101 | RSK-102 | TP-202, TP-1004 | SU-APP-08-01, SU-INF-07-01, SU-INF-01-01 | Not Run |
| SRS-203 | Permessi sensibili con feature-gate | UC-01 | UN-101, UN-109 | RSK-105 | TP-203, TP-1203 | SU-APP-08-01, SU-INF-02-01, SU-INF-03-01, SU-INF-04-01 | Not Run |
| SRS-301 | Intercettazione pre-squillo entro timeout | UC-02 | UN-101, UN-114 | RSK-102 | TP-301, TP-1202 | SU-APP-01-01, SU-INF-01-01 | Not Run |
| SRS-302 | Rifiuto sse visibile/non-rubrica/non-whitelist | UC-02 | UN-101, UN-102 | RSK-101, RSK-102 | TP-302, TP-1101 | SU-DOM-01-01, SU-DOM-02-01, SU-APP-01-01 | Not Run |
| SRS-303 | Contatti passano senza log/SMS | UC-02 | UN-102 | RSK-101 | TP-303, TP-1101 | SU-DOM-02-01, SU-INF-02-01, SU-APP-01-01 | Not Run |
| SRS-304 | Anonimi passano, mai SMS | UC-02 | UN-101 | — | TP-304 | SU-DOM-01-01, SU-DOM-02-01, SU-DOM-02-02 | Not Run |
| SRS-305 | Mai SMS a short code/non composti | UC-04 | UN-105 | RSK-107 | TP-305 | SU-DOM-01-01, SU-DOM-02-02, SU-INF-03-01 | Not Run |
| SRS-306 | Blacklist prevale sempre | UC-02 | UN-103 | — | TP-306, TP-703 | SU-DOM-02-01, SU-APP-01-01 | Not Run |
| SRS-307 | Decisioni attive dalla chiamata successiva | UC-07 | UN-108 | — | TP-307, TP-603, TP-604, TP-704 | SU-APP-05-01, SU-INF-05-01, SU-INF-01-01 | Not Run |
| SRS-401 | Record per rifiuto (5 campi) | UC-03 | UN-104, UN-110 | RSK-106 | TP-401 | SU-DOM-03-01, SU-APP-02-01, SU-INF-05-01 | Not Run |
| SRS-402 | Stato invio SMS nel record | UC-03 | UN-104 | — | TP-402 | SU-APP-02-01, SU-APP-03-01, SU-INF-05-01 | Not Run |
| SRS-403 | Cronologia persiste, ordine discendente | UC-03 | UN-110 | RSK-106 | TP-403, TP-1201 | SU-INF-05-01, SU-INF-07-01 | Not Run |
| SRS-501 | Un solo SMS per rifiuto | UC-04 | UN-105 | RSK-107 | TP-501, TP-1102 | SU-APP-03-01, SU-INF-03-01, SU-DOM-02-02 | Not Run |
| SRS-502 | Skip SMS blacklist se toggle OFF | UC-04 | UN-103 | — | TP-502 | SU-DOM-02-02, SU-APP-03-01 | Not Run |
| SRS-503 | Editor testo SMS validato | UC-08 | UN-105 | — | TP-503, TP-1102 | SU-DOM-04-01, SU-APP-07-01, SU-INF-07-01 | Not Run |
| SRS-601 | Vista SMS all'apertura, collegata | UC-06 | UN-106 | RSK-109 | TP-601, TP-1104 | SU-APP-04-01, SU-INF-04-01, SU-INF-07-01 | Not Run |
| SRS-602 | Due CTA Accetta/Rifiuta | UC-06 | UN-106 | RSK-108 | TP-602, TP-1103 | SU-INF-07-01 | Not Run |
| SRS-603 | Accetta → whitelist | UC-06 | UN-106, UN-108 | RSK-108 | TP-603 | SU-APP-05-01, SU-DOM-03-02, SU-INF-05-01 | Not Run |
| SRS-604 | Rifiuta → blacklist | UC-06 | UN-106, UN-108 | RSK-108 | TP-604 | SU-APP-05-01, SU-DOM-03-02, SU-INF-05-01 | Not Run |
| SRS-701 | CRUD liste + profilo (6 campi) | UC-07 | UN-107 | — | TP-701 | SU-DOM-03-02, SU-APP-06-01, SU-INF-05-01 | Not Run |
| SRS-702 | Mutua esclusione liste | UC-07 | UN-107 | — | TP-702 | SU-DOM-03-02, SU-APP-06-01 | Not Run |
| SRS-703 | Precedenza blacklist > pass > reject | UC-02 | UN-102, UN-103 | — | TP-703, TP-306 | SU-DOM-02-01, SU-APP-01-01 | Not Run |
| SRS-704 | Promozione diretta da cronologia | UC-05 | UN-104, UN-106 | — | TP-704 | SU-APP-05-01, SU-INF-07-01 | Not Run |
| SRS-705 | Liste persistenti | UC-07 | UN-107, UN-110 | RSK-106 | TP-705, TP-1201 | SU-INF-05-01 | Not Run |
| SRS-801 | Tre liste con filtro + sort | UC-05 | UN-104, UN-107 | — | TP-801 | SU-INF-07-01, SU-INF-05-01 | Not Run |
| SRS-802 | Dettaglio profilo modificabile | UC-07 | UN-107 | — | TP-802 | SU-INF-07-01, SU-DOM-03-02 | Not Run |
| SRS-901 | Errori con azione, no PII/stack | UC-02 | UN-112, UN-113 | RSK-103 | TP-901 | SU-INF-07-01, SU-INF-08-01, SU-APP-08-01 | Not Run |
| SRS-902 | Un solo retry manuale SMS | UC-04 | UN-112, UN-105 | RSK-107 | TP-902 | SU-APP-03-01, SU-INF-07-01 | Not Run |
| SRS-1001 | Screening solo on-device, no rete | UC-01 | UN-114, UN-111 | RSK-102, RSK-104 | TP-1001 | SU-APP-01-01, SU-INF-01-01 | Not Run |
| SRS-1002 | Nessun dato lascia il dispositivo | UC-03 | UN-111 | RSK-104 | TP-1002 | SU-INF-05-01, SU-INF-08-01 | Not Run |
| SRS-1003 | No PII nei log | UC-03 | UN-113, UN-111 | RSK-103 | TP-1003, TP-901 | SU-INF-08-01 | Not Run |
| SRS-1004 | Degrado graceful fail-open | UC-01 | UN-112, UN-101 | RSK-102 | TP-1004, TP-1202 | SU-APP-08-01, SU-APP-01-01, SU-INF-07-01 | Not Run |
| SRS-1005 | Solo Android 10+ con messaggio | UC-01 | UN-109 | — | TP-1005 | SU-APP-08-01, SU-INF-07-01 | Not Run |

Copertura UN→UC (ogni UN ha almeno un UC): UN-101→UC-01/UC-02 · UN-102→UC-02 · UN-103→UC-02/UC-04 · UN-104→UC-03/UC-05 · UN-105→UC-04/UC-08 · UN-106→UC-05/UC-06 · UN-107→UC-05/UC-07 · UN-108→UC-06/UC-07 · UN-109→UC-01 · UN-110→UC-03/UC-07 · UN-111→UC-01/UC-03 · UN-112→UC-01/UC-02/UC-04 · UN-113→UC-02/UC-03 · UN-114→UC-01/UC-02.

---

## 3. Risk Control Coverage

> Ogni controllo di CG-RSK-001 è implementato da almeno un SRS e verificato da almeno un TP. Dettaglio pericoli in CG-RSK-001; qui il sunto operativo.

| RSK | Hazard | Risk Control Measure | SRS | Test Cases | Test Status |
|---|---|---|---|---|---|
| RSK-101 | Legittima/urgente trattata da sconosciuta e disconnessa prima dello squillo | Pass garantito per rubrica/whitelist; blacklist prevalente esplicita; precedente ordinato; storia con richiamata 1-tap | SRS-302, SRS-303, SRS-703 | TP-302, TP-303, TP-703, TP-1101 | Not Run |
| RSK-102 | Screening oltre timeout / ruolo mancante / OEM aggressivo → spam passa o suoneria in stallo | Solo lookup locali on-device entro timeout; stato bloccante senza ruolo; fail-open; nessun I/O lento in screening | SRS-201, SRS-202, SRS-301, SRS-302, SRS-1001, SRS-1004 | TP-201, TP-202, TP-301, TP-1001, TP-1004, TP-1202 | Not Run |
| RSK-103 | PII (numeri/corpi SMS) in log, crash report, diagnostica | Divieto PII nei log (solo hash/prefissi); scrub in DiagnosticsLogger; errori senza PII extra né stack trace | SRS-901, SRS-1003 | TP-901, TP-1003 | Not Run |
| RSK-104 | Storia/liste/SMS leggibili da altri soggetti (altre app, backup, accesso fisico) | Store solo app-private, nessun provider esportato, nessuna sync/analytics/backup con PII; screening senza rete | SRS-1001, SRS-1002 | TP-1001, TP-1002 | Not Run |
| RSK-105 | Rigetto/rimozione Play per permessi SMS restricted | Permessi minimi dichiarati con feature-gate; toggle default-OFF per blacklist; triage solo foreground; readiness declaration + fallback solo-rifiuto | SRS-103, SRS-203, SRS-601 | TP-103, TP-203, TP-502, TP-601, TP-1203 | Not Run |
| RSK-106 | Perdita cronologia/liste/testo a reboot/update/crash | Persistenza Room/transazionale per storia, liste, template e flag; migrazioni testate | SRS-102, SRS-401, SRS-403, SRS-705 | TP-102, TP-401, TP-403, TP-705, TP-1201 | Not Run |
| RSK-107 | Invii SMS incontrollati (multipli, target errato, costi) | Exactly-once per rifiuto; skip short-code/anonimi/non-composti; skip blacklist se flag OFF; un solo retry manuale, mai background | SRS-103, SRS-304, SRS-305, SRS-501, SRS-502, SRS-902 | TP-304, TP-305, TP-501, TP-502, TP-902, TP-1102 | Not Run |
| RSK-108 | Misclassification 1-tap (spam in whitelist / legittimo in blacklist) | Due CTA etichettate; classificazione con source+timestamp; mutua esclusione; undo/promozione reversibile da dettaglio e cronologia | SRS-602, SRS-603, SRS-604, SRS-702, SRS-704 | TP-602, TP-603, TP-604, TP-702, TP-1103 | Not Run |
| RSK-109 | Risposte SMS non viste finché l'app non si apre (numero resta non classificato) | Triage foreground dichiarato + badge/notifica con deep-link alla vista; richiamate restano rifiutate con SMS fino a classificazione | SRS-601 | TP-601, TP-1104 | Not Run |

Rischi residui noti da CG-RSK-001 (ALARP, non gap): RSK-101 MEDIO (falso positivo mai azzerabile), RSK-105 MEDIO (policy Play), RSK-109 MEDIO (triage differito). Gate di release: TP-1003, TP-301/TP-1202, TP-1201, TP-1203, TP-1101 devono essere verdi.

---

## 4. Test Coverage Summary

> Conteggi derivati dalle tabelle sopra e da CG-TP-001 §5–§6. Esecuzione (TER) non ancora emessa: tutti i TP risultano Not Run.

| Metric | Count | Notes |
|---|---|---|
| Total Use Cases (UC) | 8 | UC-01…UC-08 (CG-UC-001) |
| Total User Needs (UN) | 14 | UN-101…UN-114 (CG-UN-001); tutte legate ad almeno un UC |
| Total Risk Items (RSK) | 9 | RSK-101…RSK-109 (CG-RSK-001) |
| Total Requirements (SRS) | 37 | SRS-101…SRS-1005 (CG-SRS-001) |
| SRS requirements with ≥ 1 test case | 37 | Gap = 0 |
| SRS requirements with ≥ 1 SU | 37 | Gap = 0 (verifica §12 di CG-SDS-001) |
| Total Test Cases (TP) | 46 | TP-101…TP-103, TP-201…TP-203, TP-301…TP-307, TP-401…TP-403, TP-501…TP-503, TP-601…TP-604, TP-701…TP-705, TP-801…TP-802, TP-901…TP-902, TP-1001…TP-1005, TP-1101…TP-1104, TP-1201…TP-1203 |
| Test Cases — Pass | 0 | Da CG-TER-001 (non ancora emesso) |
| Test Cases — Fail | 0 | Deve essere 0 alla release |
| Test Cases — Not Run | 46 | Deve essere 0 alla release; esecuzione pianificata prima dell'approvazione |
| Risk controls with ≥ 1 test case | 9 | Gap = 0 |

---

## 5. Coverage Gap Register

> Nessun gap strutturale aperto: ogni SRS ha TP e SU, ogni UN ha UC+SRS, ogni controllo RSK ha TP. Resta solo il gap di esecuzione (TER non emesso), che blocca l'approvazione.

| Gap ID | Type | Description | Affected IDs | Owner | Status |
|---|---|---|---|---|---|
| GAP-01 | Test Execution | Esecuzione non ancora svolta: 46 TP in Not Run, nessun TER emesso. Bloccante per Approved. | Tutti i TP; tutti gli SRS | QA | Open |
| GAP-02 | Missing Test | Nessuno: ogni SRS-101…SRS-1005 ha ≥1 TP (fonte CG-TP-001 §5). | — | Aldo (PM) | Resolved |
| GAP-03 | Missing SU | Nessuno: ogni SRS ha ≥1 SU (fonte CG-SDS-001 §12); nessuna SU orfana. | — | Aldo (PM) | Resolved |
| GAP-04 | Missing SRS | Nessuno: ogni UN-101…UN-114 ha ≥1 SRS derivato (vedi §2). | — | Aldo (PM) | Resolved |
| GAP-05 | Unverified RSK Control | Nessuno: ogni RSK-101…RSK-109 ha ≥1 TP (fonte CG-TP-001 §6). | — | Aldo (PM) | Resolved |

Regola di approvazione: GAP-01 si chiude solo con TER tutto-verde (inclusi i gate TP-1003, TP-301/TP-1202, TP-1201, TP-1203, TP-1101); i rischi residui RSK-101/105/109 restano in ALARP come da CG-RSK-001.

---

*End of Document — CG-TRM-001 v0.1.0*
