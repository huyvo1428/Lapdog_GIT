%function [] = readA_S()




indAxS = find(strcmp('sweep', an_tabindex(:,7)));
SAA=[];
Vplasma=[];
VSC=[];

matrix=[];


for i=1:length(indAxS)

    

        arID = fopen(an_tabindex{indAxS(i),1},'r');
        
        if arID < 0
            fprintf(1,'Error, cannot open file %s\n', tabindex{an_ind(i),1});
            break
        end % if I/O error
        
        scantemp=textscan(arID,'%s %s %d %f %f %f %f %f %f %f %*[^\n]','delimiter',',');
        
        
        
        [junk,junk,qf,SAA,sun,VSC,junk,Vplasma,a,junk] = scantemp{:};
        
        fclose(arID);
        
        hell0 = scantemp(1,4);
        matrix=[matrix;SAA,sun,VSC,Vplasma,a];
        
        
%         
%     SAA(end+1) = [scantemp(1,4)];
%     Vplasma(end+1,1) =  scantemp(1,8);
%     Vplasma(end+1,2) = scantemp(1,9);
%     VSC(end+1,1) = scantemp(1,6);
%     
%     
end

figure(25)

issun= matrix(:,2);


subplot(2,2,1);
plot(matrix(matrix(:,2),3));
subplot(2,2,2)
plot(matrix(matrix(:,2),4));

plot(matrix(matrix(:,2)==1,1),matrix(matrix(:,2)==1,3),'r');

plot(matrix(matrix(:,2)==1,1),matrix(matrix(:,2)==1,3),'r')

'hello'


