% Analyses sweeps, utilising modded version of Anders an_swp code, and other
% methods.
function [XXP] = an_sweepmain(an_ind,tabindex,targetfullname)

global an_tabindex der_struct;
global target;
global diag_info
global CO IN     % Physical & instrumental constants
global SATURATION_CONSTANT;


global assmpt;

        assmpt =[];
        assmpt.Vknee = 0; %dummy
        assmpt.Tph = 2; %eV
        assmpt.Iph0 = -6.6473e-09;   % from median of M06 & SPIS simulation
        %    assmpt.Iph0 = -8.55e-09; % from mean of M08, probably too high.
        assmpt.vram = 4E5; % Solar wind assumption
        assmpt.ionZ = 1;   % SW assumption
        assmpt.ionM = 1;   % SW assumption



dynampath = strrep(mfilename('fullpath'),'/an_sweepmain_v2','');
kernelFile = strcat(dynampath,'/metakernel_rosetta.txt');
paths(); 

cspice_furnsh(kernelFile);


k=0; %needed for error output

try

    for i=1:length(an_ind)     % iterate over sweep files...

        % get file, read variables etc
        rfile =tabindex{an_ind(i),1};                  % Sweep file
        rfolder = strrep(tabindex{an_ind(i),1},tabindex{an_ind(i),2},'');
        %tabindex{an_ind(i),1}(end-10:end-8)
        mode      = rfile(end- 6:end-4);
        diagmacro = rfile(end-10:end-8);
        probe     = rfile(end-5);

        diag_info{1} = strcat(diagmacro,'P',probe); %remember probe and macro everywhere for debugging
        diag_info{2} = rfile; %let's also remember the full name

        arID = fopen(tabindex{an_ind(i),1},'r');                   % Open sweep file.

        if arID < 0
            fprintf(1,'Error, cannot open file %s\n', tabindex{an_ind(i),1});
            break
        end % if I/O error

        scantemp = textscan(arID,'%s','delimiter',',','CollectOutput', true);   % Reads all values into one long 1D vector of strings.

        fclose(arID);

        rfile(end-6)='B';
        arID = fopen(rfile,'r');                                 % Open sweep potentials/times file.
        scantemp2 = textscan(arID,'%f%f','delimiter',',');


        % scantemp=textscan(arID,'%s%f%f%f%d','delimiter',',');
        fclose(arID);

        steps = length(scantemp2{1,2})+5;       % Nbr of values per sweep: currents/voltages + 4 timestamps + 1 QF
        N_file_values = numel(scantemp{1,1});   % Nbr of values in sweep data file (all sweeps & columns).
        N_sp = N_file_values/steps;             % Nbr of sweep/pairs. sp = sweep/pair

        if mod(N_file_values,steps) ~=0
            fprintf(1,'error, bad sweepfile at \n %s \n, aborting %s mode analysis\n',rfile,mode);
            return
        end


        A = reshape(scantemp{1,1},steps,N_file_values/steps);        % Matrix of STRINGS (<column nbr>, <sweep/pair index>)
        Iarr= str2double(A(6:end,1:end));                  % Matrix of doubles (<sweep voltage nbr>, <sweep/pair index>)
        timing = {A{1,1},A{2,end},A{3,1},A{4,end}};        % Timing for entire analysis file.
        Qfarr =str2double(A(5,:));

        Vb = scantemp2{1,2};              % Voltage, for each sweep/pair.

        Tarr = A(1:4,1:end);              % Matrix for individual sweep times: (<column nbr>, <sweep/pair index>)

        
        
        %----------- SATURATION HANDLING FKJN 6/3 2018 ---------------%
        satur_ind = Iarr==SATURATION_CONSTANT; % logical matrix which is true if any current is saturated (pds outputs -1000 as of 6/3 2018)
        %Iarr(Iarr==SATURATION_CONSTANT)    = NaN;
        Iarr(satur_ind) = NaN;% This should also work, so we don't have to
        %do this twice
        %
        %note that this index needs special handling for V or /\ sweeps
        %(see :if split), etc
        %-------------------------------------------------------------%
        
        % Classify "sweep" depending on voltage curve: one/two sweeps, up/down, where split.
        potdiff = diff(Vb);
        upd = max(0,sign(potdiff));    % is an int either 0 or 1...
        if potdiff(1) > 0 && Vb(end)~=max(Vb)
            % potbias looks like V.

            mind=find(Vb==max(Vb));
            split = 1;
            upd = [ 0 1];

        elseif potdiff(1) <0 && Vb(end)~=min(Vb)
            % potbias looks like upside-down V.

            mind=find(Vb==min(Vb));
            split = -1;
            upd = [ 1 0];
        else
            split = 0;
        end



        if split

            % Split data for first and second sweep in sweep pair.
            Vb2   = Vb(mind:end);
            Iarr2 = Iarr(mind:end,:);
           % satur_ind2 = satur_ind(mind:end,:);%mirror Iarr treatment everywhere.
            

            Vb   = Vb(1:mind);
            Iarr = Iarr(1:mind,:);
           % satur_ind = satur_ind(1:mind,:); %mirror Iarr treatment everywhere.

            Tarr2 = Tarr;
            t_sweep_rel = scantemp2{1,1};     % Time, relative to beginning of sweep/pair sequence (one/two sweeps).
            t_diff = t_sweep_rel(mind);

            for i_sp = 1:N_sp         % sp = sweep pair

                % Take start time and add time interval.
                % NOTE: Not important which time system is used for converting UTC string, since converts back to UTC string anyway.
                t_spm_utc_str = cspice_et2utc(   cspice_str2et(Tarr{ 1, i_sp}) + t_diff, 'ISOC', 6);    % spm = sweep pair middle
                t_spm_nbr_str = num2str( str2double(Tarr{ 4, i_sp}) + t_diff,   '%f' );

                Tarr{  2, i_sp} = t_spm_utc_str;
                Tarr{  4, i_sp} = t_spm_nbr_str;
                Tarr2{ 1, i_sp} = t_spm_utc_str;
                Tarr2{ 3, i_sp} = t_spm_nbr_str;
            end
        end



        % 'preloaded' is a dummy entry, just so orbit realises spice kernels
        % are already loaded.
        [altitude,SEA,SAA]=orbit('Rosetta',Tarr(1:2,:),target,'ECLIPJ2000','preloaded');
        clear junk
 

        if strcmp(mode(2),'1') %probe 1
            
            
                   %%%
        % *Anders values* (converted to the present solar aspect angle definition
        % by ADDING 90 degrees):
        %
           Phi11 = 131;
           Phi12 = 181;

        %%%
        % *My values* (from photoemission study):
           % Phi11 = 131.2;%degrees
            %Phi12 = 179.2;
            %lap1_ill = ((Phi < Phi11) | (Phi > Phi12));

            SAA_OK = ((SAA < Phi11) | (SAA > Phi12)); %1 = sunlit
            illuminati = SAA_OK;
            

        else %we will hopefully never have sweeps with probe number "3"

            %%%
            % *Anders values* (+90 degrees)
            Phi21 = 18;
            Phi22 = 82;
            Phi23 = 107;
            %illuminati = ((SAA < Phi21) | (SAA > Phi22));

            illuminati = ((SAA < Phi21) | (SAA > Phi22)) - 0.6*((SAA > Phi22) & (SAA < Phi23));
            % illuminati = illuminati - 0.6*((SAA > Phi22) & (SAA < Phi23));
        end
        
        SEA_OK = abs(SEA)<1; %  <1 degree  = nominal pointing
        illuminati(~SEA_OK)=0.3;
        %clear SEA_OK SAA_OK;

        len = length(Iarr(1,:));     % Number of sweeps/pairs. Should be identical to N_sp. Kept for now.
        %  cspice_str2et(



        %% initialise output struct


        %tscsweep = str2double(Tarr{3,1});

        %check if we are close to comet
        %(3000 km ? 1000*radius of comet)


    %    if (le(altitude(end),3000) && strcmp(target,'CHURYUMOV-GERASIMENKO'))
        if strcmp(target,'CHURYUMOV-GERASIMENKO')

            %date = cspice_et2utc(cspice_str2et(Tarr{ 1,1}), 'ISOC', 0);
            %formatin = 'YYYY-mm-ddTHH:MM:SS';
            %this if should have worked, but MatLab sucks between versions and
            %linux/mac differences.
            %            if datenum(Tarr{1,1}(1:19),formatin) < datenum('2015-01-01T00:00:00',formatin)378691143.436616

            if (str2double(Tarr{3,1}) > 365904090.294412)%if past 6 aug 2014 (ESA blog post "arrival at comet")

                assmpt.vram = 550; %m/s
                assmpt.ionZ = +1; % ion charge
                assmpt.ionM = 19; % atomic mass units
                %assmpt.v_SW = 5E5; %500 km/s
            end
        end



        %Edit 31 Aug 2015 added new Iph0 selector, to be used with Norwegian Iph0
        %results.
        %EDIT 6 April 2016, FKJN modified Iph0 selector, to be used with Niklas results

        
        switch str2double(probe)           

            case 1
                iph0file = 'iph0_probe1.txt';                                
            case 2
                iph0file = 'iph0_probe2.txt';                
        end    
        
        assmpt.Iph0 = Iph0selector(iph0file,str2double(Tarr{3,1}));
        
        
        %Anders analysed parameters
        AP(len).ts       = [];
        AP(len).vx       = [];
        AP(len).Tph      = [];
        AP(len).Iph0     = [];
        AP(len).vs       = [];
        AP(len).lastneg  = [];
        AP(len).firstpos = [];
        AP(len).poli1    = [];
        AP(len).poli2    = [];
        AP(len).pole1    = [];
        AP(len).pole2    = [];
        AP(len).probe    = [];
        AP(len).vbinf    = [];
        AP(len).diinf    = [];
        AP(len).d2iinf   = [];
        AP(len).Vz       = [];


        %EP = extra parameters, not from functions

        EP(len).tstamp   = [];
        EP(len).SAA      = [];
        EP(len).qf       = [];
        EP(len).Tarr     = {};
        EP(len).lum      = [];
        EP(len).split    = [];
        EP(len).dir      = [];
%
%         EP(len).ni_1comp = [];
%         EP(len).ni_2comp = [];
%         EP(len).v_ion    = [];
        EP(len).ne_5eV   = [];
        EP(len).Vsc_ni_ne= [];

%         EP(len).ni_aion    = [];
%         EP(len).Vsc_aion   = [];
%         EP(len).v_aion = [];
%         EP(len).asm_ni_aion    = [];
%         EP(len).asm_Vsc_aion   = [];
%         EP(len).asm_v_aion = [];
%
%         EP(len).asm_ni_1comp = [];
%         EP(len).asm_ni_2comp = [];
%         EP(len).asm_v_ion    = [];
        EP(len).asm_ne_5eV   = [];
        EP(len).asm_Vsc_ni_ne= [];
        EP(len).curr = [];
        EP(len).B = [];
        


        % Derived parameters from sweep
        DP(len).Iph0                = [];
        DP(len).Tph                 = [];
        DP(len).Vsi                 = [];
        DP(len).Te                  = [];
        DP(len).ne                  = [];

        DP(len).Vsg                 = [];
        DP(len).Vph_knee            = [];
        DP(len).Vbar                = [];

        DP(len).Vsg_lowAc           = [];
        DP(len).Vph_knee_lowAc      = [];
        DP(len).Vbar_lowAc          = [];


        DP(len).ion_Vb_slope        = [];
        DP(len).ion_Vb_intersect    = [];
        DP(len).ion_slope           = [];
        DP(len).ion_intersect       = [];
        DP(len).ion_Up_slope        = [];
        DP(len).ion_Up_intersect    = [];


        DP(len).ni_1comp            = [];
        DP(len).ni_2comp            = [];
        DP(len).v_ion               = [];

        DP(len).ni_aion             = [];
        DP(len).Vsc_aion            = [];
        DP(len).v_aion              = [];


        DP(len).e_Vb_slope          = [];
        DP(len).e_Vb_intersect      = [];
        DP(len).e_slope             = [];
        DP(len).e_intersect         = [];

        DP(len).Tphc                = [];
        DP(len).nphc                = [];
        DP(len).phc_slope           = [];
        DP(len).phc_intersect       = [];

        DP(len).Te_exp              = [];
        DP(len).Ie0_exp             = [];
        DP(len).ne_exp              = [];

        DP(len).Te_exp_belowVknee   = [];
        DP(len).Ie0_exp_belowVknee  = [];
        DP(len).ne_exp_belowVknee   = [];


        DP(len).Quality             = [];
        DP(len).Rsq                 = [];


        DP_asm= DP;



        % analyse!


%         parfor k=1:len    % Iterate over first sweep in every potential sweep pair (one/two sweeps)
        for k=1:len    % Iterate over first sweep in every potential sweep pair (one/two sweeps)

            %  a= cspice_str2et(timing{1,k});

            % quality factor check
            qf = Qfarr(k);

            if (abs(SAA(1, 2*k-1)-SAA(1, 2*k)) >0.05) %rotation of more than 0.05 degrees  %arbitrary chosen value... seems decent
                qf = qf+20; %rotation
            end
            
%             if (any(satur_ind(:,k))) 
%                 qf = qf+400; % saturation flagging
%             end
            

            EP(k).split = 0;
            EP(k).SAA = mean(SAA(1,2*k-1:2*k));
            EP(k).lum = mean(illuminati(1,2*k-1:2*k));
            EP(k).Tarr = {Tarr{:,k}};
            EP(k).tstamp = Tarr{3,k};
            EP(k).qf = qf;
            EP(k).dir = upd(1);

            % Anders LP sweep analysis
            AP(k) = an_swp(Vb,Iarr(:,k),cspice_str2et(Tarr{1,k}),mode(2),EP(k).lum);

            
            
            if k>1
                Vguess = DP(k-1).Vph_knee(1);

            else
                Vguess = 0;
            end

            [DP(k),DP_asm(k)] = an_LP_Sweep_v2(Vb, Iarr(:,k),Vguess,EP(k).lum);

            %DP(k) = an_LP_Sweep(Vb, Iarr(:,k),Vguess,EP(k).lum);
            %DP_asm(k) = an_LP_Sweep_with_assmpt(Vb),Iarr(:,k),assmpt,EP(k).lum);

            Te_guess = 5;%eV
            %EP(k).ne_5eV = abs(1e-6*DP(k).e_intersect(1)/(IN.probe_A*-CO.e*sqrt(CO.e*Te_guess/(2*pi*CO.me))));
            %EP(k).asm_ne_5eV = abs(1e-6*DP_asm(k).e_intersect(1)/(IN.probe_A*-CO.e*sqrt(CO.e*Te_guess/(2*pi*CO.me))));
            EP(k).ne_5eV        = max(1e-6*sqrt(2*pi*CO.me*Te_guess) * DP(k).e_slope(1) / (IN.probe_A*CO.e.^1.5),0); %max out of expression and 0 -> if >0, ne=0;
            EP(k).asm_ne_5eV    = max(1e-6*sqrt(2*pi*CO.me*Te_guess) * DP_asm(k).e_slope(1) / (IN.probe_A*CO.e.^1.5),0);%max out of expression and 0 -> if >0, ne=0;
            EP(k).asm_Vsc_ni_ne = nansum((DP_asm(k).ion_Vb_intersect(1)-(sqrt(DP_asm(k).ion_intersect(1))*DP_asm(k).ne(1)/DP_asm(k).ni_2comp(1)).^2)/DP_asm(k).ion_slope(1));
            EP(k).Vsc_ni_ne     = nansum((DP(k).ion_Vb_intersect(1)    -(sqrt(DP(k).ion_intersect(1))    *DP(k).ne(1)    /DP(k).ni_2comp(1)).^2)    /DP(k).ion_slope(1));

            
           
        end % parfor
            %double some arrays, it's annoying, but whatevs.  

        if (split~=0)    % If every sweep/pair is really two sweeps...

            %parfor k=1:length(Iarr2(1,:))     % Iterate over second sweep in every sweep pair (two sweeps together)
            for k=1:length(Iarr2(1,:))     % Iterate over second sweep in every sweep pair (two sweeps together)
                m=k+len;
                %note Vb =! Vb2, Iarr =! Iarr2, etc.
                % quality factor check
                qf = Qfarr(k);

                if (abs(SAA(1, 2*k-1)-SAA(1, 2*k)) >0.05) %rotation of more than 0.01 degrees
                    qf = qf+20; %rotation
                end
                
%                 
%                 if (any(satur_ind2(:,k)))
%                     qf = qf+400; % saturation flagging not necessary.
%                     Done in createTAB and already in QF array
%                 end
                
                

                EP(m).split = split;  % 1 for V form, -1 for upside-down V
                EP(m).SAA = mean(SAA(1,2*k-1:2*k));
                EP(m).lum = mean(illuminati(1,2*k-1:2*k));
                EP(m).Tarr = {Tarr2{:,k}};
                EP(m).tstamp = Tarr2{4,k};
                EP(m).qf = qf;
                EP(m).dir = upd(2);

                AP(m) = an_swp(Vb2,Iarr2(:,k),cspice_str2et(Tarr2{1,k}),mode(2),EP(m).lum);


                if k>1
                    Vguess = DP(m-1).Vph_knee;
                else
                    Vguess = 0; %use last calculation as a first guess
                end

                [DP(m),DP_asm(m)] = an_LP_Sweep_v2(Vb2,Iarr2(:,k),Vguess,EP(m).lum);

                %DP(m) = an_LP_Sweep(Vb2,Iarr2(:,k),Vguess,EP(m).lum);
                %DP_asm(m) = an_LP_Sweep_with_assmpt(Vb2,Iarr2(:,k),assmpt,EP(m).lum);

                Te_guess = 5;%eV
                %EP(m).ne_5eV = abs(1e-6*DP(m).e_intersect(1)/(IN.probe_A*-CO.e*sqrt(CO.e*Te_guess/(2*pi*CO.me))));
                %EP(m).asm_ne_5eV = abs(1e-6*DP_asm(m).e_intersect(1)/(IN.probe_A*-CO.e*sqrt(CO.e*Te_guess/(2*pi*CO.me))));
                EP(m).ne_5eV        = max((1e-6*sqrt(2*pi*CO.me*Te_guess) * DP(m).e_slope(1) / (IN.probe_A*CO.e.^1.5)),0); %max out of expression and 0 -> if >0, n=0;
                EP(m).asm_ne_5eV    = max((1e-6*sqrt(2*pi*CO.me*Te_guess) * DP_asm(m).e_slope(1) / (IN.probe_A*CO.e.^1.5)),0);  %max out of expression and 0 -> if >0, ni=0;
                EP(m).asm_Vsc_ni_ne = nansum((DP_asm(k).ion_Vb_intersect(1)-(sqrt(DP_asm(k).ion_intersect(1))*DP_asm(k).ne(1)/DP_asm(k).ni_2comp(1)).^2)/DP_asm(k).ion_slope(1));
                EP(m).Vsc_ni_ne     = nansum((DP(k).ion_Vb_intersect(1)    -(sqrt(DP(k).ion_intersect(1))    *DP(k).ne(1)    /DP(k).ni_2comp(1)).^2)    /DP(k).ion_slope(1));

            end%for
        end%if split

        
  %% some extra information for photoemission statistics
        V_query=-17;%V
        [checkthis,ind1] = sort(abs(Vb-V_query)); % find and sort values closest to -17.0V
        epsilon=1;
        %ind1=find( abs(temp2.bias_potentials+17.0) < epsilon) ; %Find potential near -17, within 1.0V
        if checkthis(1) < epsilon %max 1V away from  17
            
            for x =1:len %had to resort to loops, unfortunately.
                
            EP(x).curr=Iarr(ind1(1),x);%save absolute current
            EP(x).B=Vb(ind1(1));       %save potential value
            end
            
        else
                     
            for x =1:len               
                EP(x).curr=nan;
                EP(x).B=nan;
            end
        end
        
        if (split~=0)    % If every sweep/pair is really two sweeps...
            
            %now the same, but with Vb2 & Iarr2...
            [checkthis,ind1] = sort(abs(Vb2-V_query)); % find and sort values closest to -17.0V
            %indz=len+(1:+length(Iarr2(1,:)));
            if checkthis(1) < epsilon %max 1V away from  Vquery
                
                 for x =1:length(Iarr2(1,:))          
                EP(len+x).curr=Iarr2(ind1(1),x); %save absolute current
                EP(len+x).B=Vb2(ind1(1));        %save potential value
                 end
                 
            else
                
                for x =1:length(Iarr2(1,:))
                    EP(len+x).curr=nan; %save absolute current
                    EP(len+x).B=nan;        %save potential value
                end

            end
        end
        %%

        [junk,ind] = sort({EP.tstamp});
        klen=length(ind);

        AP=AP(ind);
        DP=DP(ind);
        DP_asm=DP_asm(ind);
        EP=EP(ind);
        wfile= rfile;
        wfile(end-6)='A';
        
%         if split
%             Tarrcat = horzcat(Tarr,Tarr);
%             [junk testind3]= sort(Tarrcat(4,:));
%             Tarrcat2=Tarrcat(:,ind);
%             Tarrcat=Tarrcat(:,testind3); % any differences between these two?
%             
%             
%         else
%             
%             Tarrcat=Tarr;
%         end
%         
        
        
        
        
        
        
         
        %%%%%--------------------------------%%%%%%
        %Parameterfiles  Struct
        if str2double(probe)==1
            
            info_struct=[];
            info_struct.file      =wfile;
            info_struct.shortname =strrep(wfile,rfolder,'');
            info_struct.derivedpath=rfolder(1:end-13);
            info_struct.rows      =klen;
            %der_struct.an_ind_id(i) =an_ind(i);
            info_struct.timing=timing;
            info_struct.macroId=str2double(diagmacro);
            info_struct.nroffiles=length(an_ind);
            % XXP_struct.Tarr{i}=Tarrcat;
            %  XXP_struct.Tarr=XXP_struct.Tarr;
            
            for j=1:klen
                XXP_struct.Tarr(j,1:4)=EP(j).Tarr;
                XXP_struct.t0(j,1) = cspice_str2et(XXP_struct.Tarr(j,1));%now
                %XXP_struct.t0 = irf_time(XXP_struct.Tarr{j,1},'utc>tt');
                XXP_struct.ion_slope(j,1:2)=DP(j).ion_slope;
                XXP_struct.curr(j,1)=EP(j).curr;
                XXP_struct.B(j,1)=EP(j).B;
                XXP_struct.ion_slope(j,1:2)=DP(j).ion_slope;
                XXP_struct.Vph_knee(j,1:2)=DP(j).Vph_knee;
                XXP_struct.Vz(j,1:2)=AP(j).Vz;
                XXP_struct.Vsi(j,1:2)=DP(j).Vsi;
                XXP_struct.Te_exp_belowVknee(j,1:2)=DP_asm(j).Te_exp_belowVknee;
                XXP_struct.Iph0(j,1:2)=DP(j).Iph0;
                XXP_struct.Vph_knee(j,1:2)=DP(j).Vph_knee;
                XXP_struct.qf(j,1)=EP(j).qf;
               
                
            end
           % nan_ind=isnan(XXP_struct.ionslope); XXP_struct.ionslope(nan_ind)=SATURATION_CONSTANT;
            nan_ind=isnan(XXP_struct.Vph_knee); XXP_struct.Vph_knee(nan_ind)=SATURATION_CONSTANT;
            nan_ind=isnan(XXP_struct.Vz);       XXP_struct.Vz(nan_ind)=SATURATION_CONSTANT;
            nan_ind=isnan(XXP_struct.Vsi);      XXP_struct.Vsi(nan_ind)=SATURATION_CONSTANT;
            nan_ind=isnan(XXP_struct.Te_exp_belowVknee);XXP_struct.Te_exp_belowVknee(nan_ind)=SATURATION_CONSTANT;          
           % nan_ind=isnan(XXP_struct.Iph0);     XXP_struct.Iph0(nan_ind)=SATURATION_CONSTANT;          
            nan_ind=isnan(XXP_struct.Vph_knee); XXP_struct.Vph_knee(nan_ind)=SATURATION_CONSTANT;
            
            
            %some variables exist in both structs at the moment.
%             XXP_struct.ion_slope=XXP_struct.ion_slope; 
%             XXP_struct.Vz=XXP_struct.Vz;
%             XXP_struct.Vsi=XXP_struct.Vsi;
            
            if i ==1
                XXP.data=XXP_struct;
                XXP.info=info_struct;
                XXP(2).info=info_struct; %boom, I have now made an array of structs in this silly fashion, such that I can populate PXP(i), in future.      
            else
                XXP(i).data=XXP_struct;
                XXP(i).info=info_struct;
             
            end
            
            
        end%probenr
        

           %EP(k).Tarr{1,1}, EP(k).Tarr{1,2}, EP(k).Tarr{1,3}, EP(k).Tarr{1,4}

%     
%  PXPTABfile(var_ind,EP)
% %this file needs all lapa1s.t1, DP.ion_slope in archive
% %,also. This file needs the potential and current value closest to e.g.
% %-17Vb for each sweep.        
%    
% 
% UXPfile(var_ind)
% %this file needs all Vph_knee*, and all Vfloat measurements in archive.
% %or AP.Vz, V_sc from ion slope
% %or DP.Vsi 
% 
% 
% end
% 
% AXPfile(DP,MIP,macroNo)
%this file needs DP & all MIP measurements.
  
            
            
        
        
        
        
        
        
        
        
        
% 
%         an_tabindex{end+1,1} = wfile;                   % start new line of an_tabindex, and record file name
%         an_tabindex{end,2} = strrep(wfile,rfolder,'');  % shortfilename
%         an_tabindex{end,3} = tabindex{an_ind(i),3};     % first calib data file index
%         %an_tabindex{end,3} = an_ind(1);                % First calib data file index of first derived file in this set
%         an_tabindex{end,4} = klen; % Number of rows
%         an_tabindex{end,5} = 112;  % Number of columns
%         an_tabindex{end,6} = an_ind(i);
%         an_tabindex{end,7} = 'sweep'; % Type
%         an_tabindex{end,8} = timing;
%         an_tabindex{end,9} = row_bytes;

%          if str2double(probe)==1
%             dfile= wfile;
%             dfile(end-6:end-4)='A1P';
%             awID= fopen(dfile,'w');
%             if i==1
%                  der_struct=[];
%                  der_struct.file={};                 
%                  der_struct.shortname={};
%                  der_struct.firstind=[];
%                  der_struct.rows=[];
%                  der_struct.cols=[];
%                  der_struct.an_ind_id=[];
%                  der_struct.timing={};
%                  der_struct.bytes=[];
%                  der_struct.macro={};
%             end
%             
            
            
            
         %   nanind=isnan(DP(:).Vph_knee(1));
%             
%             
%          
%          for k=1:klen
%              
%              dstr1  = sprintf('%s, %s, %16s, %16s, %04i,', EP(k).Tarr{1,1}, EP(k).Tarr{1,2}, EP(k).Tarr{1,3}, EP(k).Tarr{1,4}, EP(k).qf);
%              dstr2 = sprintf(' %14.7e, %14.7e', DP(k).Vph_knee(1),DP(k).Te_exp_belowVknee(1));
%              if isnan(DP(k).Vph_knee(1))                 
%                  dstrtot=strcat(dstr1,dstr2);
%                  dstrtot=strrep(dstrtot,'  0.0000000e+00','       -1.0e+03'); % ugly fix, but this fixes the ni = 0 problem in the least code heavy way & probably most efficient way.
%                  dstrtot=strrep(dstrtot,'     NaN','-1.0e+03');                
%              end
%              drow_bytes = fprintf(awID,'%s\r\n',dstrtot);
% 
%          end
%             fclose(awID);
%                                 
%             %der_struct=[];
%             der_struct.file{i}      = dfile;
%             der_struct.shortname{i} =strrep(dfile,rfolder,'');
%             der_struct.firstind(i)  =tabindex{an_ind(i),3};
%             der_struct.rows(i)      =klen;
%             der_struct.cols(i)      =7;
%             der_struct.an_ind_id(i) =an_ind(i);
%             der_struct.timing(i,1:4)=timing;
%             der_struct.bytes=drow_bytes;
%                       
%         end

        
        
        
        %clear output structs before looping again
        clear AP DP EP
        
    end  % for every sweep file

    cspice_kclear;  %unload ALL kernels when exiting function
    %
catch err

    fprintf(1,'Error at loop step %i, file %s',i,tabindex{an_ind(i),1});
    if ~isempty(k)
        fprintf(1,'\n Error at loop step k=%i,',k);
    end
    err.identifier
    err.message
    len = length(err.stack);
    if (~isempty(len))
        for i=1:len
            fprintf(1,'%s, %i; ',err.stack(i).name,err.stack(i).line);
        end
    end
    cspice_kclear;  %unload ALL kernels when exiting function
    %cspice_unload(kernelFile);  %unload kernels when exiting function

end


end    % function




