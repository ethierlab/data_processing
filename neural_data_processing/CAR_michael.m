
% filter_order=1;
% fc = [300 5000]; %Hz
% [b_pass,a_pass] = butter(filter_order,fc/(sr/2));
% data=filtfilt(b_pass,a_pass,data);
% figure
% plot(data)
?
garder1=3*garder1;
?
% sera sliding
garder1=garder1/rms(garder1);
garder2=garder2/rms(garder2);
garder3=garder3/rms(garder3);
% retenir rms pour remettre signal 
?
figure
subplot(3,1,1)
plot(garder1)
% ylim([-25 25])
subplot(3,1,2)
plot(garder2)
% ylim([-25 25])
subplot(3,1,3)
plot(garder3)
% ylim([-25 25])
?
moyenne=(garder1+garder2+garder3)/3;
[moy_pks, moy_pks_locs]=findpeaks(moyenne,'MinPeakHeight',5);
?
?
fun = @(x) mean(garder1(moy_pks_locs)-x*moy_pks);
x1 = fzero(fun,-100);
fun = @(x) mean(garder2(moy_pks_locs)-x*moy_pks);
x2 = fzero(fun,-100);
fun = @(x) mean(garder3(moy_pks_locs)-x*moy_pks);
x3 = fzero(fun,-50);
?
% % OU BIEN trouver x pic par pic et moyenner ces valeurs
% x1=mean(garder1(moy_pks_locs)./moy_pks);
% x2=mean(garder2(moy_pks_locs)./moy_pks);
% x3=mean(garder3(moy_pks_locs)./moy_pks);
?
garder1bis=garder1-x1*moyenne;
garder2bis=garder2-x2*moyenne;
garder3bis=garder3-x3*moyenne;
?
figure
subplot(3,1,1)
plot(garder1bis)
% ylim([-5 5])
subplot(3,1,2)
plot(garder2bis)
% ylim([-5 5])
subplot(3,1,3)
plot(garder3bis)
% ylim([-5 5])
?
figure
ax1=subplot(2,1,1);
plot(garder1)
ax2=subplot(2,1,2);
plot(garder1bis)
linkaxes([ax1 ax2],'x');