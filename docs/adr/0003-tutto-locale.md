# Tutto sul telefono: nessun backend, nessuna telemetria

L'app tratta i dati più sensibili che ci siano su un telefono: la rubrica, chi chiama, il testo dei messaggi. Un backend — anche solo per «migliorare» le regole o contare gli utenti — significherebbe portare quei dati fuori dal dispositivo, con privacy policy, trattamento del dato, e una superficie di rischio che nessuno chiede.

Abbiamo deciso che Spam Saver è **interamente locale**: nessun server, nessun account, nessuna sincronizzazione, nessun SDK di analisi o crash reporting. Rubrica, whitelist, elenco degli interrogati, storico dei respinti e messaggi vivono solo sul dispositivo. La privacy policy diventa una riga vera — *nessun dato lascia il telefono* — che su Google Play è anche un argomento di fiducia in una categoria dove gli utenti temono il contrario.

Considerato e scartato: **crash reporting anonimo** — utile quando gli utenti sono tanti, ma è un SDK di terze parti e una voce in più da dichiarare: si aggiunge dopo, se serve; **backend per reputazione dei numeri condivisa** — cambia il prodotto (da «chiedo chi è» a «decido io chi sei»), e trascina moderazione, responsabilità e trattamento di dati di terzi.
