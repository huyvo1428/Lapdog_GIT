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

fld={'t1' 'Iph0' 'Tph' 'START_TIME_UTC' 'asm_ni_v_indep' 'asm_ni_v_dep' 'asm_ne_exp' 'ne_exp' 'asm_ne_linear' 'asm_ne_5eV' 'asm_Vsg', 'ni_v_dep' 'ni_v_indep' 'ne_linear' 'ne_5eV' 'Vsg' 'Te_linear' 'Te_exp'  'asm_Te_linear' 'asm_Te_exp' 'asm_v_ion' 'v_ion'};

len = length(fld);

data1=dataraw(1);

for j=2:length(dataraw)

   for k=1:len

       data1.(sprintf('%s',fld{1,k})) = [[data1.(sprintf('%s',fld{1,k}))];[dataraw(j).(sprintf('%s',fld{1,k}))]];
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



%enter the field names of the values you are interested in here

%fld={'t1' 'asm_ni_v_indep' 'asm_ni_v_dep' 'asm_ne_linear' 'asm_ne_5eV' 'asm_Vsg', 'ni_v_dep' 'ni_v_indep' 'ne_linear' 'ne_5eV' 'Vsg' 'asm_Te_linear' 'asm_Te_exp' 'asm_v_ion'};


data2=dataraw(1);

for j=2:length(dataraw)

   for k=1:len

       data2.(sprintf('%s',fld{1,k})) = [[data2.(sprintf('%s',fld{1,k}))];[dataraw(j).(sprintf('%s',fld{1,k}))]];
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


if strcmp(shortphase,'EAR3')
    
    data1.asm_ni_v_dep =   data1.asm_ni_v_dep *2/7;
    data2.asm_ni_v_dep =   data2.asm_ni_v_dep *2/7;
    
end



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







figure(153)
plot(data1.t1,data1.ni_v_dep,'blacko',data2.t1,data2.ni_v_dep,'black',data1.t1,data1.ne_5eV,'ro',data2.t1,data2.ne_5eV,'r',data1.t1,data1.ne_linear,'bo',data2.t1,data2.ne_linear,'b');

%plot(data1.t1,data1.asm_ni_v_indep,'ro',data2.t1,data2.asm_ni_v_indep,'blacko',data1.t1,data1.asm_ne_linear,'bo',data2.t1,data2.asm_ne_linear,'black+');
axis([data2.t1(1) data2.t1(end) 0 2000])

set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
datetick('x',20,'keepticks')
grid on;
legend('probe 1 ni\_v\_dep','probe 2 ni\_v\_dep','probe 1 ne\_5eV','probe 2 ne\_5eV','probe 1 ne\_linear','probe 2 ne\_linear');

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
plot(data1.t1,data1.asm_v_ion,'bo',data2.t1,data2.asm_v_ion,'ro')
%axis([data2.t1(1) data2.t1(end) 0 1E4])
grid on;
set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
datetick('x',20,'keepticks')
title([sprintf('%s Probe 1 & 2 Velocity estimation from ion current M10 19amu, average =%3.2f m/s',shortphase,v_u)]);
legend('probe 1 asm\_v\_ion','probe 2 asm\_v\_ion')
subplot(2,1,2)

%plot(data1.t1,data1.asm_v_ion,'bo',data1.t1,v_u,'b',data2.t1,data2.asm_v_ion,'ro',data2.t1,nanmean(data2.asm_v_ion),'r')
plot(data1.t1,data1.v_ion,'bo',data2.t1,data2.v_ion,'ro')
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
tx1=abs(data1.Tph(data1.Tph < 20 &data1.Tph > 0));
tx2=abs(data2.Tph(data2.Tph < 20 &data2.Tph > 0));

tx3=[tx1;tx2];

hist(tx3,1000)
grid on;
title([strcat(sprintf('%s',shortphase),'abs(Tph) both probes, histogram, 1000 bins')])

%title('M07 abs(Tph) both probes, histogram, 1000 bins')

figure(164)
ix1=data1.Iph0(~isnan(data1.Iph0));
ix2=data2.Iph0(~isnan(data2.Iph0));


ix3=[ix1;ix2];

hist(log10(abs(ix3)),1000)
grid on;
title([strcat(sprintf('%s',shortphase),'log10(abs(Iph0)) both probes, histogram, 1000 bins')])

title('M07 log10(abs(Iph0)) both probes, histogram, 1000 bins')


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






