%% inizializzazione
clear all
close all
s = tf('s');

% NB: tutti i dettagli e le formule sono spiegate sul foglio allegato

%% inserimento dati
F1 = (1+s/0.1)/((1+s/0.2)*(1+s/10));
F2 = 1/s;
Kr = 1;
d = 1.5

%% calcolo dei guadagni
Kf1 = dcgain(F1);
Kf2 = dcgain(s*F2);


%% inserimento specs richieste
einfgrad = 0;                       % errore di inseguimento al gradino
einfparab = 0.16;                   % errore di inseguimento alla parabola
dinf = 0.05;                        % disturbo sull'uscita
wbd = 4;                            % banda passante cira 4 +- 10%
sovrmax = 0.25;                     % sovraelongazione massima

% SVOLGIMENTO:
%% 1) specifica sull'errore di inseguimento al gradino unitario
% sistema di tipo 1 -> sempre soddisfatta

%% 2) specifica sull'errore di inseguimento alla parabola t^2/2
% NB: devo inserire un polo
Kcb = Kr/(0.16*Kf1*Kf2);

%% 3) specifica sul disturbo sull'uscita in assenza di disturbi
% G1 tipo 1 e G2 tipo 1 -> sempre soddisfatta

%% dichiarazione del Kc
% verifica del segno del Kc:
% Kf1*Kf2                             % dev'essere > 0 per avere Kc positivo (OK)
% pole(F1)                            % no poli a parte reale positivi (OK)
% pole(F2)                            % no poli a parte reale positivi (OK)
% bode(F1*F2)                         % un solo punto a 0 dB ed un solo punto a -180° (OK)
% posso quindi dichiarare Kc positivo:
Kc = Kcb                            

%% 4) specifica sulla banda passante
wcd = 0.63 * wbd;                   % wcd = 2.52 rad/s
wcd = 1.9;                          % sostituzione dopo fallimento requisito sula wb
%% specifica sulla sovralongazione massima
Mr = 20*log10((1+sovrmax)/0.9);

%% prima chiusura
Ga1 = Kc/s*F1*F2/(1/Kr);

figure,bode(Ga1)                    % trovo mod=5.59dB e fase=-192°
% verifico quanto devo recuperare da Nichols a 2.85dB (Mr) --> circa 43°
mphi = 60 - 5 * Mr                  % da qui ricavo invece 45.7°
% alla luce di ciò decido quindi di recuperare circa 45.7°+12°(derivano da -192 di bode) = 60° --> dovrei
% arrivare ad un modulo di 6*2(a cause delle derivatrici)+5.59 dB
% NB: posso accontentarmi di minimo 43°(Nichols)+12°=55°

%% reti derivatrici
% tentativo 1: inserisco due reti derivatrici da 3 --> failed
% tentativo 2: inserisco due reti derivatrici, una da 3 ed una da 4 --> failed
% tentativa 3: inserisco due reti derivatrici da 4
md1 = 4;
xd1 = sqrt(md1);
taud1 = xd1/wcd;
Rd1 = (1+s*taud1)/(1+s*taud1/md1);

Ga2 = Ga1*Rd1^2;
figure,bode(Ga2)                    % trovo infatti una fase=-118° (OK, recuperato 62°>60°) e un mod=17.6dB (da ridurre con reti attenuatrici)
% dopo la modifica di wcd da 2.52 a 1.9 trovo: fase=-114° e mod=22.6dB

%% reti attenuatrici
% tentivo 1: inserisco una rete attenuatrice da 8 per ridurre circa 18dB di modulo --> failed
mi1 = 13;                          % ho ridotto la mi1 da 8 a 7.6 per avere una rete "meno attenuatrice" e mantenere la wcd nel range
xi1 = 100;
taui1 = xi1/wcd;
Ri1 = (1+s*taui1/mi1)/(1+s*taui1);
% figure,bode((1+s/m1)/(1+s))       % disegno una rete attenuatrice tale da perdere esattamente circa 17.6dB (m1)
%                                   % trovo che a x=100 perderei 17.6dB, per cui dichiaro le variabili:
% xi1 = 100;
% taui1 = xi1/wcd
% Ri1 = (1+s*taui1/m1)/(1+s*taui1);

% NON HA FUNZIONATO --> wb maggiore di 4.4 (circa 5.4)

Ga3 = Ga2*Ri1;
figure,bode(Ga3)                    % trovo mod=-0.04dB (OK) e fase=-122° (OK, recuperato comunque 58°>55° (minimo da Nichols))

% provo quindi a chiudere l'anello
figure,margin(Ga3)                  % 58° a 2.53 rad/s (OK)

%% chiusura
% suppongo questo sia il controllore che cerco e ne dichiaro la funzione:
C = Kc/s*Rd1^2*Ri1
Ga = C*F1*F2;
W = feedback(Ga, 1/Kr)

% verifica sul tempo di salita
figure,step(W)                      % trovo ts=0.5s
% verifica sul picco di risonanza
figure,bode(W)                      % trovo peakresponse=2.21dB e wb(w a -3dB)=5.23 !TROPPO DISTANTE DA wbd (req non soddisfatto)!
% decido quindi di far diminuire wc in modo da far diminuire anche wb:
% provo a fare una proporzione del tipo 5.32 : 2.52 = 4 : wcd --> wcd = 1.9
% lo sostituisco sopra...
wb = 4.11                           % DOPO LA CORREZIONE DI wcd, trovo da bode sopra questa wb, finalmente valida.

%% calcolo specs x
wd = 0.5;
sens = feedback(1,Ga3)
[ms,fs] = bode(sens,wd)
err = ms*Kr

%% discretizzazione
alpha = 5;                           % metto 5 perché con 20 veniva estremamente piccolo
T = 2*pi/(alpha*wb);
Gazoh = Ga/(1+s*T/2);
Cz = c2d(C, T, "tustin")
Fz = c2d(F1*F2, T, "tustin")
Wz = feedback(Cz*Fz,1)