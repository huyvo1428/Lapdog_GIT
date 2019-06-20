%function lapbitor takes an array of LAP qualityflags, combines it using bitwise-or to output a single value
%example: A = [0 40 2 40], x = 42
%conveniently, this example fails to detect that bitor(620,10) =622, it
%simply doesn't work on larger numbers. How I missed that is ridiculous
function x=frejonbitor(A)
x=uint32(A(1)); %make sure flags are handled as unsigned integers
if length(A)>1


    %use matrix notation. This whole screw up makes everything 4-12 times
    %slower. Which is an improvement over my first bugfix of 160xslower
    %( which relied on loops)
    A_rem100=mod(A,100);%e.g. mod(642,100)=42
    A_100=uint32((A-A_rem100)/100);%e.g. (642-42)/100=6
    A_10=uint32((A_rem100-mod(A_rem100,10))/10);%e.g (42-2)/10= 4
    A_1=uint32(mod(A,10));%e.g mod(642,100)=2;
    
    
    x_100=frejonbitor_part2(unique(A_100));
    x_10 =frejonbitor_part2(unique(A_10));
    x_1  =frejonbitor_part2(unique(A_1));
    

    
    x=x_100*100+x_10*10+x_1;
    
end
end

%this shit works on values like 6,4,2,1
function x=frejonbitor_part2(A)
len = length(A); %length of array A
x=uint32(A(1)); %make sure flags are handled as unsigned integers
if len>1

    
    for i = 2:len %loop all values in array A
        
        x=bitor(x,uint32(A(i))); %bitwise each value with x, one at a time, store results in x
    end
        
end
end
%functio