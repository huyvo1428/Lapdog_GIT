function [Iph] = gen_ph_current(V,Vbplasma,Iph0,Tph,model)

ind=find(V-Vbplasma>0,1,'first');
Iph = V;
Iph(:) = Iph0; % if V is a column/row vector, Iph is now a column/row vector of same size



%in regards to models, read "ROSETTA LANGMUIR PERFORMANCE by Fredrik
%Johansson" or Rejean Grard


if model == 1  % photoelectrons from a sphere
    

       
    Iph(ind:end) =Iph0*exp(-(V(ind:end)-Vbplasma)/Tph);
   
elseif model == 2 %photoelectrons from a point
    
    for i=ind:length(V)
        Iph(i) = Iph0*(1+(V(i)-Vbplasma)/Tph)*exp(-(V(i)-Vbplasma)/Tph);
        
    end

    
    
   % Iph(ind:end) =Iph0*((V(ind:end)-Vbplasma)/Tph)*exp(-(V(ind:end)-Vbplasma)/Tph);
    
end



end





