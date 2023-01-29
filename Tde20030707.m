%% inizializzazione
clear all
close all
s = tf('s');

%% dati
F1 = 5/s;
F2 = (s+20)/((s+1)*(s+5)^2);
Kr = 1;

%% specs richieste
einf = 0.05;
d1inf = 0.01;
d2inf = 0.01;

tsd = 1;
Mrmax = 2.5;

%% calcolo guadagni
Kf1 = dcgain(s*F1);
Kf2 = dcgain(F2);

%% specifiche statiche (calcolo Kc)
Kca = abs(Kr/(einf*Kf1*Kf2));
% Kcb non posso calcolarlo perché yd1inf=0 in quanto G1 è di tipo 1 e d1 è
% un disturbo costante
Kcc = abs(10/(Kf1*Kf2));

Kc = max(Kca,Kcc);
% scelgo il segno di Kc
% Kf1*Kf2 > 0 (OK)
% pole(F1) e pole(F2) (OK)
% bode(F1*F2) (OK)
% tutti i requisiti sopra sono soddisfatti, per cui prendo Kc POSITIVO

%% specifiche dinamiche
wbmin = 3 / tsd;
wcd = 0.63 * wbmin;                             % wcd = 1.89 rad/s

mphi = 60 - 5 * Mrmax;                          % mphi = 47.5° --- NB: da Nichols trovo invece circa 40°-45°

%% prima chiusura anello
Ga1 = Kc * F1 * F2 / 1/Kr;
figure,bode(Ga1)                                % mod=12.7dB , fase=-188°

%% considerazioni
% devo recuperare 8° trovati da bode(Ga1) + 50° (arrotondato i 47.5° di
% mphi) --- per quanto riguarda invece il modulo dovrò recuperare quei
% 12.7dB trovati sempre in bode(Ga1)
% decido quindi di recuperare circa 55°-60° (minimo da Nichols -> circa 40+8=48°)

%% reti derivatrici
md1 = 3;
xd1 = sqrt(md1);
taud1 = xd1/wcd;
Rd1 = (1+s*taud1)/(1+s*taud1/md1);

md2 = 4;
xd2 = sqrt(md2);
taud2 = xd2/wcd;
Rd2 = (1+s*taud2)/(1+s*taud2/md2);

Ga2 = Ga1*Rd1*Rd2;

figure,bode(Ga2)                                % mod=23.5dB , fase=-122°
% OK per la fase: ho recuperato 58°

%% reti attenuatrici
mi1 = 14.9;
xi1 = 100;
taui1 = xi1/wcd;
Ri1 = (1+s*taui1/mi1)/(1+s*taui1);

Ga3 = Ga2*Ri1;

figure,bode(Ga3)                                % mod=0.125dB , fase=-130°
% OK per la fase: il recupero va ancora bene (55° > 51°)

figure,margin(Ga3)                              % 49.7° at 1.93 rad/s (OK)

%% dichiaro il controllore
C = Kc*Rd1*Rd2*Ri1;

Ga = C*F1*F2;
W = feedback(Ga,1/Kr);

figure,bode(W)                                  % wb = 3.72 rad/s
figure,step(W)                                  % overshoot = 15.7%, ts=0.582s (NO -> <0.8)