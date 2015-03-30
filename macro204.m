

    
%fileList = getAllFiles('/Users/frejon/Documents/RosettaArchive/PDS_Archives/DATASETS/SECOND_DELIVERY_VERSIONS/204/I_S/');

bfileList = getAllFiles('/Users/frejon/Documents/RosettaArchive/PDS_Archives/DATASETS/SECOND_DELIVERY_VERSIONS/204/B_S/');



    for i=1:length(fileList)
        
        j=i*2 -1 ;
        
        
        rfile=fileList{j,1}(1:end);
        rfile2=fileList{j+1,1}(1:end);
        
        bfile=bfileList{j,1}(1:end);
        bfile2=bfileList{j+1,1}(1:end);


        if exist(rfile)==2 && strcmp(rfile(end-3:end),'.TAB');
            temp=lap_import(rfile);
            temp2=lap_import(rfile2);
            
            temp.sweeps = temp.sweeps.';
            temp2.sweeps = temp2.sweeps.';
            I1sdown = temp.sweeps(1:120,:);
            I1sup   = temp.sweeps(122:end,:);
            I2sup  =temp2.sweeps(105:end-1,:);
            I2sdown =temp2.sweeps(1:104,:);

            btemp = lap_import(bfile);
            btemp2 = lap_import(bfile2);
            
            V_P1 = btemp.bias_potentials;
            V_P2 = btemp2.bias_potentials;
            
            

%I2sdown=Matrix204I2Ssort(1:104,:);
%I2sup=Matrix204I2Ssort(105:end-1,:);
%I1sup=temp.sweeps(122:end,:);
%I1sdown=temp.sweeps(1:120,:);
ind1 = 120:-1:1;
I1sup=I1sup(ind1,:); %rotate


ind2 = 104:-1:1;

I2sup=I2sup(ind2,:); %rotate


diffI1supdown = I1sdown - I1sup;
diffI2supdown = I2sdown - I2sup;


g8 = floor(length(temp.sweeps(:,1))/8);

i1s_1 = temp.sweeps(:,1:g8);
i1s_2 = temp.sweeps(:,g8+1:2*g8);
i1s_3 = temp.sweeps(:,2*g8+1:3*g8);
i1s_4 = temp.sweeps(:,3*g8+1:4*g8);
i1s_5 = temp.sweeps(:,4*g8+1:5*g8);
i1s_6 = temp.sweeps(:,5*g8+1:6*g8);
i1s_7 = temp.sweeps(:,6*g8+1:7*g8);
i1s_8 = temp.sweeps(:,7*g8+1:end);


i1sdown_1=i1s_1(1:120,:);
i1sup_1=i1s_1(122:end,:);
i1sup_1=i1sup_1(ind1,:); %rotate
diffI1supdown_1 = i1sdown_1 - i1sup_1;

i1sdown_2=i1s_2(1:120,:);
i1sup_2=i1s_2(122:end,:);
i1sup_2=i1sup_2(ind1,:); %rotate
diffI1supdown_2 = i1sdown_2 - i1sup_2;

i1sdown_3=i1s_3(1:120,:);
i1sup_3=i1s_3(122:end,:);
i1sup_3=i1sup_3(ind1,:); %rotate
diffI1supdown_3 = i1sdown_3 - i1sup_3;

i1sdown_4=i1s_4(1:120,:);
i1sup_4=i1s_4(122:end,:);
i1sup_4=i1sup_4(ind1,:); %rotate
diffI1supdown_4 = i1sdown_4 - i1sup_4;

i1sdown_5=i1s_5(1:120,:);
i1sup_5=i1s_5(122:end,:);
i1sup_5=i1sup_5(ind1,:); %rotate
diffI1supdown_5 = i1sdown_5 - i1sup_5;

i1sdown_6=i1s_6(1:120,:);
i1sup_6=i1s_6(122:end,:);
i1sup_6=i1sup_6(ind1,:); %rotate
diffI1supdown_6 = i1sdown_6 - i1sup_6;

i1sdown_7=i1s_7(1:120,:);
i1sup_7=i1s_7(122:end,:);
i1sup_7=i1sup_7(ind1,:); %rotate
diffI1supdown_7 = i1sdown_7 - i1sup_7;

i1sdown_8=i1s_8(1:120,:);
i1sup_8=i1s_8(122:end,:);
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




V1 = V_P1(1:120) ;

V2 = V_P2(1:104);

figure(6);


time1=temp.START_TIME_UTC{1,1}(1:10);

title([sprintf('%s Macro 204       Probe 2',time1)]);

%title(' 10 Sep 2014 Macro 204       Probe 2 10 Sep 2014 macro 204');
subplot(2,2,1);
plot(1E9*temp2.sweeps);
grid on;
axis([0 210 -12 40]);
xlabel('step nr');
ylabel('nA');
title([sprintf('%s Macro 204        P2 Sweep current vs time',time1)]);


subplot(2,2,2);
plot(V_P2,1E9*temp2.sweeps(:,:));
grid on;

title([sprintf('%s Macro 204        P2 Sweep current vs Vbias',time1)]);

ylabel('nA');


V1 = V_P1(1:120) ;
V2 = V_P2(1:104);

subplot(2,2,3);
plot(V2,1E9*diffI2supdown);
grid on;
axis([-25 25 -10 10]);
xlabel('V');
ylabel('nA');

title([sprintf('%s Macro 204        P2 diff up/down on each potential step',time1)]);




subplot(2,2,2);
plot(1E9*temp.sweeps);
grid on;
title([sprintf('%s Macro 204        P1 Sweep current vs time',time1)]);

axis([0 240 -12 40]);
xlabel('step nr');
ylabel('nA');

subplot(2,2,4);

plot(V1,i1_1,V1,i1_2,V1,i1_3,V1,i1_4,V1,i1_4,V1,i1_6,V1,i1_7,V1,i1_8);
%plot(V_P1(1:120),1E9*diffI1supdown);
grid on;
axis([-30 30 -10 10]);
title([sprintf('%s Macro 204        P1 diff up/down on each potential step',time1)]);

xlabel('V');
ylabel('nA');

figure(5);
std1u = 1E9*mean(diffI1supdown,2)+1E9*std(diffI1supdown,1,2);
std1d = 1E9*mean(diffI1supdown,2)-1E9*std(diffI1supdown,1,2);


std2u = 1E9*mean(diffI2supdown,2)+1E9*std(diffI2supdown,1,2);
std2d = 1E9*mean(diffI2supdown,2)-1E9*std(diffI2supdown,1,2);




a= find(V1<0,1,'first');

b = find(V2<0,1,'first');



[P1,S] = polyfit(V2(b:end),mean(diffI2supdown(b:end,:),2),1);
%fit2_2 = P(3) + P(2)*V2(b:end)+P(1)*V2(b:end).^2;
fit2_1 = P1(2) + P1(1)*V2(b:end);

[P2,S] = polyfit(V1(a:end),mean(diffI1supdown(a:end,:),2),1);
fit1_1 = P2(2) + P2(1)*V1(a:end);

%fit1_2 = P(3) + P(2)*V1(a:end)+P(1)*V1(a:end).^2;

plot(V1(a:end),fit1_1,'r',V2(b:end),fit2_1,'b')


plot(V1,1E9*mean(diffI1supdown,2),'or',V2,1E9*mean(diffI2supdown,2),'ob',V1,std1u,'--r',V1,std1d,'--r',V2,std2u,'--b',V2,std2d,'--b',V1(a:end),1E9*fit1_1,'black',V2(b:end),1E9*fit2_1,'black');

%plot(V_P1(1:120),1E9*mean(diffI1supdown,2),'or',V_P2(1:104),1E9*mean(diffI2supdown,2),'ob');
grid on;
axis([-30 30 -20 10]);

title([sprintf('%s Macro 204        Mean P1 & P2 diff up/down on each potential step & standard devation',time1)]);

xlabel('V');
ylabel('nA');
%text(10,0,'\leftarrow sin(-\pi\div4)','HorizontalAlignment','left')
str2 = sprintf(' k=%5.2e \noffset = %5.2e',P1(1),P1(2));
str1 = sprintf(' k=%5.2e \noffset = %5.2e',P2(1),P2(2));

text(-10,1.6,str1,'HorizontalAlignment','left')'
text(-10,-3.5,str2,'HorizontalAlignment','left')


hleg1 = legend('Probe 1 mean diff','Probe 2 mean diff');
            
            
        end
    end
    
         
%         
%         if exist(rfile)==2 && strcmp(rfile(end-3:end),'.TAB');
%             
%             formatin = 'YYYY-mm-ddTHH:MM:SS';
%             
%             temp=lap_import(rfile);
% 
%             
%         end
%     
%     
%     
%     Matrix204I1S=1;
%     Matrix204I2S=1;
% 
% temp.sweeps = Matrix204I1S.';
% Matrix204I2Ssort = Matrix204I2S.';
% 
% Matrix204I2Ssort(:,1:23) = [];
% %temp.sweeps(:,10:end) = [];


% 
% 
% I1sdown=Matrix204I2Ssort(1:104,:);
% I2sup=Matrix204I2Ssort(105:end-1,:);
% 
% 
%%%%temp.sweeps(:,end-5:end) = [];


