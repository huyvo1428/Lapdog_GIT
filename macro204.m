Matrix204I1Ssort = Matrix204I1S.';
Matrix204I2Ssort = Matrix204I2S.';

Matrix204I2Ssort(:,1:23) = [];
%Matrix204I1Ssort(:,10:end) = [];




I1sdown=Matrix204I2Ssort(1:104,:);
I2sup=Matrix204I2Ssort(105:end-1,:);


%Matrix204I1Ssort(:,end-5:end) = [];

I2sdown=Matrix204I2Ssort(1:104,:);
I2sup=Matrix204I2Ssort(105:end-1,:);
I1sup=Matrix204I1Ssort(122:end,:);
I1sdown=Matrix204I1Ssort(1:120,:);
ind1 = 120:-1:1;
I1sup=I1sup(ind1,:); %rotate


ind2 = 104:-1:1;

I2sup=I2sup(ind2,:); %rotate


diffI1supdown = I1sdown - I1sup;
diffI2supdown = I2sdown - I2sup;



i1s_1 = Matrix204I1Ssort(:,1:10);
i1s_2 = Matrix204I1Ssort(:,11:30);
i1s_3 = Matrix204I1Ssort(:,21:40);
i1s_4 = Matrix204I1Ssort(:,31:50);
i1s_5 = Matrix204I1Ssort(:,41:60);
i1s_6 = Matrix204I1Ssort(:,51:70);
i1s_7 = Matrix204I1Ssort(:,61:70);
i1s_8 = Matrix204I1Ssort(:,71:end);


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
i1_1= 1E9*mean(diffI1supdown_1);

std1u_2 = 1E9*mean(diffI1supdown_2,2)+1E9*std(diffI1supdown_2,1,2);
std1d_2 = 1E9*mean(diffI1supdown_2,2)-1E9*std(diffI1supdown_2,1,2);
i1_2= 1E9*mean(diffI1supdown_2);

std1u_3 = 1E9*mean(diffI1supdown_3,2)+1E9*std(diffI1supdown_3,1,2);
std1d_3 = 1E9*mean(diffI1supdown_3,2)-1E9*std(diffI1supdown_3,1,2);
i1_3= 1E9*mean(diffI1supdown_3);

std1u_4 = 1E9*mean(diffI1supdown_4,2)+1E9*std(diffI1supdown_4,1,2);
std1d_4 = 1E9*mean(diffI1supdown_4,2)-1E9*std(diffI1supdown_4,1,2);
i1_4= 1E9*mean(diffI1supdown_4);

std1u_5 = 1E9*mean(diffI1supdown_5,2)+1E9*std(diffI1supdown_5,1,2);
std1d_5 = 1E9*mean(diffI1supdown_5,2)-1E9*std(diffI1supdown_5,1,2);
i1_5= 1E9*mean(diffI1supdown_5);

std1u_6 = 1E9*mean(diffI1supdown_6,2)+1E9*std(diffI1supdown_6,1,2);
std1d_6 = 1E9*mean(diffI1supdown_6,2)-1E9*std(diffI1supdown_6,1,2);
i1_6= 1E9*mean(diffI1supdown_6);

std1u_7 = 1E9*mean(diffI1supdown_7,2)+1E9*std(diffI1supdown_7,1,2);
std1d_7 = 1E9*mean(diffI1supdown_7,2)-1E9*std(diffI1supdown_7,1,2);
i1_7= 1E9*mean(diffI1supdown_7);

std1u_8 = 1E9*mean(diffI1supdown_8,2)+1E9*std(diffI1supdown_8,1,2);
std1d_8 = 1E9*mean(diffI1supdown_8,2)-1E9*std(diffI1supdown_8,1,2);
i1_8= 1E9*mean(diffI1supdown_8);




V1 = V_P1(1:120) ;

V2 = V_P2(1:104);

figure(6);
title(' 10 Sep 2014 Macro 204       Probe 2 10 Sep 2014 macro 204');
subplot(2,2,1);
plot(1E9*Matrix204I2Ssort);
grid on;
axis([0 210 -12 40]);
xlabel('step nr');
ylabel('nA');
title(' 10 Sep 2014 Macro 204       P2 Sweep current vs time');

subplot(2,2,2);
plot(V_P2,1E9*Matrix204I2Ssort(:,:));
grid on;
title(' 10 Sep 2014 Macro 204        P2 sweep current vs Vbias');
ylabel('nA');


V1 = V_P1(1:120) ;
V2 = V_P2(1:104);

subplot(2,2,3);
plot(V2,1E9*diffI2supdown);
grid on;
axis([-25 25 -10 10]);
xlabel('V');
ylabel('nA');

title(' 10 Sep 2014 Macro 204        P2 diff up/down on each potential step');




subplot(2,2,2);
plot(1E9*Matrix204I1Ssort);
grid on;
title(' 10 Sep 2014 Macro 204       P1 Sweep current vs time');
axis([0 240 -12 40]);
xlabel('step nr');
ylabel('nA');

subplot(2,2,4);

plot(V1,i1_1,V1,i1_2,V1,i1_3,V1,i1_4,V1,i1_4,V1,i1_6,V1,i1_7,V1,i1_8);
%plot(V_P1(1:120),1E9*diffI1supdown);
grid on;
axis([-30 30 -10 10]);
title(' 10 Sep 2014 Macro 204        P1 diff up/down on each potential step');
xlabel('V');
ylabel('nA');

figure(5);
std1u = 1E9*mean(diffI1supdown,2)+1E9*std(diffI1supdown,1,2);
std1d = 1E9*mean(diffI1supdown,2)-1E9*std(diffI1supdown,1,2);


std2u = 1E9*mean(diffI2supdown,2)+1E9*std(diffI2supdown,1,2);
std2d = 1E9*mean(diffI2supdown,2)-1E9*std(diffI2supdown,1,2);

V1 = V_P1(1:120) ;

V2 = V_P2(1:104);




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
axis([-30 30 -10 10]);
title(' 10 Sep 2014 Macro 204        Mean P1 & P2 diff up/down on each potential step & standard devation');
xlabel('V');
ylabel('nA');
%text(10,0,'\leftarrow sin(-\pi\div4)','HorizontalAlignment','left')
str2 = sprintf(' k=%5.2e \noffset = %5.2e',P1(1),P1(2));
str1 = sprintf(' k=%5.2e \noffset = %5.2e',P2(1),P2(2));

text(-10,1.6,str1,'HorizontalAlignment','left')'
text(-10,-3.5,str2,'HorizontalAlignment','left')


hleg1 = legend('Probe 1 mean diff','Probe 2 mean diff');


