%function lapbitor takes an array of LAP qualityflags, combines it using bitwise-or to output a single value
%example: A = [0 40 2 40], x = 42
function x=frejonbitor(A)
len = length(A); %length of array A
x=uint32(A(1)); %make sure flags are handled as unsigned integers
if len>1

    for i = 1:len %loop all values in array A
    x=bitor(x,uint32(A(i))); %bitwise each value with x, one at a time, store results in x
    end
end
end
