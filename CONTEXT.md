# Spam Saver

App Android che difende il telefono dalle chiamate indesiderate **chiedendo a chi chiama di identificarsi**: se il numero non è in rubrica né nella whitelist dell'app, la chiamata è respinta e al numero parte un SMS che chiede chi è. Le risposte si leggono dentro l'app, e da lì si decide se sbloccare il numero o lasciarlo bloccato.

È anche il **gestore SMS predefinito** del telefono: legge, scrive e notifica gli SMS, quindi è l'app con cui si leggono e si mandano i messaggi.

## Language

**Numero sconosciuto**:
Un numero che chiama e non è né in rubrica né in whitelist. È l'unico concetto che l'app distingue: non esistono «spam» o «numeri indesiderati», esistono numeri che conosciamo e numeri che non conosciamo.
_Avoid_: spam, mittente indesiderato, blacklist (l'app non ha una blacklist)

**Rubrica**:
I contatti del telefono. Un numero in rubrica passa sempre, senza chiedere niente a nessuno.
_Avoid_: contatti dell'app

**Whitelist**:
L'elenco dei numeri che l'app lascia passare pur non essendo in rubrica.
_Avoid_: lista bianca, numeri fidati

**Rifiuto**:
Il respingere una chiamata in arrivo da un numero sconosciuto, senza che il telefono squilli.
_Avoid_: blocco della chiamata, filtro

**SMS di identificazione** (`chi sei?`):
Il messaggio che parte automaticamente verso un numero sconosciuto dopo il rifiuto, per chiedere chi è. Parte **una volta sola per numero, per sempre**: il numero resta «interrogato» anche se non risponde, anche se richiama, anche dopo un riavvio.
_Avoid_: messaggio di cortesia, auto-risposta

**Interrogato**:
Un numero a cui l'SMS di identificazione è già stato mandato. L'app ne tiene memoria per non riscrivergli mai più.

**Sblocco**:
Il far passare un numero sconosciuto: o lo si mette in **whitelist** dall'app, o lo si aggiunge alla **rubrica** del telefono. Sono due strade con lo stesso effetto — la rubrica è già una whitelist.
_Avoid_: autorizzazione, permesso

**Bloccato**:
Un numero sconosciuto che l'app continua a respingere. Resta bloccato **finché non lo si sblocca**: non esistono sblocchi automatici, scadenze o «dopo N chiamate passa».

**Tetto giornaliero**:
Il numero massimo di SMS di identificazione che l'app manda in un giorno. Oltre il tetto l'app respinge ancora, ma non scrive, e lo dice all'utente.
_Avoid_: limite di spesa, quota

**Conversazione**:
Lo scambio di SMS con un numero, letto e scritto dentro Spam Saver. Comprende la conversazione con i numeri interrogati — è lì che si legge la loro risposta.

**Gestore SMS predefinito**:
Il ruolo di sistema che fa di Spam Saver l'app responsabile degli SMS: riceve quelli in arrivo, li scrive nel database del telefono e li notifica. Senza questo ruolo l'app non può né mandare l'SMS di identificazione né leggere le risposte.
_Avoid_: app di messaggistica (generico), SMS di sistema

**Ruolo**:
Un incarico di sistema che l'utente assegna all'app: il **gestore SMS predefinito** e lo **screening delle chiamate** («Caller ID & spam»). L'app li chiede in onboarding, prima dei permessi che ne dipendono.

**Storico dei respinti**:
L'elenco delle chiamate respinte, con il numero e quando ha chiamato. È da lì che si sblocca o si lascia bloccato.
_Avoid_: call log (quello è del telefono)
