%plotalot.m
addpath('/Users/frejon/Documents/RosettaArchive/lap_import')

antype = cellfun(@(x) x(end-6:end-4),tabindex(:,2),'un',0);


probe = 1;

str1 = sprintf('I%iS',probe); %I1S or I2S
str2 = sprintf('A%iS',probe); %A1S or A2S


a_ind= find(strcmp(str1, antype));

j = 1;

i = length(a_ind);
clear dataraw

for i=1:length(a_ind)
    
    
    if i==100
        break
    end
    
    
    
    %fout=cell(1,7);
    
    rfile =tabindex{a_ind(i),1};
    rfile = strrep(rfile,str1,str2); %I1S-> A1S
    
    i
%    rfile
    
  %  data=lap_import(rfile);
    
%     
%     (sprintf('temp_%d',i)
%     
    
%    data=lap_import('/Users/frejon/Documents/RosettaArchive/PDS_Archives/DATASETS/SECOND_DELIVERY_VERSIONS/RO-C-RPCLAP-5-M08-DERIV-V0.2/2014/OCT/D13/RPCLAP_20141013_000001_604_A1S.TAB')
    formatin = 'YYYY-mm-ddTHH:MM:SS';
    
        temp=lap_import(rfile);   
        temp.t1 = datenum(cspice_et2utc(cspice_str2et(temp.START_TIME_UTC),'ISOC',0),formatin);

        dataraw(i) = temp;
        
%     t1 =datenum(cspice_et2utc(cspice_str2et(data.START_TIME_UTC),'ISOC',0),formatin);
%     
%     if i > 1
%         combine = [combine;t1,data.asm_ni_ram,data.asm_ne_5eV,data.asm_ne];
%     else
%         
%     combine =[t1,data.asm_ni_ram,data.asm_ne_5eV,data.asm_ne];
%     end
       
end

%enter the field names of the values you are interested in here

fld={'t1' 'asm_ni_v_indep' 'asm_ni_v_dep' 'asm_ne_linear' 'asm_ne_5eV' 'asm_Vsg', 'ni_v_dep' 'ni_v_indep' 'ne_linear' 'ne_5eV' 'Vsg' 'asm_Te_linear' 'asm_Te_exp' 'asm_v_ion'};

len = length(fld);


%fld={'t1' 'asm_ni_v_indep' 'asm_ni_v_dep' 'asm_ne_linear' 'asm_ne_5eV' 'asm_Vsg', 'asm_Te_linear' 'asm_Te_exp' 'asm_v_ion'};




data=dataraw(1);

for j=2:length(dataraw)

   for k=1:len

       data.(sprintf('%s',fld{1,k})) = [[data.(sprintf('%s',fld{1,k}))];[dataraw(j).(sprintf('%s',fld{1,k}))]];
   end  
       
end
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

% figure(70)
% plot(data.t1,data.asm_ni_v_indep,'ro',data.t1,data.asm_ni_v_dep,'blacko',data.t1,data.asm_ne_linear,'g',data.t1,data.asm_ne_5eV,'b')
% %plot(data2.t1,data2.asm_Vsg,'o');
% %legend('If0','\alpha SAA','Ion current y intersect','average','standard deviation')
% datetick('x',20)
% grid on;
% axis([data.t1(1) data.t1(end) 0 500])
% legend('asm\_ni\_slope*intsct','asm\_ni\_slope\_7000m/s','asm\_ne','asm\_ne\_5eV');
% title('Probe 2 density estimations probe 1 M09 19amu')


figure(70)
plot(data.t1,data.asm_ni_v_indep,'ro',data.t1,data.asm_ni_v_dep,'blacko',data2.t1,data2.asm_ni_v_dep,'go',data2.t1,data2.asm_ni_v_indep,'bo')
grid on;
axis([data.t1(1) data.t1(end) 0 500])
datetick('x',20)
legend('probe1 asm\_ni\_v\_indep','probe1 asm\_ni\_v\_dep', 'probe2 asm\_ni\_v\_indep', 'probe2 asm\_ni\_v\_dep')


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
% v_u= nanmean(v_ion);
% v_std=nanstd(v_ion);
% 
% v_u2= nanmean(v_ion2);
% v_std2=nanstd(v_ion2);
% 
% %plot(data.t1,v_ion,'o',data.t1,v_u,'r',data.t1,v_u-v_std,'r-.',data.t1,v_u+v_std,'r-.')
%axis([data2.t1(1) data2.t1(end) 0 1E4])
figure(71)

plot(data.t1,data.asm_v_ion,'black+',data2.t1,data2.asm_v_ion,'ro')

grid on;
%axis([data2.t1(1) data2.t1(end) 0 500])
legend('probe 1 asm\_v\_ion','probe 2 asm\_v\_ion')
datetick('x',20)
%title(sprintf('Probe 2 Velocity estimation from ion current M09 19amu, average =%3.2f m/s',v_u));

%
% figure(72)
% 
% 
% plot(data2.t1,v_ion2,'o',data2.t1,v_u2,'r',data2.t1,v_u2-v_std2,'r-.',data2.t1,v_u2+v_std2,'r-.')
% %axis([data2.t1(1) data2.t1(end) 0 1E4])
% datetick('x',20)
% grid on;
% %axis([data2.t1(1) data2.t1(end) 0 500])
% legend('v\_ion','average','standard deviation')
% title(sprintf('Velocity estimation from ion current M09 19amu, average =%3.2f m/s',v_u2));
% 



% 
% y= nanmean(combine(:,4));
% y_std=nanstd(combine(:,4));
% 
% 
% 
% fac=y/nanmean(combine(:,3));
% 
% %plot
% 
% plot(combine(:,1),combine(:,2),'go',combine(:,1),combine(:,4),'b+',combine(:,1),y,'r',combine(:,1),y-y_std,'r--',combine(:,1),y+y_std,'r--')
% %title(sprintf('M09 Probe %i. If0 vs time, mean If0 = %16.6e',probe,y));
% title(sprintf('M09 Probe %i. ne vs time mean ne= %16.6e',probe,y));
% legend('ni_ram','asm_ne','average','standard deviation')
% 

% 
