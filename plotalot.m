%plotalot.m
%loads a prexisting tabindex (either from server or otherwise)
%reads A*S files for both probes, 
%store chosen variables in structure data1 & data2
%chosen variables listed in 'fld' cell array
% plots various components against eachother


%readserverindexfiles
shortphase

addpath('/Users/frejon/Documents/RosettaArchive/lap_import')

antype = cellfun(@(x) x(end-6:end-4),tabindex(:,2),'un',0);
clear dataraw


%cspice_furnsh('/Users/frejon/Documents/RosettaArchive/Lapdog_GIT/metakernel_rosetta.txt');

probe = 1;
str1 = sprintf('I%iS',probe); %I1S or I2S
str2 = sprintf('A%iS',probe); %A1S or A2S
a_ind= find(strcmp(str1, antype));

for i=1:length(a_ind);
    
    
    if i==100
        break
    end
    
    
   i
   
    rfile =tabindex{a_ind(i),1};
    rfile = strrep(rfile,str1,str2); %I1S-> A1S

    if exist(rfile)==2
        
        formatin = 'YYYY-mm-ddTHH:MM:SS';
        
        temp=lap_import(rfile);
        temp.t1 = datenum(cspice_et2utc(cspice_str2et(temp.START_TIME_UTC),'ISOC',0),formatin);
        
        dataraw(i) = temp;
    else
        'no file'
    end

       
end


'probe  1 done'

fld={'t1' 'Iph0' 'Tph' 'asm_ni_v_indep' 'asm_ni_v_dep' 'asm_ne_exp' 'ne_exp' 'asm_ne_linear' 'asm_ne_5eV' 'asm_Vsg', 'ni_v_dep' 'ni_v_indep' 'ne_linear' 'ne_5eV' 'Vsg' 'Te_linear' 'Te_exp'  'asm_Te_linear' 'asm_Te_exp' 'asm_v_ion' 'v_ion' 'v_aion' 'asm_Vsc_aion'  'Vsc_aion' 'asm_ni_aion' 'asm_v_aion' 'asm_Vph_knee' 'ni_aion'};

len = length(fld);

data1=[];
meand1=[];
mediand1=[];


for j=1:length(dataraw)

    if j <2
        
        
        for k=1:len
            meand1.(sprintf('%s',fld{1,k})) =nanmean([dataraw(j).(sprintf('%s',fld{1,k}))]);
            data1.(sprintf('%s',fld{1,k})) =[dataraw(j).(sprintf('%s',fld{1,k}))];
            mediand1.(sprintf('%s',fld{1,k})) =nanmedian([dataraw(j).(sprintf('%s',fld{1,k}))]);

        end
    else
        
        
        for k=1:len
            meand1.(sprintf('%s',fld{1,k})) = [[meand1.(sprintf('%s',fld{1,k}))];nanmean([dataraw(j).(sprintf('%s',fld{1,k}))])];
            mediand1.(sprintf('%s',fld{1,k})) =[[mediand1.(sprintf('%s',fld{1,k}))];nanmedian([dataraw(j).(sprintf('%s',fld{1,k}))])];
            data1.(sprintf('%s',fld{1,k})) = [[data1.(sprintf('%s',fld{1,k}))];[dataraw(j).(sprintf('%s',fld{1,k}))]];
        end
    end
    
    
end

clear dataraw

probe = 2;
str1 = sprintf('I%iS',probe); %I1S or I2S
str2 = sprintf('A%iS',probe); %A1S or A2S
a_ind= find(strcmp(str1, antype));

for i=1:length(a_ind);
    
    
    if i==100
        break
    end
    
    
    rfile =tabindex{a_ind(i),1};
    rfile = strrep(rfile,str1,str2); %I1S-> A1S

    formatin = 'YYYY-mm-ddTHH:MM:SS';
    
        temp=lap_import(rfile);   
        temp.t1 = datenum(cspice_et2utc(cspice_str2et(temp.START_TIME_UTC),'ISOC',0),formatin);

        dataraw(i) = temp;

       
end


data2=dataraw(1);



for j=2:length(dataraw)

   for k=1:len

       data2.(sprintf('%s',fld{1,k})) = [[data2.(sprintf('%s',fld{1,k}))];[dataraw(j).(sprintf('%s',fld{1,k}))]];
   end  
       
  
end


data2=[];
meand2=[];
mediand2=[];


for j=1:length(dataraw)
    %
    
    if j <2
        
        
        for k=1:len
            meand2.(sprintf('%s',fld{1,k})) =nanmean([dataraw(j).(sprintf('%s',fld{1,k}))]);
            data2.(sprintf('%s',fld{1,k})) =[dataraw(j).(sprintf('%s',fld{1,k}))];
            mediand2.(sprintf('%s',fld{1,k})) =nanmedian([dataraw(j).(sprintf('%s',fld{1,k}))]);

        end
    else
        
        
        for k=1:len
            meand2.(sprintf('%s',fld{1,k})) = [[meand2.(sprintf('%s',fld{1,k}))];nanmean([dataraw(j).(sprintf('%s',fld{1,k}))])];
            mediand2.(sprintf('%s',fld{1,k})) =[[mediand2.(sprintf('%s',fld{1,k}))];nanmedian([dataraw(j).(sprintf('%s',fld{1,k}))])];
            data2.(sprintf('%s',fld{1,k})) = [[data2.(sprintf('%s',fld{1,k}))];[dataraw(j).(sprintf('%s',fld{1,k}))]];
        end
    end
    
    
end


clear dataraw

% 
% figure(69)
% 
% plot(data2.t1,data2.ni_2comp,'ro',data2.t1,data2.ni_1comp,'blacko',data2.t1,data2.ne,'g',data2.t1,data2.ne_5eV,'b')
% %plot(data2.t1,data2.asm_Vsg,'o');
% %legend('If0','\alpha SAA','Ion current y intersect','average','standard deviation')
% datetick('x',20)
% grid on;
% axis([data2.t1(1) data2.t1(end) 0 700])
% legend('ni\_slope*intsct','ni\_slope\_7000m/s','ne','ne\_5eV');
% title('density estimations probe 1 M09 19amu')


% if strcmp(shortphase,'EAR3')
%     
%     data1.asm_ni_v_dep =   data1.asm_ni_v_dep *2/7;
%     data2.asm_ni_v_dep =   data2.asm_ni_v_dep *2/7;
%     
% end





figure(152)
subplot(2,2,1)

plot(data1.t1,data1.ne_exp,'b+',data1.t1,data1.ne_linear,'r',data1.t1,data1.ne_5eV,'g',data1.t1,data1.ni_v_indep,'ro',data1.t1,data1.ni_v_dep,'black',data1.t1,data1.asm_ni_v_indep,'blacko');

%plot(data1.t1,data1.ni_v_indep,'blacko:',data1.t1,data1.asm_ne_linear,'g',data1.t1,data1.asm_ne_5eV,'b',data1.t1,data1.asm_ne_exp,'ro')
%plot(data2.t1,data2.asm_Vsg,'o');
%legend('If0','\alpha SAA','Ion current y intersect','average','standard deviation')
set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
datetick('x',20,'keepticks')
grid on;
axis([data1.t1(1) data1.t1(end) 0 10000])
legend('ne\_exp','ne\_linear','ne\_5eV','ni\_v\_indep','ni\_v\_dep','asm\_ni\_v\_indep');

%legend('ni\_v\_indep','asm\_ne','asm\_ne\_5eV','asm\_ne\_exp');
title([sprintf('Density estimations probe 1 %s 19amu vion = 550m/s',shortphase)])


subplot(2,2,2)

plot(data2.t1,data2.ne_exp,'b+',data2.t1,data2.ne_linear,'r',data2.t1,data2.ne_5eV,'g',data2.t1,data2.ni_v_indep,'go',data2.t1,data2.ni_v_dep,'black',data2.t1,data2.asm_ni_v_indep,'blacko');
legend('ne\_exp','ne\_linear','ne\_5eV','ni\_v\_indep','ni\_v\_dep','asm\_ni\_v\_indep');
%plot(data2.t1,data2.ni_v_indep,'ro:',data2.t1,data2.ni_v_dep,'blacko:',data2.t1,data2.asm_ne_linear,'g',data2.t1,data2.asm_ne_5eV,'b',data2.t1,data2.asm_ne_exp,':')
axis([data2.t1(1) data2.t1(end) 0 10000])

set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
datetick('x',20,'keepticks')
grid on;

%legend('ni\_v\_indep','ni\_v\_dep','asm\_ne','asm\_ne\_5eV','asm\_ne\_exp');
title([sprintf('Density estimations probe 2 %s 19amu vion = 550m/s',shortphase)])
% 
% subplot(2,2,3)
% plot(data1.t1,data1.ni_v_indep,'blacko',data1.t1,data1.ni_v_dep,'ro',data1.t1,data1.asm_ni_v_indep,'bo',data1.t1,data1.asm_ni_v_dep,'go')
% %plot(data2.t1,data2.asm_Vsg,'o');
% %legend('If0','\alpha SAA','Ion current y intersect','average','standard deviation')
% set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
% datetick('x',20,'keepticks')
% grid on;
% axis([data1.t1(1) data1.t1(end) 0 10000])
% legend('ni\_v\_indep','ni\_v\_dep','asm\_ni\_v\_indep','asm\_ni\_v\_dep');
% title([sprintf('Density estimations probe 1 %s 19amu vion = 550m/s',shortphase)])

subplot(2,2,3)
plot(data1.t1,data1.ni_v_indep,'black',data1.t1,data1.ni_v_dep,'r',data1.t1,data1.asm_ni_v_indep,'bo',data1.t1,data1.asm_ni_v_dep,'go')
%plot(data2.t1,data2.asm_Vsg,'o');
%legend('If0','\alpha SAA','Ion current y intersect','average','standard deviation')
set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
datetick('x',20,'keepticks')
grid on;
axis([data1.t1(1) data1.t1(end) 0 10000])
legend('ni\_v\_indep','ni\_v\_dep','asm\_ni\_v\_indep','asm\_ni\_v\_dep');
title([sprintf('Density estimations probe 1 %s 19amu vion = 550m/s',shortphase)])

subplot(2,2,4)
plot(data1.t1,data1.ne_exp,'b+',data1.t1,data1.ne_linear,'r',data1.t1,data1.ne_5eV,'g');

%plot(data1.t1,data1.asm_ne_exp,'ro',data2.t1,data2.asm_ne_linear,'blacko',data1.t1,data1.asm_ne_5eV,'bo',data2.t1,data2.ne_linear,'black:',data1.t1,data1.ne_exp,'red:',data2.t1,data2.ne_5eV,'b:');
set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
datetick('x',20,'keepticks')
grid on;
axis([data1.t1(1) data1.t1(end) 0 2000])
legend('asm\_ne\_exp','ne\_linear','ne\_5eV');
title([sprintf('Density estimations probe 1 %s 19amu vion = 550m/s',shortphase)])

figure(1111)

plot(meand1.t1,meand1.asm_ni_v_dep,'b',meand1.t1,meand1.asm_ni_v_indep,'ro',meand1.t1,meand1.asm_ne_5eV,'black',meand1.t1,meand1.asm_ni_aion,'bo',meand1.t1,meand1.ne_exp,'black+');

%plot(data1.t1,data1.asm_ni_v_indep,'ro',data2.t1,data2.asm_ni_v_indep,'blacko',data1.t1,data1.asm_ne_linear,'bo',data2.t1,data2.asm_ne_linear,'black+');
axis([meand1.t1(1) meand1.t1(end) 0 2000])

set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
datetick('x',20,'keepticks')
grid on;
legend('probe 1 asm\_ni\_v\_dep','probe 2 asm\_ni\_v\_indep','probe 1 asm\_ne\_5eV','probe 1 asm\_ni\_aion','probe 1 asm\_ne\_exp');

%legend('probe 1 asm\_ni\_v\_indep','probe 2 asm\_ni\_v\_indep','probe 1 asm\_ne','probe 2 asm\_ne');
title([sprintf('Density estimations probe 1&2 %s 19amu',shortphase)])




figure(1153)
plot(data1.t1,data1.asm_ni_v_dep,'b',data1.t1,data1.asm_ni_v_indep,'ro',data1.t1,data1.asm_ne_5eV,'black',data1.t1,data1.asm_ni_aion,'bo',data1.t1,data1.ne_exp,'blacko');

%plot(data1.t1,data1.asm_ni_v_indep,'ro',data2.t1,data2.asm_ni_v_indep,'blacko',data1.t1,data1.asm_ne_linear,'bo',data2.t1,data2.asm_ne_linear,'black+');
axis([data2.t1(1) data2.t1(end) 0 2000])

set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
datetick('x',20,'keepticks')
grid on;
legend('probe 1 asm\_ni\_v\_dep','probe 2 asm\_ni\_v\_indep','probe 1 asm\_ne\_5eV','probe 1 asm\_ni\_aion','probe 1 asm\_ne\_exp');

%legend('probe 1 asm\_ni\_v\_indep','probe 2 asm\_ni\_v\_indep','probe 1 asm\_ne','probe 2 asm\_ne');
title([sprintf('Density estimations probe 1&2 %s 19amu',shortphase)])



figure(1154)

%plot(data1.t1,data1.Vsg,'blackdiamond',data1.t1,data1.Vph_knee,'rdiamond')
plot(data1.t1,data1.asm_Vph_knee,'blackdiamond',data1.t1,data1.asm_Vsg,'rdiamond',data1.t1,data1.asm_Vsc_aion,'bo:',data1.t1,data1.Vsc_aion,'go:')
set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
datetick('x',20,'keepticks')
grid on;
legend('p1asm\_Vph\_knee','p1asm\_Vsg','p1asm\_Vsc\_aion','p1Vsc\_aion')






figure(153)
plot(data1.t1,data1.asm_ni_v_dep,'blacko',data2.t1,data2.ni_v_dep,'black',data1.t1,data1.ne_5eV,'ro',data2.t1,data2.ne_5eV,'r',data1.t1,data1.ne_linear,'bo',data2.t1,data2.ne_linear,'b');

%plot(data1.t1,data1.asm_ni_v_indep,'ro',data2.t1,data2.asm_ni_v_indep,'blacko',data1.t1,data1.asm_ne_linear,'bo',data2.t1,data2.asm_ne_linear,'black+');
axis([data2.t1(1) data2.t1(end) 0 2000])

set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
datetick('x',20,'keepticks')
grid on;
legend('probe 1 asm\_ni\_v\_dep','probe 2 ni\_v\_dep','probe 1 ne\_5eV','probe 2 ne\_5eV','probe 1 ne\_linear','probe 2 ne\_linear');

%legend('probe 1 asm\_ni\_v\_indep','probe 2 asm\_ni\_v\_indep','probe 1 asm\_ne','probe 2 asm\_ne');
title([sprintf('Density estimations probe 1&2 %s 19amu',shortphase)])




figure(154)

%plot(data1.t1,data1.Vsg,'blackdiamond',data1.t1,data1.Vph_knee,'rdiamond')
plot(data1.t1,data1.Vsg,'blackdiamond',data2.t1,data2.Vsg,'rdiamond',data1.t1,data1.asm_Vsg,'bo',data2.t1,data2.Vsg,'go')
set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
datetick('x',20,'keepticks')
grid on;
legend('p1Vsg','p2Vsg','p1asm_Vsg','p2asmVsg')

% 
% figure(70)
% plot(data1.t1,data1.asm_ni_v_indep,'ro',data1.t1,data1.asm_ni_v_dep,'blacko',data2.t1,data2.asm_ni_v_dep,'go',data2.t1,data2.asm_ni_v_indep,'bo')
% grid on;
% axis([data1.t1(1) data1.t1(end) 0 500])
% datetick('x',20)
% legend('probe1 asm\_ni\_v\_indep','probe1 asm\_ni\_v\_dep', 'probe2 asm\_ni\_v\_indep', 'probe2 asm\_ni\_v\_dep')
% 

% v_ion=[];
% v_ion2=[];
% 
% 
% for k=1:length(data.asm_ni_v_indep)
%     
%     tv=data.asm_ni_v_indep(k) / (data.asm_ni_v_dep(k) / 7000);
%     tv2=data.ni_v_indep(k) / (data.ni_v_dep(k) / 7000);
%     v_ion= [v_ion;tv];
%     v_ion2 = [v_ion2;tv2];
% end
v_u= nanmean([data1.asm_v_ion;data2.asm_v_ion]);
v_std=nanstd([data1.asm_v_ion;data2.asm_v_ion]);
% 
% v_u2= nanmean(v_ion2);
% v_std2=nanstd(v_ion2);
% 
figure(151)
subplot(2,1,1)

%plot(data1.t1,data1.asm_v_ion,'bo',data1.t1,v_u,'b',data2.t1,data2.asm_v_ion,'ro',data2.t1,nanmean(data2.asm_v_ion),'r')
plot(data1.t1,data1.asm_v_ion,'bo',data2.t1,data2.asm_v_ion,'ro',data1.t1,data1.asm_v_aion,'blacko')
%axis([data2.t1(1) data2.t1(end) 0 1E4])
grid on;
set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
datetick('x',20,'keepticks')
title([sprintf('%s Probe 1 & 2 Velocity estimation from ion current M10 19amu, average =%3.2f m/s',shortphase,v_u)]);
legend('probe 1 asm\_v\_ion','probe 2 asm\_v\_ion')
subplot(2,1,2)

%plot(data1.t1,data1.asm_v_ion,'bo',data1.t1,v_u,'b',data2.t1,data2.asm_v_ion,'ro',data2.t1,nanmean(data2.asm_v_ion),'r')
plot(data1.t1,data1.v_ion,'bo',data2.t1,data2.v_ion,'ro',data1.t1,data1.v_aion,'blacko')
%axis([data2.t1(1) data2.t1(end) 0 1E4])
grid on;
set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
datetick('x',20,'keepticks')
title([sprintf('%s Probe 1 & 2 Velocity estimation from ion current M10 19amu, average =%3.2f m/s',shortphase,v_u)]);
legend('probe 1 v\_ion','probe 2 v\_ion')


figure(60)
subplot(2,1,1)
plot(data1.ni_v_dep,data1.ni_v_indep,'ro',data2.ni_v_dep,data2.ni_v_indep,'bo',[0 1000],[0 1000],'black')

legend('probe 1','probe 2','y=x')
title([strcat(sprintf('%s',shortphase),' ni\_v\_dep vs ni\_v\_indep')])
%axis([0 1000 0 1000])
grid on;


subplot(2,1,2)
plot(data1.asm_ni_v_dep,data1.asm_ni_v_indep,'ro',data2.asm_ni_v_dep,data2.asm_ni_v_indep,'bo',[0 1000],[0 1000],'black')
legend('probe 1','probe 2','y=x')
title([strcat(sprintf('%s',shortphase),' asm\_ni\_v\_dep vs asm\_ni\_v\_indep')])
%axis([0 1000 0 1000])
grid on;



figure(163)
tx1=abs(mediand1.Tph(mediand1.Tph < 20 &mediand1.Tph > 0));
tx2=abs(mediand2.Tph(mediand2.Tph < 20 &mediand2.Tph > 0));

tx3=[tx1;tx2];

hist(tx3,10)
grid on;
title([strcat(sprintf('%s',shortphase),'abs(Tph) both probes, histogram, 1000 bins')])

%title('M07 abs(Tph) both probes, histogram, 1000 bins')
%------------------------------------------------------histogram

figure(1164)
subplot(2,1,1)

asm_vs1 = data1.asm_Vsc_aion(~isnan(data1.asm_Vsc_aion));
asm_vp1 = data1.asm_Vph_knee(~isnan(data1.asm_Vph_knee));


asm_vs1f=asm_vs1;
asm_vs1f(100<asm_vs1)  = 110;
asm_vs1f(-200>asm_vs1)=-210;

%vs1f = vs1(100>vs1&vs1>-1000);
%nvs=(max(vs1)-min(vs1))/1000;
%nvp=(max(vp1)-min(vp1))/1000;
hist(asm_vs1f,100);

hold on;

hist(asm_vp1,50);

h = findobj(gca,'Type','patch');
set(h(1),'FaceColor',[0 1 .5],'EdgeColor','black')
set(h(2),'FaceColor',[0 .5 .5],'EdgeColor','black')

title([strcat(sprintf('%s,median asmVscaion: %05.3f median asmVphknee: %05.3f',shortphase,median(asm_vs1),median(asm_vp1)),' asm\_Vsc\_aion probe1 , histogram, 1000 bins')])
legend('asm\_Vsc\_aion','asm\_Vph\_knee','Location','NorthWest');
grid on;
hold off;

subplot(2,1,2)

vs1 = data1.Vsc_aion(~isnan(data1.Vsc_aion));
vp1 = data1.asm_Vph_knee(~isnan(data1.asm_Vph_knee));


vs1f=vs1;
vs1f(100<vs1)  = 110;
vs1f(-200>vs1)=-210;

%vs1f = vs1(100>vs1&vs1>-1000);
%nvs=(max(vs1)-min(vs1))/1000;
%nvp=(max(vp1)-min(vp1))/1000;
hist(vs1f,100);

hold on;
hist(vp1,50);

h = findobj(gca,'Type','patch');
set(h(1),'FaceColor',[0 1 .5],'EdgeColor','black')
set(h(2),'FaceColor',[0 .5 .5],'EdgeColor','black')
title([strcat(sprintf('%s,median Vscaion: %05.3f median Vphknee: %05.3f',shortphase,median(vs1),median(vp1)),' asm\_Vsc\_aion probe1 , histogram, 1000 bins')])
legend('Vsc\_aion','Vph\_knee','Location','NorthWest');
grid on;
hold off;
%------------------------------------------------------



%------------------------------------------------------

figure(1100)

asm_valpha= [];
valpha= [];

for i=1:length(mediand1.t1)

    if  data1.asm_Vph_knee(i,1) > 0
        
    asm_valpha(i) = abs(mediand1.asm_Vph_knee(i,1)/mediand1.asm_Vsc_aion(i,1));
    else
            asm_valpha(i) = -abs(mediand1.asm_Vph_knee(i,1)/mediand1.asm_Vsc_aion(i,1));

    end
    
        if  data1.asm_Vph_knee(i,1) > 0
        
    valpha(i) = abs(mediand1.asm_Vph_knee(i,1)/mediand1.Vsc_aion(i,1));
    else
            valpha(i) = -abs(mediand1.asm_Vph_knee(i,1)/mediand1.Vsc_aion(i,1));

    end
    
    
    
end

asm_valpha = asm_valpha(~isnan(asm_valpha));
asm_valpha= asm_valpha(le(abs(asm_valpha),1));

alpha = valpha(~isnan(valpha));
valpha= valpha(le(abs(valpha),1));

subplot(1,2,1)


hist(asm_valpha,10);
grid on;
title([strcat(sprintf('mission phase %s,median alpha: %05.3f std alpha: %05.3f',shortphase,median(asm_valpha),std(asm_valpha)),' alpha= asm\_Vph\_knee / asm\_Vsc\_aion probe1 , histogram, 100 bins')])

legend('asm\_alpha= asm\_Vph\_knee / asm\_Vsc\_aion');

subplot(1,2,2)
hist(valpha,10);
grid on;
title([strcat(sprintf('mission phase %s,median alpha: %05.3f std alpha: %05.3f',shortphase,median(asm_valpha),std(asm_valpha)),' alpha= asm\_Vph\_knee / asm\_Vsc\_aion probe1 , histogram, 100 bins')])

legend('alpha= Vph\_knee / Vsc\_aion');



%--
figure(164)

ix1=mediand1.Iph0(~isnan(mediand1.Iph0));
ix2=mediand2.Iph0(~isnan(mediand2.Iph0));


ix3=[ix1;ix2];

hist(log10(abs(ix3)),20)
grid on;
title([strcat(sprintf('%s',shortphase),'log10(abs(Iph0)) both probes, histogram, 1000 bins')])


subplot(1,2,1)

ix1=mediand1.Iph0(~isnan(mediand1.Iph0));
ix2=mediand2.Iph0(~isnan(mediand2.Iph0));


ix3=[ix1;ix2];

hist(log10(abs(ix3)),20)
grid on;
title([strcat(sprintf('%s',shortphase),'log10(abs(Iph0)) both probes, histogram, 1000 bins')])



%title('M07 log10(abs(Iph0)) both probes, histogram, 1000 bins')


%figure(71)
% 
% plot(data1.t1,data1.asm_v_ion,'black+',data2.t1,data2.asm_v_ion,'ro')
% 
% grid on;
% %axis([data2.t1(1) data2.t1(end) 0 500])
% legend('probe 1 asm\_v\_ion','probe 2 asm\_v\_ion')
% set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
% datetick('x',20,'keepticks')
%title(sprintf('Probe 2 Velocity estimation from ion current M09 19amu, average =%3.2f m/s',v_u));

% %
% % figure(72)
% % 
% % 
% % plot(data2.t1,v_ion2,'o',data2.t1,v_u2,'r',data2.t1,v_u2-v_std2,'r-.',data2.t1,v_u2+v_std2,'r-.')
% % % %axis([data2.t1(1) data2.t1(end) 0 1E4])
% % set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
% % datetick('x',20,'keepticks')
% % grid on;
% % %axis([data2.t1(1) data2.t1(end) 0 500])
% % legend('v\_ion','average','standard deviation')
% % title(sprintf('Velocity estimation from ion current M09 19amu, average =%3.2f m/s',v_u2));
% % 
% 
% 
% 
% % 
% % y= nanmean(combine(:,4));
% % y_std=nanstd(combine(:,4));
% % 
% % 
% % 
% % fac=y/nanmean(combine(:,3));
% % 
% % %plot
% % 
% % plot(combine(:,1),combine(:,2),'go',combine(:,1),combine(:,4),'b+',combine(:,1),y,'r',combine(:,1),y-y_std,'r--',combine(:,1),y+y_std,'r--')
% % %title(sprintf('M09 Probe %i. If0 vs time, mean If0 = %16.6e',probe,y));
% % title(sprintf('M09 Probe %i. ne vs time mean ne= %16.6e',probe,y));
% % legend('ni_ram','asm_ne','average','standard deviation')
% % 
% 
% 
% figure(157)
% subplot(2,1,1)
% plot(data1.t1,data1.we_ni_v_indep,'ro:',data1.t1,data1.we_ni_vdep,'blacko:',data1.t1,data1.we_linear,'g',data1.t1,data1.we_5eV,'b')
% %plot(data2.t1,data2.asm_Vsg,'o');
% %legend('If0','\alpha SAA','Ion current y intersect','average','standard deviation')
% set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
% datetick('x',20,'keepticks')
% grid on;
% axis([data1.t1(1) data1.t1(end) 0 0.01])
% legend('asm\_ni\_v\_indep','asm\_ni\_v\_dep','asm\_ne','asm\_ne\_5eV');
% title([sprintf('Density estimations probe 1 %s 19amu vion = 7000m/s',shortphase)])
% 
% subplot(2,1,2)
% plot(data2.t1,data2.we_ni_v_indep,'ro:',data2.t1,data2.we_ni_vdep,'blacko:',data2.t1,data2.we_linear,'g',data2.t1,data2.we_5eV,'b')
% axis([data2.t1(1) data2.t1(end) 0 0.01])
% 
% set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
% datetick('x',20,'keepticks')
% grid on;
% 
% legend('asm\_ni\_v\_indep','asm\_ni\_v\_dep','asm\_ne','asm\_ne\_5eV');
% title([sprintf('Density estimations probe 2 %s 19amu vion = 7000m/s',shortphase)])
% 
% 
% 


 
 
 
 
figure(252)
subplot(2,2,1)
 
plot(mediand1.t1,mediand1.ne_exp,'b+',mediand1.t1,mediand1.ne_linear,'r',mediand1.t1,mediand1.ne_5eV,'g',mediand1.t1,mediand1.ni_v_indep,'ro',mediand1.t1,mediand1.ni_v_dep,'black',mediand1.t1,mediand1.asm_ni_v_indep,'blacko');
 
%plot(mediand1.t1,mediand1.ni_v_indep,'blacko:',mediand1.t1,mediand1.asm_ne_linear,'g',mediand1.t1,mediand1.asm_ne_5eV,'b',mediand1.t1,mediand1.asm_ne_exp,'ro')
%plot(mediand2.t1,mediand2.asm_Vsg,'o');
%legend('If0','\alpha SAA','Ion current y intersect','average','standard deviation')
set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
datetick('x',20,'keepticks')
grid on;
axis([mediand1.t1(1) mediand1.t1(end) 0 10000])
legend('ne\_exp','ne\_linear','ne\_5eV','ni\_v\_indep','ni\_v\_dep','asm\_ni\_v\_indep');
 
%legend('ni\_v\_indep','asm\_ne','asm\_ne\_5eV','asm\_ne\_exp');
title([sprintf('Density estimations probe 1 %s 19amu vion = 550m/s',shortphase)])
 
 
subplot(2,2,2)
 
plot(mediand2.t1,mediand2.ne_exp,'b+',mediand2.t1,mediand2.ne_linear,'r',mediand2.t1,mediand2.ne_5eV,'g',mediand2.t1,mediand2.ni_v_indep,'go',mediand2.t1,mediand2.ni_v_dep,'black',mediand2.t1,mediand2.asm_ni_v_indep,'blacko');
legend('ne\_exp','ne\_linear','ne\_5eV','ni\_v\_indep','ni\_v\_dep','asm\_ni\_v\_indep');
%plot(mediand2.t1,mediand2.ni_v_indep,'ro:',mediand2.t1,mediand2.ni_v_dep,'blacko:',mediand2.t1,mediand2.asm_ne_linear,'g',mediand2.t1,mediand2.asm_ne_5eV,'b',mediand2.t1,mediand2.asm_ne_exp,':')
axis([mediand2.t1(1) mediand2.t1(end) 0 10000])
 
set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
datetick('x',20,'keepticks')
grid on;
 
%legend('ni\_v\_indep','ni\_v\_dep','asm\_ne','asm\_ne\_5eV','asm\_ne\_exp');
title([sprintf('Density estimations probe 2 %s 19amu vion = 550m/s',shortphase)])
% 
% subplot(2,2,3)
% plot(mediand1.t1,mediand1.ni_v_indep,'blacko',mediand1.t1,mediand1.ni_v_dep,'ro',mediand1.t1,mediand1.asm_ni_v_indep,'bo',mediand1.t1,mediand1.asm_ni_v_dep,'go')
% %plot(mediand2.t1,mediand2.asm_Vsg,'o');
% %legend('If0','\alpha SAA','Ion current y intersect','average','standard deviation')
% set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
% datetick('x',20,'keepticks')
% grid on;
% axis([mediand1.t1(1) mediand1.t1(end) 0 10000])
% legend('ni\_v\_indep','ni\_v\_dep','asm\_ni\_v\_indep','asm\_ni\_v\_dep');
% title([sprintf('Density estimations probe 1 %s 19amu vion = 550m/s',shortphase)])
 
subplot(2,2,3)
plot(mediand1.t1,mediand1.ni_v_indep,'black',mediand1.t1,mediand1.ni_v_dep,'r',mediand1.t1,mediand1.asm_ni_v_indep,'bo',mediand1.t1,mediand1.asm_ni_v_dep,'go')
%plot(mediand2.t1,mediand2.asm_Vsg,'o');
%legend('If0','\alpha SAA','Ion current y intersect','average','standard deviation')
set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
datetick('x',20,'keepticks')
grid on;
axis([mediand1.t1(1) mediand1.t1(end) 0 10000])
legend('ni\_v\_indep','ni\_v\_dep','asm\_ni\_v\_indep','asm\_ni\_v\_dep');
title([sprintf('Density estimations probe 1 %s 19amu vion = 550m/s',shortphase)])
 
subplot(2,2,4)
plot(mediand1.t1,mediand1.ne_exp,'b+',mediand1.t1,mediand1.ne_linear,'r',mediand1.t1,mediand1.ne_5eV,'g');
 
%plot(mediand1.t1,mediand1.asm_ne_exp,'ro',mediand2.t1,mediand2.asm_ne_linear,'blacko',mediand1.t1,mediand1.asm_ne_5eV,'bo',mediand2.t1,mediand2.ne_linear,'black:',mediand1.t1,mediand1.ne_exp,'red:',mediand2.t1,mediand2.ne_5eV,'b:');
set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
datetick('x',20,'keepticks')
grid on;
axis([mediand1.t1(1) mediand1.t1(end) 0 2000])
legend('asm\_ne\_exp','ne\_linear','ne\_5eV');
title([sprintf('Density estimations probe 1 %s 19amu vion = 550m/s',shortphase)])
 
figure(2111)
 
plot(mediand1.t1,mediand1.asm_ni_v_dep,'b',mediand1.t1,mediand1.asm_ni_v_indep,'ro:',mediand1.t1,mediand1.asm_ne_5eV,'black',mediand1.t1,mediand1.asm_ni_aion,'bo:',mediand1.t1,mediand1.ne_exp,'black+:',mediand2.t1,mediand2.asm_ni_v_dep,'b+:',mediand2.t1,mediand2.asm_ni_v_indep,'r+:',mediand2.t1,mediand2.asm_ni_aion,'bdiamond:');
 
%plot(mediand1.t1,mediand1.asm_ni_v_indep,'ro',mediand2.t1,mediand2.asm_ni_v_indep,'blacko',mediand1.t1,mediand1.asm_ne_linear,'bo',mediand2.t1,mediand2.asm_ne_linear,'black+');
axis([mediand1.t1(1) mediand1.t1(end) 0 2000])
 
set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
datetick('x',20,'keepticks')
grid on;
legend('probe 1 asm\_ni\_v\_dep','probe 1 asm\_ni\_v\_indep','probe 1 asm\_ne\_5eV','probe 1 asm\_ni\_aion','probe 1 asm\_ne\_exp','probe 2 asm\_ni\_v\_dep','probe 2 asm\_ni\_v\_indep','probe 2 asm\_ni\_aion');
 
%legend('probe 1 asm\_ni\_v\_indep','probe 2 asm\_ni\_v\_indep','probe 1 asm\_ne','probe 2 asm\_ne');
title([sprintf('binned median Density estimations probe 1&2 %s 19amu,binned by macroblock',shortphase)])
 
 
 
 
figure(2153)
plot(mediand1.t1,mediand1.asm_ni_v_dep,'b',mediand1.t1,mediand1.asm_ni_v_indep,'ro',mediand1.t1,mediand1.asm_ne_5eV,'black',mediand1.t1,mediand1.asm_ni_aion,'bo',mediand1.t1,mediand1.ne_exp,'blacko');
 
%plot(mediand1.t1,mediand1.asm_ni_v_indep,'ro',mediand2.t1,mediand2.asm_ni_v_indep,'blacko',mediand1.t1,mediand1.asm_ne_linear,'bo',mediand2.t1,mediand2.asm_ne_linear,'black+');
axis([mediand2.t1(1) mediand2.t1(end) 0 2000])
 
set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
datetick('x',20,'keepticks')
grid on;
legend('probe 1 asm\_ni\_v\_dep','probe 2 asm\_ni\_v\_indep','probe 1 asm\_ne\_5eV','probe 1 asm\_ni\_aion','probe 1 asm\_ne\_exp');
 
%legend('probe 1 asm\_ni\_v\_indep','probe 2 asm\_ni\_v\_indep','probe 1 asm\_ne','probe 2 asm\_ne');
title([sprintf('Density estimations probe 1&2 %s 19amu',shortphase)])
 
 
 
figure(2154)
 
%plot(mediand1.t1,mediand1.Vsg,'blackdiamond',mediand1.t1,mediand1.Vph_knee,'rdiamond')
plot(mediand1.t1,mediand1.asm_Vph_knee,'blackdiamond',mediand1.t1,mediand1.asm_Vsg,'rdiamond',mediand1.t1,mediand1.asm_Vsc_aion,'bo',mediand2.t1,mediand2.asm_Vsc_aion,'go')
set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
datetick('x',20,'keepticks')
grid on;
legend('p1asm\_Vph\_knee','p1asm\_Vsg','p1asm\_Vsc\_aion','p2asm\_Vsc\_aion')
 
 
 
 
 
 
figure(253)
plot(mediand1.t1,mediand1.asm_ni_v_dep,'blacko',mediand2.t1,mediand2.ni_v_dep,'black',mediand1.t1,mediand1.ne_5eV,'ro',mediand2.t1,mediand2.ne_5eV,'r',mediand1.t1,mediand1.ne_linear,'bo',mediand2.t1,mediand2.ne_linear,'b');
 
%plot(mediand1.t1,mediand1.asm_ni_v_indep,'ro',mediand2.t1,mediand2.asm_ni_v_indep,'blacko',mediand1.t1,mediand1.asm_ne_linear,'bo',mediand2.t1,mediand2.asm_ne_linear,'black+');
axis([mediand2.t1(1) mediand2.t1(end) 0 2000])
 
set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
datetick('x',20,'keepticks')
grid on;
legend('probe 1 asm\_ni\_v\_dep','probe 2 ni\_v\_dep','probe 1 ne\_5eV','probe 2 ne\_5eV','probe 1 ne\_linear','probe 2 ne\_linear');
 
%legend('probe 1 asm\_ni\_v\_indep','probe 2 asm\_ni\_v\_indep','probe 1 asm\_ne','probe 2 asm\_ne');
title([sprintf('Density estimations probe 1&2 %s 19amu',shortphase)])
 
 
 
 
figure(254)
 
%plot(mediand1.t1,mediand1.Vsg,'blackdiamond',mediand1.t1,mediand1.Vph_knee,'rdiamond')
plot(mediand1.t1,mediand1.Vsg,'blackdiamond',mediand2.t1,mediand2.Vsg,'rdiamond',mediand1.t1,mediand1.asm_Vsg,'bo',mediand2.t1,mediand2.Vsg,'go')
set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
datetick('x',20,'keepticks')
grid on;
legend('p1Vsg','p2Vsg','p1asm_Vsg','p2asmVsg')
 
% 
% figure(70)
% plot(mediand1.t1,mediand1.asm_ni_v_indep,'ro',mediand1.t1,mediand1.asm_ni_v_dep,'blacko',mediand2.t1,mediand2.asm_ni_v_dep,'go',mediand2.t1,mediand2.asm_ni_v_indep,'bo')
% grid on;
% axis([mediand1.t1(1) mediand1.t1(end) 0 500])
% datetick('x',20)
% legend('probe1 asm\_ni\_v\_indep','probe1 asm\_ni\_v\_dep', 'probe2 asm\_ni\_v\_indep', 'probe2 asm\_ni\_v\_dep')
% 
 
% v_ion=[];
% v_ion2=[];
% 
% 
% for k=1:length(data.asm_ni_v_indep)
%     
%     tv=data.asm_ni_v_indep(k) / (data.asm_ni_v_dep(k) / 7000);
%     tv2=data.ni_v_indep(k) / (data.ni_v_dep(k) / 7000);
%     v_ion= [v_ion;tv];
%     v_ion2 = [v_ion2;tv2];
% end
v_u= nanmean([mediand1.asm_v_ion;mediand2.asm_v_ion]);
v_std=nanstd([mediand1.asm_v_ion;mediand2.asm_v_ion]);
% 
% v_u2= nanmean(v_ion2);
% v_std2=nanstd(v_ion2);
% 
figure(251)
subplot(2,1,1)
 
%plot(mediand1.t1,mediand1.asm_v_ion,'bo',mediand1.t1,v_u,'b',mediand2.t1,mediand2.asm_v_ion,'ro',mediand2.t1,nanmean(mediand2.asm_v_ion),'r')
plot(mediand1.t1,mediand1.asm_v_ion,'bo:',mediand2.t1,mediand2.asm_v_ion,'ro:',mediand1.t1,mediand1.asm_v_aion,'blacko:',mediand2.t1,mediand2.asm_v_aion,'blackdiamond:')
%axis([mediand2.t1(1) mediand2.t1(end) 0 1E4])
grid on;
set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
datetick('x',20,'keepticks')
title([sprintf('%s Probe 1 & 2 Velocity estimation from ion current M10 19amu, average =%3.2f m/s',shortphase,v_u)]);
legend('probe 1 asm\_v\_ion','probe 2 asm\_v\_ion','probe 1 asm\_v\_aion','probe 2 asm\_v\_aion')
subplot(2,1,2)
 
%plot(mediand1.t1,mediand1.asm_v_ion,'bo',mediand1.t1,v_u,'b',mediand2.t1,mediand2.asm_v_ion,'ro',mediand2.t1,nanmean(mediand2.asm_v_ion),'r')
plot(mediand1.t1,mediand1.v_ion,'bo:',mediand2.t1,mediand2.v_ion,'ro:',mediand1.t1,mediand1.v_aion,'blacko:',mediand2.t1,mediand2.v_aion,'blackdiamond:')
%axis([mediand2.t1(1) mediand2.t1(end) 0 1E4])
grid on;
set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
datetick('x',20,'keepticks')
title([sprintf('%s Probe 1 & 2 Velocity estimation from ion current M10 19amu, average =%3.2f m/s',shortphase,v_u)]);
legend('probe 1 v\_ion','probe 2 v\_ion','probe 1 v\_aion','probe 2 v\_aion')
 
 
figure(60)
subplot(2,1,1)
plot(mediand1.ni_v_dep,mediand1.ni_v_indep,'ro',mediand2.ni_v_dep,mediand2.ni_v_indep,'bo',[0 1000],[0 1000],'black')
 
legend('probe 1','probe 2','y=x')
title([strcat(sprintf('%s',shortphase),' ni\_v\_dep vs ni\_v\_indep')])
%axis([0 1000 0 1000])
grid on;
 
 
subplot(2,1,2)
plot(mediand1.asm_ni_v_dep,mediand1.asm_ni_v_indep,'ro',mediand2.asm_ni_v_dep,mediand2.asm_ni_v_indep,'bo',[0 1000],[0 1000],'black')
legend('probe 1','probe 2','y=x')
title([strcat(sprintf('%s',shortphase),' asm\_ni\_v\_dep vs asm\_ni\_v\_indep')])
%axis([0 1000 0 1000])
grid on;
 
 
 

