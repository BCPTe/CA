clear all
close all

s = tf('s');

%% dichiarazione dati
Gp = (-0.65)/(s^3+4*s^2+1.75*s);
Tp = 1;
A = 9;
A1 = 5.5e-3;
A2 = 5.5e-3;
Ap = 1e-3;
wp = 30;
tsmax = 1;
smax = 0.3;

%% calcolo guadagni
KGp = dcgain(s*Gp);

%% specifiche statiche

% 1)
Kca = abs(1/(0.2*A*KGp));
% 2)
Kcb = abs(A1/(6e-4*A));
% 3)
Kcc = abs(A2/(1.5e-3*A*KGp));

Kc = max([Kca,Kcb,Kcc]);
% devo decidere il segno di Kc in quanto:
% * Kgp < 0 (NO)
% * ci sono poli instabili ({Re}<0) --> li vedo con pole(Gp)
nyquist(A*Gp),axis equal
hold on
plot(1/Kc,0,'g*',-1/Kc,0,'r*')
% Kc va preso negativo, quindi:
Kc = -Kc;

%% specifiche dinamiche
% 4)
wbmin = 3/tsmax;                                % wbmin = 3 rad/s
wcmin = 0.63*wbmin;                             % wcmin = 1.89 rad/s
% decido di prendere una wc più grande per avere un po' di margine dalla wcmin
wcd = 2.2;

% 5)
Mr_un_nat = (1+smax)/0.9;
Mr = 20*log10(Mr_un_nat);                       % Mr = 3.19dB

%% prima chiusura d'anello
Ga1 = Kc*Gp*A/Tp;
figure,bode(Ga1)                                % mod=-7.41dB fase=-199°
% devo quindi recuperare -7.41dB di modulo e 19° di fase

%% commenti sulla situazione
% da Nichols -> devo recuperare 180-142 = 38° + 19° di sopra = almeno 57°
% dalla formula approxx trovo:
mphi = 60 - 5 * Mr;                             % mphi = 44° + 19° di sopra = almeno 63°
% decido di recupare almeno 65°

%% reti derivatrici
% tentativo 1: una da 3 ed una da 4
% md1 = 3;
% xd1 = sqrt(md1);
% taud1 = xd1/wcd;
% Rd1 = (1+s*taud1)/(1+s*taud1/md1);

% tentativo 2: due reti da 4 (poi diventate da 5)
md2 = 5;                                        % ho visto che due reti da 4 mi facevano recuperare solo 55°
                                                % per cui ho optato per una leggermente più grande (da 5)
xd2 = sqrt(md2);
taud2 = xd2/wcd;
Rd2 = (1+s*taud2)/(1+s*taud2/md2);

Ga2 = Ga1*Rd2^2;

figure,bode(Ga2)                                % trovo m1 = 6.56 e fase = -116° (recupero di 64°)

%% reti attenuatrici
% tentativo 1: una rete da 2 in x=100
mi1 = 2;
xi1 = 100;
taui1 = xi1/wcd;
Ri1 = (1+s*taui1/mi1)/(1+s*taui1);

Ga3 = Ga2*Ri1;

% dovrei aver finito quindi vado di margin prepotente
figure, margin(Ga3)                             % trovo 60.9° a 2.36 rad/s (OK)

%% definizione del controllore
C = Kc*Rd2^2*Ri1;
Ga = C*A*Gp;
W = feedback(Ga, Tp);

%% verifiche su wb e Mr
figure,step(W)                                  % trovo un ts=0.5s (OK) e un overshoot(s^) del 9.31% (OK)
figure,bode(W)                                  % wb = 4.54 rad/s --- Mr = 0.24dB
wb = 4.54;

%% verifiche sugli errori statici
We = feedback(Tp,Ga);
We_d1 = -Gp*We;
We_d2 = -We;

figure,step(We/s)
figure,step(A1*We_d1)
figure,step(A2/s*We_d2)

%% discretizzazione (non era richiesta dalla traccia, ma ci alleniamo)
T = 2*pi/(5*wb);
Gazoh = Ga/(1+s*T/2);
Cz = c2d(C, T, "tustin");
Fz = c2d(A*Gp, T, "tustin");
Wz = feedback(Cz*Fz,1)