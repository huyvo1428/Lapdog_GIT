len = length(RPCLAP1409021Y7SRDS28BS(:,1));
corredited = zeros(len,2);
old_corredited = zeros(len,2);
conv = zeros(len,4);
for i=1:len
    
    %a = potential
    a = RPCLAP1409021Y7SRDS28BS{i,2};
    %b = position of that potential in calibV 
    pos1= find(a==mCALIBMEAS3(:,1),1,'first');
    
    
    
    %copy potential
    corredited(i,2) = mCALIBVBIAS(pos1,3);
    %edit current
 %   modedited(i,1)=RPCLAP1409021Y7SRDS28BS{i,1}-calibI2(b);

    %find position of current in CALIBIBIASplot(1:length(conv(:,2)),conv(:,1),'+',1:length(conv(:,2)),conv(:,4),'o',1:length(conv(:,2)),3.05180438E-10,'r')
   % pos2=find(RPCLAP1409021Y7SRDS28BS{i,1}==mCALIBIBIAS(:,1),1,'first');
    
    
    corredited(i,1)=3.05180438E-10*(RPCLAP1409021Y7SRDS28BS{i,1}-mCALIBMEAS3(pos1,3));
        
    conv(i,1) = RPCLAP1409021Y7SCDS28BS{i,1}/(RPCLAP1409021Y7SRDS28BS{i,1}-mCALIBMEAS3(pos1,3));
    conv(i,2)= RPCLAP1409021Y7SCDS28BS{i,1}/(RPCLAP1409021Y7SRDS28BS{i,1}+mCALIBMEAS3(pos1,3));
    conv(i,3)= RPCLAP1409021Y7SCDS28BS{i,1}/(RPCLAP1409021Y7SRDS28BS{i,1});
    

    
    
    old_corredited(i,2) = mCALIBVBIAS(pos1,3);
    old_corredited(i,1) = 3.05180438E-10*(RPCLAP1409021Y7SRDS28BS{i,1}-CALIBMEAS2{pos1,3});
    
    conv(i,4)= RPCLAP1409021Y7SCDS28BS{i,1}/(RPCLAP1409021Y7SRDS28BS{i,1}-CALIBMEAS2{pos1,3}-mCALIBVBIAS(pos1,3));
end



arr= cell2mat(RPCLAP1409021Y7SCDS28BS);



%plot(modedited(:,2),modedited(:,1),'r',cell2mat(RPCLAP1409021Y7SCDS28BS(:,2)),cell2mat(RPCLAP1409021Y7SCDS28BS(:,1)),'g')
figure(5)

ini = 6;

arr=arr(ini:end,:);
corredited=corredited(ini:end,:);
old_corredited=old_corredited(ini:end,:);
subplot(1,2,1)
plot(corredited(:,2),corredited(:,1),'+',arr(:,2),arr(:,1),'o',old_corredited(:,2),old_corredited(:,1),'+g')
subplot(1,2,2)
plot(arr(:,2),arr(:,1)/corredited(:,1),'+',arr(:,2),arr(:,1)/old_corredited(:,1),'o')



mCALIBIBIAS=cell2mat(CALIBIBIAS);
figure(6)

coeff = polyfit(mCALIBIBIAS(:,1),mCALIBIBIAS(:,2),1);
coeff2 = polyfit(mCALIBIBIAS(:,1),mCALIBIBIAS(:,3),1);


plot(mCALIBIBIAS(:,1),mCALIBIBIAS(:,2)-mCALIBIBIAS(:,1)*coeff(1)-coeff(2),'r',mCALIBIBIAS(:,1),mCALIBIBIAS(:,3)-mCALIBIBIAS(:,1)*coeff2(1)-coeff2(2),'b');





