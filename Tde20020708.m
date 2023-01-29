clear all
close all

s=tf('s');

F1 = 30/(s+15);                     % tipo 0
F2 = (3*s+3)/(s^3+10*s^2+24*s);     % tipo 1

Kr = 1;
d1 = 1;
d2 = 4;

% specifihe statiche
einf = 0.1;                         % errore alla rampa
d1inf = 0.05;                       % disturbo sull'uscita
d2inf = 0.01;                       % disturbo sull'uscita
% specifiche dinamiche
wbd = 20;                           % banda passante (NB: toll. 10%)
sovrmax = 0.2;                      % sovraelongazione massima

Kf1 = dcgain(F1)
Kf2 = dcgain(s*F2)

% FORMULE RICAVATE SUL FOGLIO %
Kca = Kr/(einf * Kf1 * Kf2);
Kcb = d1/(d1inf * Kf1);
% yd2 = 0;                          % perché il disturbo costituito da Kc*Kf1*Kf2 è sempre
                                    % nullo (disturbo costante sull'uscita con Ga di tipo 1)

Kc = max(Kca, Kcb)                  % prendo il Kc più restrittivo

Ga1 = Kc * F1 * F2 * 1/Kr           % prima funzione d'anello

wcd = wbd * 0.63

Mr = 20*log10((1+sovrmax)/0.9)      % da Nichols mi rendo conto che devo recuperare circa 43°-45°
mphi = 60 - 5 * Mr                  % con la relazione approx invece trovo 47.5°

figure,bode(Ga1)                    % da qui ho trovato mod=-0.04 e fase=-181°, quindi devo recuperare 1°

% decido di recuperare quindi almeno 50° cercando di mantenere il modulo
% così (visto che già è vicino a 0)

% per recuperare i 50° ho bisogno di una o più reti anticipatrici
% tentativo 1: una sola rete da 8 nel punto di massimo recupero
md1 = 8;
xd1 = sqrt(8);
taud1 = xd1/wcd;
Rd1 = (s*taud1+1)/(s*taud1/md1+1);

Ga2 = Ga1*Rd1;                      % mi aspetto un buon recupero in fase ma un aumento in modulo di circa 9dB

figure,bode(Ga2)                    % trovo infatti in wcd i valori fase=-130° mod=9.02
% abbiamo recuperato un totale di 50° sulla fase (perfetto)
% abbiamo però causato un incremento elevato del modulo

% ora dobbiamo cercare di far perdere i 9dB in eccesso di modulo, con una o più reti attenuatrici
% proviamo con una rete da 3 centrata in x=100 per garantire il recupero
% del modulo e contemporaneamente mantenere la fase
mi1 = 3;
xi1 = 100;
taui1 = xi1/wcd;
Ri1 = (s*taui1/mi1+1)/(s*taui1+1);

Ga3 = Ga2*Ri1;

figure,bode(Ga3)                    % da bode vedo che ho mod=-0.5 (OK) e fase=-132° (OK)

% posso per cui provare a chiudere l'anello e vedere se sono soddisfatte le specifiche

figure,margin(Ga3)                  % effettivamente risulta che io abbia un margin di 51.1° in 12.1 rad/s (OK)
C = Kc*Rd1*Ri1

W = feedback(C*F1*F2, 1/Kr)
figure,bode(W)                      % trovo che a -3dB ho wb=20.6 (OK -> è circa 20)
figure,step(W)                      % trovo un overshoot (s) di 8.74% (<20% --> OK) ed un rise time ts=0.11s

% per calcolare la specs gamma (quella sull'err max in regime permanente a r(t) = sin(0.2t) devo fare:
wd = 0.2;
sens = feedback(1,Ga3)
[ms,fs] = bode(sens,wd)
err = ms*Kr                         % trovo che l'errore sia = 0.033