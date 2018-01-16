% Does not appear to be used (called) by Lapdog itself.

    count=0;
dontskip=1;
if(dontskip)
%fileList = getAllFiles('/Users/frejon/Documents/RosettaArchive/PDS_Archives/DATASETS/SECOND_DELIVERY_VERSIONS/204/I_S/');
fileList = getAllFiles('/Users/frejon/Rosetta/temp/I_S/');
fileList(1)=[];
% bfileList = getAllFiles('/Users/frejon/Documents/RosettaArchive/PDS_Archives/DATASETS/SECOND_DELIVERY_VERSIONS/204/B_S/');
bfileList = getAllFiles('/Users/frejon/Rosetta/temp/B_S/');
bfileList(1)=[];
%  fileList = getAllFiles('/Users/frejon/Rosetta/temp/I_S_204/');
%  bfileList = getAllFiles('/Users/frejon/Rosetta/temp/B_S_204/');
% 

addpath('~/Rosetta/lap_import/')
m926LAP1=[];
 m926LAP1.diff=nan(119,30);
% m926LAP1.diff=nan(120,30);
m926LAP1.std=m926LAP1.diff;

m926LAP1.t_epoch=[];

m926LAP2=m926LAP1;
 m926LAP2.diff=nan(119,30);
%m926LAP2.diff=nan(104,30);
m926LAP2.std=m926LAP2.diff;

Allsweeps=nan(119,1);

    for i=1:length(fileList)
        
        j=i*2 -1 ;
        
        if(j>length(fileList));break;end  
        rfile=fileList{j,1}(1:end);
        rfile2=fileList{j+1,1}(1:end);
        
        bfile=bfileList{j,1}(1:end);
        bfile2=bfileList{j+1,1}(1:end);
        
        if exist(rfile)==2 && strcmp(rfile(end-3:end),'.TAB');
            btemp = lap_import(bfile);
            btemp2 = lap_import(bfile2);          
            V_P1 = btemp.bias_potentials;
            V_P2 = btemp2.bias_potentials;
        % Classify "sweep" depending on voltage curve: one/two sweeps, up/down, where split.
        potdiff = diff(V_P1);
        len=length(V_P1);
        upd = max(0,sign(potdiff));    % is an int either 0 or 1...
        if potdiff(1) > 0 && V_P1(end)~=max(V_P1)
            % potbias looks like V.
            mind=find(V_P1==max(V_P1));
            mind2=find(V_P2==max(V_P2));            
            split = 1;
            upd = [ 0 1];
        elseif potdiff(1) <0 && V_P1(end)~=min(V_P1)
            % potbias looks like upside-down V.
            mind=find(V_P1==min(V_P1));
            mind2=find(V_P2==min(V_P2));

            split = -1;
            upd = [ 1 0];
        else
            split = 0;
            fprintf(1,'error, not a compatible sweep');
            return;
        end
        ind0_1 = mind-1;
        ind1_0 = mind+1;
        if len > 2*mind
            ind0_0 = 1;
            
            ind1_1 = 2*mind;
        elseif len < 2*mind
            ind0_0=2*mind-len;
            ind1_1 = len;                                
        else          
            ind0_0 = 1;
            ind1_1 = len;
        end
        
        p2ind0_1 = mind2-1;
        p2ind1_0 = mind2+1;
        if length(V_P2) > 2*mind2
            p2ind0_0 = 1;
            
            p2ind1_1 = 2*mind2;
        elseif length(V_P2) < 2*mind2
            p2ind0_0=2*mind2-length(V_P2);
            p2ind1_1 = length(V_P2);
        else
            p2ind0_0 = 1;
            p2ind1_1 = length(V_P2);
        end
        
        
        
            temp=lap_import(rfile);
            temp2=lap_import(rfile2);
            
            temp.sweeps = temp.sweeps.';
            temp2.sweeps = temp2.sweeps.';
            I1sdown = temp.sweeps(ind0_0:ind0_1,:); %down for macro204, up for macro 926
            I1sup   = temp.sweeps(ind1_0:ind1_1,:);%up for macro204, down for macro 926
            I2sup  =temp2.sweeps(p2ind1_0:p2ind1_1,:);%down for macro204, up for macro 926
            I2sdown =temp2.sweeps(p2ind0_0:p2ind0_1,:); %up for macro204, down for macro 926          
        
        
count=count+length(temp.qf)       

%I2sdown=Matrix204I2Ssort(ind0:104,:);
%I2sup=Matrix204I2Ssort(105:end-1,:);
%I1sup=temp.sweeps(ind1_0:ind1_1,:);
%I1sdown=temp.sweeps(ind0:mind,:);


ind1 = length(I1sup(:,1)):-1:1;
I1sup=I1sup(ind1,:); %rotate


ind2 = length(I2sup(:,1)):-1:1;

I2sup=I2sup(ind2,:); %rotate


diffI1supdown = I1sdown - I1sup; %for macro926, this s instead I(/) - I(\) in a /\ sweep
diffI2supdown = I2sdown - I2sup;


g8 = floor(length(temp.sweeps(1,:))/8);

i1s_1 = temp.sweeps(:,1:g8);
i1s_2 = temp.sweeps(:,g8+1:2*g8);
i1s_3 = temp.sweeps(:,2*g8+1:3*g8);
i1s_4 = temp.sweeps(:,3*g8+1:4*g8);
i1s_5 = temp.sweeps(:,4*g8+1:5*g8);
i1s_6 = temp.sweeps(:,5*g8+1:6*g8);
i1s_7 = temp.sweeps(:,6*g8+1:7*g8);
i1s_8 = temp.sweeps(:,7*g8+1:end);


i1sdown_1=i1s_1(ind0_0:ind0_1,:);
i1sup_1=i1s_1(ind1_0:ind1_1,:);
i1sup_1=i1sup_1(ind1,:); %rotate
diffI1supdown_1 = i1sdown_1 - i1sup_1;

i1sdown_2=i1s_2(ind0_0:ind0_1,:);
i1sup_2=i1s_2(ind1_0:ind1_1,:);
i1sup_2=i1sup_2(ind1,:); %rotate
diffI1supdown_2 = i1sdown_2 - i1sup_2;

i1sdown_3=i1s_3(ind0_0:ind0_1,:);
i1sup_3=i1s_3(ind1_0:ind1_1,:);
i1sup_3=i1sup_3(ind1,:); %rotate
diffI1supdown_3 = i1sdown_3 - i1sup_3;

i1sdown_4=i1s_4(ind0_0:ind0_1,:);
i1sup_4=i1s_4(ind1_0:ind1_1,:);
i1sup_4=i1sup_4(ind1,:); %rotate
diffI1supdown_4 = i1sdown_4 - i1sup_4;

i1sdown_5=i1s_5(ind0_0:ind0_1,:);
i1sup_5=i1s_5(ind1_0:ind1_1,:);
i1sup_5=i1sup_5(ind1,:); %rotate
diffI1supdown_5 = i1sdown_5 - i1sup_5;

i1sdown_6=i1s_6(ind0_0:ind0_1,:);
i1sup_6=i1s_6(ind1_0:ind1_1,:);
i1sup_6=i1sup_6(ind1,:); %rotate
diffI1supdown_6 = i1sdown_6 - i1sup_6;

i1sdown_7=i1s_7(ind0_0:ind0_1,:);
i1sup_7=i1s_7(ind1_0:ind1_1,:);
i1sup_7=i1sup_7(ind1,:); %rotate
diffI1supdown_7 = i1sdown_7 - i1sup_7;

i1sdown_8=i1s_8(ind0_0:ind0_1,:);
i1sup_8=i1s_8(ind1_0:ind1_1,:);
i1sup_8=i1sup_8(ind1,:); %rotate
diffI1supdown_8 = i1sdown_8 - i1sup_8;



std1u_1 = 1E9*mean(diffI1supdown_1,2)+1E9*std(diffI1supdown_1,1,2);
std1d_1 = 1E9*mean(diffI1supdown_1,2)-1E9*std(diffI1supdown_1,1,2);
i1_1= 1E9*mean(diffI1supdown_1,2);

std1u_2 = 1E9*mean(diffI1supdown_2,2)+1E9*std(diffI1supdown_2,1,2);
std1d_2 = 1E9*mean(diffI1supdown_2,2)-1E9*std(diffI1supdown_2,1,2);
i1_2= 1E9*mean(diffI1supdown_2,2);

std1u_3 = 1E9*mean(diffI1supdown_3,2)+1E9*std(diffI1supdown_3,1,2);
std1d_3 = 1E9*mean(diffI1supdown_3,2)-1E9*std(diffI1supdown_3,1,2);
i1_3= 1E9*mean(diffI1supdown_3,2);

std1u_4 = 1E9*mean(diffI1supdown_4,2)+1E9*std(diffI1supdown_4,1,2);
std1d_4 = 1E9*mean(diffI1supdown_4,2)-1E9*std(diffI1supdown_4,1,2);
i1_4= 1E9*mean(diffI1supdown_4,2);

std1u_5 = 1E9*mean(diffI1supdown_5,2)+1E9*std(diffI1supdown_5,1,2);
std1d_5 = 1E9*mean(diffI1supdown_5,2)-1E9*std(diffI1supdown_5,1,2);
i1_5= 1E9*mean(diffI1supdown_5,2);

std1u_6 = 1E9*mean(diffI1supdown_6,2)+1E9*std(diffI1supdown_6,1,2);
std1d_6 = 1E9*mean(diffI1supdown_6,2)-1E9*std(diffI1supdown_6,1,2);
i1_6= 1E9*mean(diffI1supdown_6,2);

std1u_7 = 1E9*mean(diffI1supdown_7,2)+1E9*std(diffI1supdown_7,1,2);
std1d_7 = 1E9*mean(diffI1supdown_7,2)-1E9*std(diffI1supdown_7,1,2);
i1_7= 1E9*mean(diffI1supdown_7,2);

std1u_8 = 1E9*mean(diffI1supdown_8,2)+1E9*std(diffI1supdown_8,1,2);
std1d_8 = 1E9*mean(diffI1supdown_8,2)-1E9*std(diffI1supdown_8,1,2);
i1_8= 1E9*mean(diffI1supdown_8,2);




V1 = V_P1(ind0_0:ind0_1) ;

V2 = V_P2(p2ind0_0:p2ind0_1);

figure(6);


time1=temp.START_TIME_UTC{1,1}(1:10);

title([sprintf('%s Macro 926       Probe 2',time1)]);

%title(' 10 Sep 2014 Macro 926       Probe 2 10 Sep 2014 macro 204');
subplot(2,2,1);
plot(1E9*temp2.sweeps);
grid on;
axis([0 210 -100 40]);
xlabel('step nr');
ylabel('nA');
title([sprintf('%s Macro 926        P2 Sweep current vs time',time1)]);



Avg_926 = [];
Avg_926.I = mean(temp2.sweeps,2);
Avg_926.V =V_P2;


subplot(2,2,2);
plot(V_P2,1E9*temp2.sweeps(:,:));
grid on;
axis([-30 30 -40 100]);

title([sprintf('%s Macro 926        P2 Sweep current vs Vbias',time1)]);

ylabel('nA');

% 
% V1 = V_P1(ind0_0:ind0_1) ;
% V2 = V_P2(ind0_0:ind0_1);

subplot(2,2,3);
plot(V2,1E9*diffI2supdown);
grid on;
axis([-25 25 -40 40]);
xlabel('V');
ylabel('nA');

title([sprintf('%s Macro 926        P2 diff up/down on each potential step',time1)]);




subplot(2,2,2);
plot(1E9*temp.sweeps);
grid on;
title([sprintf('%s Macro 926        P1 Sweep current vs time',time1)]);

axis([0 240 -100 40]);
xlabel('step nr');
ylabel('nA');

subplot(2,2,4);

%plot(V1,i1_1,V1,i1_2,V1,i1_3,V1,i1_4,V1,i1_4,V1,i1_6,V1,i1_7,V1,i1_8);
plot(V_P1(ind0_0:ind0_1),1E9*diffI1supdown);
grid on;
axis([-30 30 -20 20]);
title([sprintf('%s Macro 926        P1 diff up/down on each potential step',time1)]);

xlabel('V');
ylabel('nA');

figure(5);
std1u = 1E9*mean(diffI1supdown,2)+1E9*std(diffI1supdown,1,2);
std1d = 1E9*mean(diffI1supdown,2)-1E9*std(diffI1supdown,1,2);


std2u = 1E9*mean(diffI2supdown,2)+1E9*std(diffI2supdown,1,2);
std2d = 1E9*mean(diffI2supdown,2)-1E9*std(diffI2supdown,1,2);




a= find(V1<0,1,'first');

b = find(V2<0,1,'first');

m926LAP1.Vb=V1;
m926LAP2.Vb=V2;

Allsweeps=[Allsweeps,diffI1supdown];

m926LAP1.diff(:,i)=mean(diffI1supdown,2);
m926LAP2.diff(:,i)=mean(diffI2supdown,2);
m926LAP1.std(:,i)=std(diffI1supdown,1,2);
m926LAP2.std(:,i)=std(diffI2supdown,1,2);
m926LAP1.t_epoch(i) = irf_time(temp.START_TIME_UTC{1,1},'utc>epoch');
m926LAP2.t_epoch(i)=m926LAP1.t_epoch(i);

[P1,S] = polyfit(V2(b:end),mean(diffI2supdown(b:end,:),2),1);
%fit2_2 = P(3) + P(2)*V2(b:end)+P(1)*V2(b:end).^2;
fit2_1 = P1(2) + P1(1)*V2(b:end);

[P2,S] = polyfit(V1(a:end),mean(diffI1supdown(a:end,:),2),1);
fit1_1 = P2(2) + P2(1)*V1(a:end);

%fit1_2 = P(3) + P(2)*V1(a:end)+P(1)*V1(a:end).^2;

plot(V1(a:end),fit1_1,'r',V2(b:end),fit2_1,'b')


plot(V1,1E9*mean(diffI1supdown,2),'or',V2,1E9*mean(diffI2supdown,2),'ob',V1,std1u,'--r',V1,std1d,'--r',V2,std2u,'--b',V2,std2d,'--b',V1(a:end),1E9*fit1_1,'black',V2(b:end),1E9*fit2_1,'black');

%plot(V_P1(ind0:mind),1E9*mean(diffI1supdown,2),'or',V_P2(ind0:104),1E9*mean(diffI2supdown,2),'ob');
grid on;
axis([-30 30 -300 10]);

title([sprintf('%s Macro 926        Mean P1 & P2 diff up/down on each potential step & standard devation',time1)]);

xlabel('V');
ylabel('nA');
%text(10,0,'\leftarrow sin(-\pi\div4)','HorizontalAlignment','left')
str2 = sprintf(' k=%5.2e \noffset = %5.2e',P1(1),P1(2));
str1 = sprintf(' k=%5.2e \noffset = %5.2e',P2(1),P2(2));

text(15,9,str1,'HorizontalAlignment','left')'
text(15,7,str2,'HorizontalAlignment','left')


hleg1 = legend('Probe 1 mean diff','Probe 2 mean diff');
            
            
        end
    end
    
end;
    
    
    
clrs=get(gca,'ColorOrder');
figure(881)
I_factor=1e9;
%   %  h1 =shadedErrorBar(V1,I_factor*mean(m926LAP1.diff,2),...
%         I_factor*mean(m926LAP1.std,2),... % Median absolute deviation MAD = 0.67449*std;
%         {'+k', 'markeredgecolor', clrs(1,:),...
%         'markerfacecolor',clrs(1,:)...
%         'markersize',4},0);
%     
h1 =shadedErrorBar(m926LAP1.Vb,I_factor*mean(m926LAP1.diff,2),...
    I_factor*mean(m926LAP1.std,2),... % Median absolute deviation MAD = 0.67449*std;
    {'-'},1);
hold on;
h2 =shadedErrorBar(m926LAP2.Vb,I_factor*mean(m926LAP2.diff,2),...
    I_factor*mean(m926LAP2.std,2),... % Median absolute deviation MAD = 0.67449*std;
    {'-'},1);

h21 =shadedErrorBar(m204LAP1.Vb,I_factor*mean(m204LAP1.diff,2),...
    I_factor*mean(m204LAP1.std,2),... % Median absolute deviation MAD = 0.67449*std;
    {'-'},1);

h22 =shadedErrorBar(m204LAP2.Vb,I_factor*mean(m204LAP2.diff,2),...
    I_factor*mean(m204LAP2.std,2),... % Median absolute deviation MAD = 0.67449*std;
    {'-'},1);



hold off;
grid on;
ax1=gca;
ax1.Title.String='LAP1 up/down sweeps difference (I(up)-I(down))';
ay4=legend([h21(1).mainLine, h21.patch,  h22(1).mainLine, h22.patch h1(1).mainLine, h1.patch,  h2(1).mainLine, h2.patch], ...
      '\mu LAP1 2014-2015 ', '\sigma','\mu LAP2 2014-2015', '\sigma','\mu LAP1 2016 ', '\sigma','\mu LAP2 2016', '\sigma', 'Location', 'NorthWest');
 ax1.XLabel.String='Sweep bias [V]';
 ax1.YLabel.String='Current difference [na]';


figure(882);h3=surf(1:length(m926LAP1.t_epoch),V1,1e9*m926LAP1.diff);
ax=gca;



figure(8821);h3=surf(1:length(m204LAP1.t_epoch),m204LAP1.Vb,1e9*m204LAP1.diff);
ax=gca;

k= 0.01*1e-9;%nA/V; slope LAP1
C=k*0.0585; %C = Q/V =  dI*dt/dV  C LAP1.


%ax.
ax.XTick=[1:length(m926LAP1.t_epoch)];
ax.XTickLabel=irf_time(m926LAP1.t_epoch,'epoch>utc_yyyy-mm-dd');
ax.Title.String='LAP1 Macro 926 up/down sweeps difference (I(up)-I(down))';
ax.YLabel.String='Sweep bias [V]';
ax.ZLabel.String='Current difference [na]';


figure(883)
I_factor=1e9;
%   %  h1 =shadedErrorBar(V1,I_factor*mean(m926LAP1.diff,2),...
%         I_factor*mean(m926LAP1.std,2),... % Median absolute deviation MAD = 0.67449*std;
%         {'+k', 'markeredgecolor', clrs(1,:),...
%         'markerfacecolor',clrs(1,:)...
%         'markersize',4},0);
%     
%h1 =shadedErrorBar(m926LAP1.Vb,-I_factor*mean(m926LAP1.diff,2),...
   % I_factor*mean(m926LAP1.std,2),... % Median absolute deviation MAD = 0.67449*std;
 %   {'-'},1);
h1 =shadedErrorBar(m926LAP1.Vb,-I_factor*nanmean(Allsweeps,2),...
    I_factor*nanstd(Allsweeps,2)/sqrt(6829),... % Median absolute deviation MAD = 0.67449*std;
    {'-'},1);

hold on;
% h2 =shadedErrorBar(m926LAP2.Vb,I_factor*mean(m926LAP2.diff,2),...
%     I_factor*mean(m926LAP2.std,2),... % Median absolute deviation MAD = 0.67449*std;
%     {'-'},1);

h21 =shadedErrorBar(m204LAP1.Vb,I_factor*mean(m204LAP1.diff,2),...
    I_factor*mean(m204LAP1.std,2)/sqrt(6829),... % Median absolute deviation MAD = 0.67449*std;
    {'-'},1);

% h22 =shadedErrorBar(m204LAP2.Vb,I_factor*mean(m204LAP2.diff,2),...
%     I_factor*mean(m204LAP2.std,2),... % Median absolute deviation MAD = 0.67449*std;
%     {'-'},1);
% 


hold off;
grid on;
ax1=gca;
ax1.Title.String='LAP1 up/down sweep current difference (I(down)-I(up))';
ay4=legend([h21(1).mainLine, h21.patch, h1(1).mainLine, h1.patch,], ...
      '\mu LAP1 09/2014-07/2015 (204 \\/) ', '\sigma','\mu LAP1 03/2016-09/2016 (926 /\\) ', '\sigma', 'Location', 'NorthWest');
 ax1.XLabel.String='Bias potential [V]';
 ax1.YLabel.String='Current difference [nA]';
ax1.YLim=[-6 6];




figure(884);
plot(m204LAP1.Vb,m204LAP1.diff,m926LAP1.Vb,m926LAP1.diff)
% h5=surf([1:length(m926LAP1.t_epoch) [1:length(m204LAP1.t_epoch)]],V1,1e9*m926LAP1.diff);
% ax=gca;
% 
% 
% 
% k= 0.01*1e-9;%nA/V; slope LAP1
% C=k*0.0585; %C = Q/V =  dI*dt/dV  C LAP1.
% 
% 
% %ax.
% ax.XTick=[1:length(m926LAP1.t_epoch)]
% ax.XTickLabel=irf_time(m926LAP1.t_epoch,'epoch>utc_yyyy-mm-dd');
% ax.Title.String='LAP1 Macro 926 up/down sweeps difference (I(up)-I(down))';
% ax.YLabel.String='Sweep bias [V]';
% ax.ZLabel.String='Current difference [na]';



