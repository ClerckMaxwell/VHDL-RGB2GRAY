# 🎨 Approssimazione RGB to Grayscale (RGB2GRAY) con Somme di Potenze di Due

Questo progetto implementa una conversione da un'immagine a colori RGB a un'immagine in scala di grigi (**Grayscale**) ottimizzata per l'**hardware** (FPGA o ASIC) utilizzando approssimazioni basate su **somme di potenze di due** e un meccanismo dedicato per la **gestione del resto (remainder handling)**.

## 🌟 Obiettivo del Progetto

L'obiettivo principale era sviluppare un algoritmo efficiente per la conversione RGB2GRAY che potesse essere implementato con sole operazioni di **shift a destra (right shift)** e **somma (addition)**, evitando le costose moltiplicazioni. Questo è stato ottenuto approssimando i coefficienti di luminanza standard ai valori più vicini espressi come somme di frazioni $1/2^n$.

***

## ⚙️ Formula e Approssimazione

La formula standard per la conversione alla scala di grigi è:

$$
\text{Gray}_{\text{pixel}} = 0.299 \cdot \text{Pix}_R + 0.587 \cdot \text{Pix}_G + 0.114 \cdot \text{Pix}_B
$$

Per l'ottimizzazione hardware, i coefficienti sono stati approssimati come somme di potenze di due:

| Canale | Coefficiente Reale | Approssimazione (Somma di Potenze di Due) | Valore Approssimato | Errore di Stima |
| :---: | :---: | :---: | :---: | :---: |
| **Rosso (R)** | 0.299 | $\frac{1}{4} + \frac{1}{32} + \frac{1}{64}$ | 0.296875 | 0.2125% (sottostima)|
| **Verde (G)** | 0.587 | $\frac{1}{2} + \frac{1}{16} + \frac{1}{64} + \frac{1}{128}$ | 0.5859375 | 0.10625% (sottostima) |
| **Blu (B)** | 0.114 | $\frac{1}{16} + \frac{1}{32} + \frac{1}{64} + \frac{1}{128}$ | 0.1171875 | 0.31875% (sovrastima) |

**Nota Importante:** La somma dei coefficienti reali ($0.299 + 0.587 + 0.114$) è pari a **1**, così come la somma delle approssimazioni in potenze di due.

***

## 🧮 Gestione del Resto (Remainder Handling)

]L'approccio basato sui soli shift comporta l'introduzione di un errore dovuto al **troncamento** (semplice taglio del vettore) dei risultati. L'obiettivo della gestione del resto è correggere l'errore risultante dall'approssimazione mediante un'analisi del resto.

**Concetto di base:**
Il metodo non scarta i resti, ma li salva, li sposta in un vettore dedicato e li somma tra loro. Questa somma dei resti frazionari (ad es. $0.5 + 0.4 + 0.2 = 1.1$) determina se una cifra intera (`+1`) debba essere aggiunta al calcolo finale.

Questo processo è implementato attraverso operazioni logiche che estraggono il resto (i bit meno significativi persi durante lo shift) e lo riallineano per la somma successiva.



***

## ⚡ Risultati e Prestazioni

L'implementazione finale ha dimostrato prestazioni elevate con un utilizzo ottimizzato delle risorse:

* **Livelli di Pipeline:** 10 livelli di pipeline in totale.
* **Periodo di Clock:** Funziona a **2.9 ns** di periodo di clock.
* **Hardware Utilizzato:** Solo alcuni registri di pipeline, **sette 8-bit Carry-save** (a quattro operandi) e **due 8-bit Adder**.
* **Accuratezza:** L'errore su ogni pixel rimane compreso tra **-1 e +1**.

***

## 👤 Autore

**Raffaele Petrolo** 
