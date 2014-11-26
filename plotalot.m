%plotalot.m


antype = cellfun(@(x) x(end-6:end-4),tabindex(:,2),'un',0);


probe = 2;

str1 = sprintf('I%iS',probe); %I1S or I2S
str2 = sprintf('A%iS',probe); %A1S or A2S


a_ind= find(strcmp(str1, antype));


%ind_I2S= find(strcmp('I2S', antype));


figure(5);
combine =[];



for i=1:length(a_ind)
    
    
    if i==100
        break
    end
    
    
    
    %fout=cell(1,7);
    
    rfile =tabindex{a_ind(i),1};
    rfile = strrep(rfile,str1,str2); %I1S-> A1S
    
    i
%    rfile
    
    data=lap_import(rfile);
    
    
    
    
    
%    data=lap_import('/Users/frejon/Documents/RosettaArchive/PDS_Archives/DATASETS/SECOND_DELIVERY_VERSIONS/RO-C-RPCLAP-5-M08-DERIV-V0.2/2014/OCT/D13/RPCLAP_20141013_000001_604_A1S.TAB')
    formatin = 'YYYY-mm-ddTHH:MM:SS';
    
    
    t1 =datenum(cspice_et2utc(cspice_str2et(data.START_TIME_UTC),'ISOC',0),formatin);
    
    if i > 1
        combine = [combine;t1,data.If0,data.SAA,data.ion_y_intersect];
    else
        
    combine =[t1,data.If0,data.SAA,data.ion_y_intersect];
    end
       
end

y= nanmean(combine(:,2));
y_std=nanstd(combine(:,2));



fac=y/nanmean(combine(:,3));

%plot

plot(combine(:,1),combine(:,2),'go',combine(:,1),combine(:,3)*fac,'black',combine(:,1),combine(:,4),'b+',combine(:,1),y,'r',combine(:,1),y-y_std,'r--',combine(:,1),y+y_std,'r--')
title(sprintf('M09 Probe %i. If0 vs time, mean If0 = %16.6e',probe,y));
legend('If0','\alpha SAA','Ion current y intersect','average','standard deviation')
datetick('x',21)
grid on;


