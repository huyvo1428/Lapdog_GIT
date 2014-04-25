





function [x] = michel(kE)

condition =1;

while condition
    x =1.0*kE*rand;
    y =1/exp(x/kE);
    
    condition = rand<y;
end
end

