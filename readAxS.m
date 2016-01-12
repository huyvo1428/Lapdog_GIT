% Does not appear to be used (called) by Lapdog itself.

%function [] = readA_S()
SAA=[];
Vplasma=[];
VSC=[];

matrix=[];
matrix2=[];

read_an_tabindex = 0;


derivedpath ='/Users/frejon/Documents/RosettaArchive/PDS_Archives/DATASETS/SECOND_DELIVERY_VERSIONS/RO-C-RPCLAP-5-M04-DERIV-V0.1/';


if ~(read_an_tabindex)
%if isempty(an_tabindex(:,))


fileList = getAllFiles(derivedpath);


antype = cellfun(@(x) x(end-6:end),fileList,'un',0);


ind_A1S= find(strcmp('A1S.TAB', antype));
ind_A2S= find(strcmp('A2S.TAB', antype));

indAxS = [ind_A1S;ind_A2S];

for i=1:length(ind_A1S)
    
    arID = fopen(fileList{ind_A1S(i),1},'r');
    
   % afileList=fileList(indAxS);
    
        if arID < 0
            fprintf(1,'Error, cannot open file %s', tabindex{an_ind(i),1});
            break
        end % if I/O error
        
        scantemp=textscan(arID,'%s %s %d %f %f %f %f %f %f %f %*[^\n]','delimiter',',');
        
        
        
        [utc0,junk,qf,SAA,sun,VSC,junk,Vplasma,a,junk] = scantemp{:};
        
        fclose(arID);
        
        for j=1:length(utc0)
            
            utc0{j,1}= strrep(utc0{j,1}(1:23),'T',' ');
            
        end
        
        
        hell0 = scantemp(1,4);
        matrix=[matrix;SAA,sun,VSC,Vplasma,a,datenum(utc0,31)];

end%for

for i=1:length(ind_A2S)
    
    arID = fopen(fileList{ind_A2S(i),1},'r');
    
   % afileList=fileList(indAxS);
    
        if arID < 0
            fprintf(1,'Error, cannot open file %s', tabindex{an_ind(i),1});
            break
        end % if I/O error
        
        scantemp=textscan(arID,'%s %s %d %f %f %f %f %f %f %f %*[^\n]','delimiter',',');
        
        
        
        [utc0,junk,qf,SAA,sun,VSC,junk,Vplasma,a,junk] = scantemp{:};
        
        fclose(arID);
        
        for j=1:length(utc0)
            
            utc0{j,1}= strrep(utc0{j,1}(1:23),'T',' ');
            
        end
        
        
        hell0 = scantemp(1,4);
        matrix2=[matrix2;SAA,sun,VSC,Vplasma,a,datenum(utc0,31)];

end%for



else
    
    
    
    
    indAxS = find(strcmp('sweep', an_tabindex(:,7)));

    
    
    for i=1:length(indAxS)
        
        
        
        arID = fopen(an_tabindex{indAxS(i),1},'r');
        
        if arID < 0
            fprintf(1,'Error, cannot open file %s', tabindex{an_ind(i),1});
            break
        end % if I/O error
        
        scantemp=textscan(arID,'%s %s %d %f %f %f %f %f %f %f %*[^\n]','delimiter',',');
        
        
        [utc0,junk,qf,SAA,sun,VSC,junk,Vplasma,a,junk] = scantemp{:};
        
        fclose(arID);
        
        hell0 = scantemp(1,4);
        matrix=[matrix;SAA,sun,VSC,Vplasma,a,utc0];
        
        %
        %     SAA(end+1) = [scantemp(1,4)];
        %     Vplasma(end+1,1) =  scantemp(1,8);
        %     Vplasma(end+1,2) = scantemp(1,9);
        %     VSC(end+1,1) = scantemp(1,6);
        %
        %
    end %for
end %if


figure(25)

issun= matrix(:,2);


nan4=isnan(matrix(:,4));

ind=matrix(:,2) & ~(nan4) ;


subplot(2,2,1);
plot(matrix(ind,6),matrix(ind,4),'r',matrix(ind,6),matrix(ind,5),'b')

axis([datenum(2014,06,01) datenum(2014,07,02) -20 40])

datetick('x',31,'keeplimits');

subplot(2,2,2)
plot(matrix(matrix(:,2),4));

plot(matrix(matrix(:,2)==1,1),matrix(matrix(:,2)==1,3),'r');

plot(matrix(matrix(:,2)==1,1),matrix(matrix(:,2)==1,3),'r')

'hello'


