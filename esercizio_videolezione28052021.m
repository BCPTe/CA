clear all
close all

s=tf('s');

F1 = (s+12)/(s+4);                      % tipo 0
F2 = 2*(s+5)/(s*(s^2+7.2*s+16));        % tipo 1

Kr = 1;
d = 0.5;

% specs richieste
dinf = 0.01;                            % disturbo sull'uscita
einf = 0.1;                             % errore sulla rampa
sens = 1;                               % sensibilità minore di 1 ↓
ws = 20;                                % per pulsazioni minori di 20 rad/s
Mr = 2;                                 % max picco di risonanza

% calcolo per prima cosa i guadagni delle due F
Kf1 = dcgain(F1);
Kf2 = dcgain(s*F2);

Kca = d/(dinf*Kf1);                     % per la specifica sul disturbo
Kcb = Kr/(einf*Kf1*Kf2);                % per la specifica sull'errore

% dopo aver eseguito quanto sopra, trovo Kca = 16.67 e Kcb = 5.33 -->
% dichiaro Kc = 17 perché è il più restrittivo (e l'ho approssimato)
Kc = 17                                 % va bene prendere Kc positivo (spiegazione sul foglio)

Ga1 = Kc*F1*F2;

wcd = 1.5*ws;                           % prendo 1.5 volte la pulsazione che mi viene data come specifica nella sens
mphi = 60-5*Mr;                         % da Nichols trovo ca. 46°, da questa relazione invece 50° --> prendo questa per avere un margine maggiore

figure,bode(Ga1)                        % trovo modulo=-27.9 e fase=-190°
% devo quindi recuperare 10+50=60° di fase e 27.9 dB in modulo

% tentativo 1 --> due reti derivatrici: una da 3 ed una da 4
md1 = 3;
xd1 = sqrt(md1);
taud1 = xd1/wcd;
Rd1 = (s*taud1+1)/(s*taud1/md1+1);

md2 = 4;
xd2 = sqrt(md2);
taud2 = xd2/wcd;
Rd2 = (s*taud2+1)/(s*taud2/md2+1);

Ga2 = Ga1 * Rd1 * Rd2;
figure,bode(Ga2)                        % trovo mod=-17.1dB (mancano ancora 17.1dB da recuperare) e fase=-123° (OK: ho recuperato 57°)
[m2,f2] = bode(Ga2,wcd)
% NB: ho recuperato meno di 60° ma considerando che avevo approssimato i 46°
% di Nichols a 50°, posso permettermi un margine di 4° (è poco,
% probabilmente non funzionerà ma provo lo stesso)

Kcorr = 1/m2;                           % utilizzo un K correttivo per aumentare il modulo senza toccare le specs statiche e la fase
% lo ridefinisco, aumentandolo, causa specifica sul peak response non soddisfatta (vedi riga 72)
Kcorr = 10;

Ga3 = Ga2*Kcorr;
figure,bode(Ga3)                        % verifico di aver risolto aggiungendo il Kcorr all'anello (OK)
figure,margin(Ga3)                      % risulta che abbiamo recuperato 56.9° e che la nostra wc è a 30 rad/s (OK)
% dopo la correzione del Kcorr da 7.1388 a 8, il recupero è stato di 57.5° a una wc di 33.6 rad/s (ancora OK)
% dopo la correzione del Kcorr da 8 a 9, il recupero è stato di 57.3° a una wc di 37.7 rad/s (ancora OK)
% dopo la correzione del Kcorr da 9 a 10, il recupero è stato di 56.6° a una wc di 41.7 rad/s (ancora OK)

% ora posso scrivere
C = Kc*Kcorr*Rd1*Rd2;

W = feedback(C*F1*F2,1) * Kr;
sens = feedback(1,Ga3);
figure,bode(sens)
[ms,fs] = bode(sens,ws)                 % ms = 0.8348 (è minore di 1 e per w<20 andrà solo a scendere --> OK)
% dopo la correzione del Kcorr (Kcorr=8) ms = 0.7409 (ancora OK)
% dopo la correzione del Kcorr (Kcorr=9) ms = 0.6508 (ancora OK)
% dopo la correzione del Kcorr (Kcorr=10) ms = 0.5776 (ancora OK)

figure,bode(W)                          % il peak response è 2.73dB (NON SODDISFATTA LA RICHIESTA DI ESSERE <=2dB)
% per far diminuire il peak response devo far dimnuire il modulo -->
% ricordandomi che lo avevo già fatto salire tramite il Kcorr, posso
% aumentare quello pe aumentare il modulo (applico  le modifiche
% direttamente alla definizione del Kcorr di sopra, all'inizio valeva
% 1/m2=7.1388 --> man mano lo faccio aumentare