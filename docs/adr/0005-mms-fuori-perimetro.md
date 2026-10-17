# Gli MMS restano fuori perimetro

Chi è gestore SMS predefinito si prende anche gli MMS: Android consegna al predefinito `WAP_PUSH_DELIVER`, e gestirli significa scaricare l'allegato, mostrarlo nel thread e permettere di rispondere. È un mondo a parte (APN, download con data connection, notifiche di scaricamento, permessi) che non serve al cuore del prodotto — chiedere a chi chiama chi è.

Abbiamo deciso che Spam Saver gestisce **solo SMS**: la faccia «client» legge, scrive e notifica i messaggi di testo, con thread, archiviazione e risposte rapide. Gli MMS non sono gestiti, e la conseguenza va detta senza addolcirla: **un MMS in arrivo non si vedrebbe**. Su Google Play un gestore predefinito deve saper svolgere la funzione per cui è predefinito — inviare e ricevere SMS — e quello l'app lo fa; l'MMS è lavoro in più che si riprende quando c'è un motivo.

Considerato e scartato: **MMS in sola ricezione** — notificare e scaricare senza poter rispondere a un MMS: un mezzo servizio, che però elimina il buco del messaggio che sparisce in silenzio; da valutare se il buco pesa più del lavoro; **MMS completi** — il lavoro più grosso, utile a una minoranza di utenti: da fare solo se gli utenti lo chiedono.
