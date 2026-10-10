# Call Guard — Use Cases

**Document ID:** CG-UC-001
**Version:** 0.1.0
**Status:** Draft
**Service:** `call-guard`
**Last Updated:** 2026-10-10
**Trace Parent:** CG-OVW-001

---

## Document Control

| Role | Name | Date | Signature |
|---|---|---|---|
| Author | Aldo (PM) | 2026-10-10 | Aldo |
| Reviewer | — | — | — |
| Approver (QA/RA) | — | — | — |

### Change Log

| Version | Date | Author | Summary of Change |
|---|---|---|---|
| 0.1.0 | 2026-10-10 | Aldo (PM) | Initial draft |

---

## Document Scope

Questo documento definisce gli Use Case di Call Guard, app Android (UI Flutter + modulo nativo Kotlin con `CallScreeningService`, ruolo `ROLE_CALL_SCREENING`, Android 10+) che protegge l'utente dalle chiamate da numeri sconosciuti: rifiuto automatico dei numeri visibili non in rubrica, registrazione del tentativo, SMS automatico di richiesta identificazione, e classificazione rapida (whitelist/blacklist) delle risposte ricevute.

Gli Use Case sono scritti dal punto di vista degli attori (cosa l'attore vuole ottenere e perché), non di come il sistema li implementa internamente.

Documento padre: CG-OVW-001 (Service Overview). Prossimo documento nel pacchetto: CG-UN-001 (User Needs).

Fuori perimetro: iOS, cloud/backend e sincronizzazione multi-dispositivo, chiamate in uscita.

---

## Actor Definitions

| Actor | Description |
|---|---|
| Utente proprietario | Persona che possiede il dispositivo Android, installa e configura Call Guard, consulta le liste e classifica i numeri. Beneficio: non essere disturbato da sconosciuti, con traccia consultabile di ogni tentativo. |
| Chiamante sconosciuto | Persona che chiama da un numero visibile non presente in rubrica/whitelist. Interagisce indirettamente: subisce il rifiuto e riceve l'SMS automatico di richiesta identificazione. |
| Sistema operativo Android | Piattaforma Android 10+ nel ruolo di call screening (`CallScreeningService`, `ROLE_CALL_SCREENING`) e gestione permessi telefono/SMS. Attore tecnico che recapita eventi di chiamata/SMS al modulo nativo. |

---

## UC-01 — Intercettare una chiamata in ingresso prima della suoneria

**Actor:** Sistema operativo Android (primario); Utente proprietario (beneficiario)
**Preconditions:**
- L'app è installata su Android 10+ e all'utente è stato assegnato il ruolo di call screening (`ROLE_CALL_SCREENING`).
- L'utente ha concesso i permessi telefono richiesti.
- Esiste una chiamata in ingresso in arrivo.

**Story:**

Come Utente proprietario, voglio che ogni chiamata in ingresso venga intercettata prima che squilli, in modo da non essere disturbato da numeri sconosciuti. Come Sistema operativo Android, voglio recapitare l'evento di chiamata al servizio di screening entro il timeout di piattaforma, in modo che la decisione (rifiuta/lascia passare) arrivi prima della suoneria.

**Main Flow:**

1. Il Sistema operativo Android notifica al modulo nativo di Call Guard una chiamata in ingresso con il numero chiamante (visibile, nascosto o assente).
2. Il sistema acquisisce numero chiamante, data/ora ed eventuali info disponibili dal carrier.
3. Il sistema valuta le regole di filtro (rubrica, whitelist, blacklist) e restituisce la decisione di screening ad Android entro il timeout di piattaforma.

**Unhappy Paths:**

- Il numero chiamante è nascosto/assente → il sistema non può applicare la regola "numero visibile non in rubrica"; la chiamata segue il comportamento predefinito configurato (passa normalmente) e nessun SMS viene inviato.
- Il ruolo di call screening non è assegnato o è stato revocato → il sistema non riceve l'evento; l'utente viene avvisato in-app di riassegnare il ruolo.
- La risposta supera il timeout di piattaforma → Android applica il comportamento di default (la chiamata squilla); l'evento viene registrato come "non schermato per timeout" senza PII nei log.

**Postconditions:**

- La decisione di screening è stata restituita ad Android prima della suoneria oppure è registrato il mancato screening con motivo.
- I dati acquisiti (numero, data/ora) sono disponibili per gli UC a valle (UC-02/UC-03/UC-05/UC-06).

---

## UC-02 — Rifiutare automaticamente una chiamata da numero sconosciuto

**Actor:** Utente proprietario (beneficiario); Sistema operativo Android (esecutore del rifiuto)
**Preconditions:**
- UC-01 ha intercettato la chiamata con numero visibile.
- Il numero non è in rubrica e non è in whitelist.
- Il numero non è in blacklist con configurazione "rifiuto silenzioso" (caso coperto da UC-06) oppure lo è ma la regola generale coincide nel rifiuto.

**Story:**

Come Utente proprietario, voglio che le chiamate da numeri visibili non in rubrica vengano rifiutate automaticamente senza farmi squillare il telefono, in modo da non essere interrotto da chiamate indesiderate o ambigue.

**Main Flow:**

1. Il sistema confronta il numero chiamante con rubrica, whitelist e blacklist.
2. Il sistema stabilisce che il numero è "sconosciuto" (visibile, non in rubrica, non in whitelist).
3. Il sistema ordina ad Android di disconnettere/silenziare la chiamata prima della suoneria.
4. Il sistema passa il controllo a UC-03 (registrazione) e UC-04 (SMS automatico).

**Unhappy Paths:**

- Il numero risulta in rubrica o in whitelist al momento del controllo → il rifiuto non scatta; si applica UC-05 (la chiamata passa).
- Il numero risulta in blacklist → il rifiuto scatta ma segue UC-06 (eventuale soppressione dell'SMS secondo configurazione).
- Il carrier/rete non consente la disconnessione programmata → la chiamata viene almeno silenziata; l'esito reale (rifiutata/silenziata/non bloccata) è registrato in cronologia.

**Postconditions:**

- La chiamata sconosciuta è stata rifiutata/silenziata senza suoneria per l'utente.
- È stato generato un evento "chiamata rifiutata" con numero, data/ora ed esito, pronto per la registrazione (UC-03).

---

## UC-03 — Consultare la cronologia dei tentativi rifiutati

**Actor:** Utente proprietario
**Preconditions:**
- L'utente apre l'app Call Guard.
- Esiste almeno un evento di chiamata rifiutata registrato (oppure la lista è vuota alla prima installazione).

**Story:**

Come Utente proprietario, voglio vedere la lista di tutte le chiamate rifiutate con numero, data/ora, esito e stato dell'SMS, in modo da avere una traccia consultabile di chi ha provato a chiamarmi e decidere come classificare ciascun numero.

**Main Flow:**

1. L'utente apre la vista "Cronologia chiamate".
2. Il sistema mostra l'elenco dei tentativi in ordine cronologico inverso, ciascuno con: numero, data/ora, esito (rifiutata/silenziata), stato SMS inviato, note.
3. L'utente seleziona una voce per vederne il dettaglio e le azioni disponibili (vai a UC-07/UC-08).

**Unhappy Paths:**

- Nessun tentativo registrato → il sistema mostra uno stato vuoto esplicativo ("Nessuna chiamata rifiutata finora"), non un errore.
- Dati locali corrotti o illeggibili → il sistema mostra un errore di lettura senza perdere gli altri record; nessun PII viene scritto nei log.

**Postconditions:**

- L'utente ha consultato la cronologia persistente dei tentativi.
- La voce selezionata (se presente) è pronta per la classificazione in whitelist/blacklist.

---

## UC-04 — Inviare un SMS automatico di richiesta identificazione

**Actor:** Sistema operativo Android (recapito SMS); Chiamante sconosciuto (destinatario); Utente proprietario (configuratore del testo)
**Preconditions:**
- Una chiamata è stata rifiutata secondo UC-02 e il numero è visibile e raggiungibile via SMS.
- Il permesso `SEND_SMS` è concesso.
- Esiste un testo SMS configurato (default precompilato se l'utente non l'ha modificato).

**Story:**

Come Utente proprietario, voglio che ogni numero sconosciuto rifiutato riceva subito un SMS che chiede di identificarsi via SMS, in modo da dare ai chiamanti legittimi un canale per presentarsi senza farmi squillare. Come Chiamante sconosciuto, voglio ricevere un messaggio chiaro sul perché la chiamata è stata rifiutata e su cosa fare per essere ricontattato.

**Main Flow:**

1. Subito dopo il rifiuto, il sistema compone l'SMS con il testo configurato dall'utente. Testo di default: "La chiamata è stata automaticamente rifiutata dal ricevente perché il suo numero è sconosciuto, le preghiamo di inviare un sms con le informazioni necessarie alla sua identificazione."
2. Il sistema invia l'SMS al numero rifiutato tramite il gestore SMS di Android.
3. Il sistema aggiorna la voce di cronologia (UC-03) con lo stato "SMS inviato / non inviato + motivo".

**Unhappy Paths:**

- Permesso `SEND_SMS` mancante o revocato → l'SMS non viene inviato; la cronologia riporta "SMS non inviato: permesso mancante" e l'utente viene guidato a ripristinarlo.
- Invio fallito (rete/carrier non disponibile, numero non valido per SMS) → il sistema registra "SMS non inviato: errore di invio" e non ritenta all'infinito; la chiamata resta comunque registrata come rifiutata.
- Il numero è in blacklist con configurazione "rifiuto senza SMS" → l'invio è soppresso intenzionalmente (vedi UC-06) e lo stato registrato è "SMS soppresso da configurazione".

**Postconditions:**

- L'SMS di richiesta identificazione è stato inviato oppure è registrato il motivo della mancata spedizione.
- La voce di cronologia riporta lo stato SMS aggiornato.

---

## UC-05 — Lasciare passare una chiamata da numero in whitelist

**Actor:** Utente proprietario (beneficiario); Sistema operativo Android (esecutore)
**Preconditions:**
- UC-01 ha intercettato la chiamata con numero visibile.
- Il numero è presente in whitelist (inserito manualmente o promosso via UC-07).

**Story:**

Come Utente proprietario, voglio che i numeri di cui mi fido (whitelist) squillino sempre normalmente, in modo da non perdere mai le chiamate importanti dopo aver classificato un numero una sola volta.

**Main Flow:**

1. Il sistema confronta il numero chiamante con la whitelist.
2. Il sistema riconosce la corrispondenza in whitelist.
3. Il sistema comunica ad Android di lasciare passare la chiamata, che squilla normalmente; nessun SMS viene inviato.

**Unhappy Paths:**

- Corrispondenza ambigua per formato (es. prefisso internazionale vs formato locale) → il sistema applica la normalizzazione configurata; se l'ambiguità resta, la chiamata passa (fail-open verso l'utente noto) ed è registrata come "passata per match incerto".
- Whitelist modificata in concorrenza durante lo screening → vale lo stato letto all'istante della decisione; la modifica avrà effetto dalla chiamata successiva (vedi UC-10).

**Postconditions:**

- La chiamata da numero in whitelist è passata normalmente.
- Nessuna voce di "chiamata rifiutata" e nessun SMS sono generati per questo evento.

---

## UC-06 — Rifiutare sempre una chiamata da numero in blacklist

**Actor:** Utente proprietario (beneficiario); Sistema operativo Android (esecutore)
**Preconditions:**
- UC-01 ha intercettato la chiamata con numero visibile.
- Il numero è presente in blacklist.

**Story:**

Come Utente proprietario, voglio che i numeri che ho bandito vengano sempre rifiutati senza disturbarmi, in modo da bloccare stabilmente chiamanti indesiderati già identificati.

**Main Flow:**

1. Il sistema confronta il numero chiamante con la blacklist.
2. Il sistema riconosce la corrispondenza in blacklist.
3. Il sistema ordina ad Android di rifiutare/silenziare la chiamata.
4. Il sistema applica la configurazione "invio SMS per blacklist" (default: nessun SMS) e registra il tentativo in cronologia.

**Unhappy Paths:**

- Configurazione "nessun SMS per blacklist" attiva → l'SMS è soppresso intenzionalmente; la cronologia riporta "SMS soppresso da configurazione".
- Il numero è contemporaneamente in rubrica/whitelist e blacklist (stato incoerente) → prevale la regola più protettiva (rifiuto) e il sistema segnala l'incoerenza all'utente per la bonifica in UC-08.

**Postconditions:**

- La chiamata da numero in blacklist è stata rifiutata.
- Il tentativo è registrato in cronologia con esito e stato SMS coerenti con la configurazione.

---

## UC-07 — Classificare un numero dalla risposta SMS all'apertura dell'app

**Actor:** Utente proprietario
**Preconditions:**
- L'utente apre l'app Call Guard.
- Il permesso di lettura SMS è concesso.
- È arrivato almeno un SMS in ingresso (tipicamente la risposta a UC-04) oppure la vista è vuota.

**Story:**

Come Utente proprietario, voglio che all'apertura dell'app le risposte SMS ricevute siano mostrate con il numero mittente e con due azioni rapide "Accetta (whitelist)" e "Rifiuta (blacklist)", in modo da promuovere o bandire ciascun numero in pochi secondi in base a come si presenta.

**Main Flow:**

1. All'apertura dell'app, il sistema intercetta/legge gli SMS in ingresso e mostra la vista dedicata con mittente, testo, data/ora e numero collegato alla cronologia chiamate quando possibile.
2. L'utente legge la presentazione del chiamante e tocca "Accetta (whitelist)" oppure "Rifiuta (blacklist)".
3. Il sistema sposta il numero nella lista scelta, con data di aggiunta, e aggiorna immediatamente il comportamento di filtro (vedi UC-10).
4. Il sistema conferma l'azione e offre l'editing del profilo (nome, note, categoria — vedi UC-08).

**Unhappy Paths:**

- Nessun SMS ricevuto → il sistema mostra uno stato vuoto esplicativo, non un errore.
- Permesso di lettura SMS mancante → la vista non può popolarsi; l'utente viene guidato a concedere il permesso.
- SMS da numero senza precedente chiamata registrata → il messaggio è comunque mostrato e classificabile; il collegamento alla cronologia resta assente.
- Doppia classificazione (numero già in lista opposta) → il sistema chiede conferma dello spostamento ed evita duplicati.

**Postconditions:**

- Il numero è inserito in whitelist o blacklist con data di aggiunta.
- Le chiamate future da quel numero seguono immediatamente UC-05 o UC-06.

---

## UC-08 — Gestire whitelist, blacklist e profilo del numero

**Actor:** Utente proprietario
**Preconditions:**
- L'utente apre la vista "Whitelist" o "Blacklist".

**Story:**

Come Utente proprietario, voglio aggiungere e rimuovere numeri dalle liste e modificare il profilo di ciascun numero (nome, note, categoria, data di aggiunta), in modo da tenere le liste accurate nel tempo quando un contatto cambia o ho classificato male un numero.

**Main Flow:**

1. L'utente apre la whitelist o la blacklist e vede l'elenco (numero, nome, categoria, data di aggiunta).
2. L'utente aggiunge un numero (manuale o da cronologia/SMS), lo rimuove, oppure ne modifica il profilo (nome, note, categoria).
3. Il sistema valida l'input (formato numero), salva in persistenza locale e conferma l'operazione.
4. Il nuovo stato ha effetto immediato sul filtro delle chiamate future (vedi UC-10).

**Unhappy Paths:**

- Numero in formato non valido o duplicato nella stessa lista → il sistema rifiuta il salvataggio segnalando il campo specifico; nessun dato viene scritto.
- Tentativo di inserimento simultaneo nelle due liste → il sistema lo vieta e propone lo spostamento esplicito con conferma.
- Rimozione di un numero inesistente (già rimosso) → il sistema informa senza errore critico; le liste restano consistenti.

**Postconditions:**

- Whitelist e blacklist persistono localmente e sopravvivono al riavvio.
- Il profilo del numero (nome, note, categoria, data di aggiunta) è aggiornato.
- Il comportamento di filtro futuro riflette immediatamente le modifiche.

---

## UC-09 — Configurare il testo dell'SMS automatico

**Actor:** Utente proprietario
**Preconditions:**
- L'utente apre le impostazioni dell'app.
- È presente il testo di default precompilato.

**Story:**

Come Utente proprietario, voglio modificare il testo dell'SMS automatico partendo dal default precompilato, in modo che i chiamanti rifiutati ricevano un messaggio nel tono e nella lingua che preferisco.

**Main Flow:**

1. L'utente apre l'impostazione "Testo SMS automatico" e vede il testo corrente (alla prima apertura: "La chiamata è stata automaticamente rifiutata dal ricevente perché il suo numero è sconosciuto, le preghiamo di inviare un sms con le informazioni necessarie alla sua identificazione.").
2. L'utente modifica e salva il testo.
3. Il sistema valida (non vuoto, lunghezza entro il limite SMS/configurato) e lo persiste localmente.
4. Il sistema conferma; il nuovo testo sarà usato dal successivo UC-04.

**Unhappy Paths:**

- Testo vuoto → il sistema rifiuta il salvataggio e mantiene il testo precedente, segnalando il problema.
- Testo oltre la lunghezza massima → il sistema rifiuta o propone la suddivisione secondo la configurazione, senza troncare in silenzio.
- Salvataggio fallito (storage non disponibile) → il sistema informa l'utente; resta valido il testo precedente.

**Postconditions:**

- Il testo SMS personalizzato è persistito localmente e sopravvive al riavvio.
- I successivi invii automatici (UC-04) usano il nuovo testo.

---

## UC-10 — Applicare immediatamente una decisione di classificazione al filtro

**Actor:** Utente proprietario (decisore); Sistema operativo Android (applicatore alla chiamata successiva)
**Preconditions:**
- L'utente ha appena classificato o modificato un numero (UC-07 o UC-08).

**Story:**

Come Utente proprietario, voglio che ogni decisione di whitelist/blacklist cambi subito il destino delle chiamate future da quel numero, in modo da fidarmi che "accetta" significhi "squillerà" e "rifiuta" significhi "non mi disturberà più".

**Main Flow:**

1. Dopo ogni inserimento, spostamento, rimozione o modifica profilo (UC-07/UC-08), il sistema aggiorna lo stato di filtro in memoria e in persistenza locale.
2. Alla successiva chiamata da quel numero, UC-01 legge lo stato aggiornato e applica UC-05 (passa) oppure UC-02/UC-06 (rifiuta).
3. Il sistema mostra all'utente un riscontro coerente ("Da ora questo numero squillerà normalmente" / "Da ora questo numero sarà rifiutato").

**Unhappy Paths:**

- Chiamata già in corso di screening al momento della modifica → vale lo stato letto all'istante della decisione; la modifica si applica dalla chiamata successiva e l'utente ne è informato se chiede.
- Persistenza non disponibile al momento del salvataggio → la modifica resta attiva in memoria per la sessione e il sistema segnala di riaprire l'app per consolidarla; nessuna decisione viene persa in silenzio.

**Postconditions:**

- Lo stato di filtro riflette l'ultima decisione dell'utente in memoria e in persistenza locale.
- Le chiamate future sono instradate secondo le regole aggiornate (RF-2/RF-5/RF-6).

---

## Traceability Matrix

La User Needs (CG-UN-001) non è ancora redatta: la colonna UN Trace è riservata e valorizzata come TBD. La colonna RF Trace garantisce fin da ora la copertura di ogni requisito funzionale del brief.

| UC ID | Title | RF Trace | UN Trace |
|---|---|---|---|
| UC-01 | Intercettare una chiamata in ingresso prima della suoneria | RF-1 | TBD (UN da redigere) |
| UC-02 | Rifiutare automaticamente una chiamata da numero sconosciuto | RF-2 | TBD (UN da redigere) |
| UC-03 | Consultare la cronologia dei tentativi rifiutati | RF-3 | TBD (UN da redigere) |
| UC-04 | Inviare un SMS automatico di richiesta identificazione | RF-4 | TBD (UN da redigere) |
| UC-05 | Lasciare passare una chiamata da numero in whitelist | RF-5 | TBD (UN da redigere) |
| UC-06 | Rifiutare sempre una chiamata da numero in blacklist | RF-6 | TBD (UN da redigere) |
| UC-07 | Classificare un numero dalla risposta SMS all'apertura dell'app | RF-7 | TBD (UN da redigere) |
| UC-08 | Gestire whitelist, blacklist e profilo del numero | RF-8 | TBD (UN da redigere) |
| UC-09 | Configurare il testo dell'SMS automatico | RF-9 | TBD (UN da redigere) |
| UC-10 | Applicare immediatamente una decisione di classificazione al filtro | RF-10 | TBD (UN da redigere) |

---

*End of Document — CG-UC-001 v0.1.0*
*Next in package: CG-UN-001 — User Needs*
