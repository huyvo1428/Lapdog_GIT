%PAR2PHYS converts the parameters used in the sweep to physical units
%
% [phys_par] = par2phys(par,handles,ref)
%
% The reference indicates one or two electron populations
function phys_par = par2phys(par,handles,ref)
phys_par = [];
Ap = 0.0078539816; %Probe area [m^2]
rp = 0.025; %Probe radius [m]
qe = 1.60217733e-19; %elementary charge [C]
%kB = 8.617385e-5; %Boltzmanns constant [eV/K]
kB = 1.380658e-23; %Boltzmanns constant [J/K]
me = 9.1093897e-31; %electron mass [kg]
%setting s/c speed and ion mass
mi = handles.ion_mass;
vsc = handles.vsc;
Tph1 = par(3)*11600;
Tph2 = par(4)*11600;
Iph01 = -par(1)*par(12);
Iph02 = -par(2)*par(12);
Ii0 = -par(5);
Ti = -par(5)/par(6);
Ie01 = par(7);
Te1 = 1/par(8)*11600;
Ie02 = par(9);
Te2 = 1/par(10)*11600;
Vsc = par(11);
f = par(12);
z = par(13);

%pars5 = [a b c d g h Vsc f]; 
% par_out(1:4) = par(1:4); %Iph01,Iph02,Tph1,Tph2
% par_out(5:12) = pars5; %The parameters
% par_out(13) = par(13); %z is unaltered
% par_out(14) = err; %The error
% 


if (handles.fit_try_all == 1)
    switch par(15); %need to determine which model was choosen
        case 1
            handles.e_plasma = 1; %plasmaelectrons
            handles.e_sc = 0; %no sc-electrons
            handles.e_photo = 0; %no photoelectrons
            handles.i_ram = 1; %ram ions
            handles.fit_partial = 1; %fit partial data (one e-pop)
        case 2
            handles.e_plasma = 1; %plasmaelectrons
            handles.e_sc = 0; %no sc-electrons
            handles.e_photo = 1; %photoelectrons
            handles.i_ram = 1; %ram ions
            handles.fit_partial = 1; %fit partial data (one e-pop)
        case 3
            handles.e_plasma = 1; %plasmaelectrons
            handles.e_sc = 0; %no sc-electrons
            handles.e_photo = 0; %no photoelectrons
            handles.i_ram = 0; %thermal ions
            handles.fit_partial = 1; %fit partial data (one e-pop)
        case 4
            handles.e_plasma = 1; %plasmaelectrons
            handles.e_sc = 0; %no sc-electrons
            handles.e_photo = 1; %photoelectrons
            handles.i_ram = 0; %thermal ions
            handles.fit_partial = 1; %fit partial data (one e-pop)
        case 5
            handles.e_plasma = 1; %plasmaelectrons
            handles.e_sc = 1; %sc-electrons
            handles.e_photo = 0; %no photoelectrons
            handles.i_ram = 1; %ram ions
            handles.fit_partial = 0; %fit all data points (two e-pops)
        case 6
            handles.e_plasma = 1; %plasmaelectrons
            handles.e_sc = 1; %sc-electrons
            handles.e_photo = 1; %photoelectrons
            handles.i_ram = 1; %ram ions
            handles.fit_partial = 0; %fit all data points (two e-pops)
        case 7
            handles.e_plasma = 1; %plasmaelectrons
            handles.e_sc = 1; %sc-electrons
            handles.e_photo = 0; %no photoelectrons
            handles.i_ram = 0; %thermal ions
            handles.fit_partial = 0; %fit all data points (two e-pops)
        case 8
            handles.e_plasma = 1; %plasmaelectrons
            handles.e_sc = 1; %sc-electrons
            handles.e_photo = 1; %photoelectrons
            handles.i_ram = 0; %thermal ions
            handles.fit_partial = 0; %fit all data points (two e-pops)
    end
end
%Determine the densities
n_e1 = Ie01/(Ap*qe*sqrt((kB*Te1)/(2*pi*me))); %density of electrons 1
n_e2 = Ie02/(Ap*qe*sqrt((kB*Te2)/(2*pi*me))); %density of electrons 2
if (handles.fit_free_densities == 1)
    n_i = Ii0/(Ap*qe*sqrt((kB*Ti*11600)/(2*pi*mi)));
end
%If we have quasineutrality, ni = ne, so it can be determined
if (handles.fit_quasineutral == 1)
    n_i = n_e1;
end
if (handles.i_ram == 1) %ram ions
    mi = Ti*2*qe/(vsc^2);
else %thermal ions
    mi = (Ap*qe*n_i/Ii0)^2*(kB*Ti*11600)/(2*pi);
end
phys_par(1) = Vsc;
%phys_par(2) = e;
phys_par(3) = f;
phys_par(4) = z;
phys_par(5) = Iph01;
phys_par(6) = Iph02;
phys_par(7) = Tph1;
phys_par(8) = Tph2;
phys_par(9) = n_i;
phys_par(10) = Ti;
phys_par(11) = mi;
phys_par(12) = n_e1;
phys_par(14) = n_e2;
phys_par(13) = Te1;
phys_par(15) = Te2;
phys_par(16) = Ie02;
if (handles.fit_try_all == 1)
    phys_par(17) = par(15);
else
    phys_par(17) = 0;
end
