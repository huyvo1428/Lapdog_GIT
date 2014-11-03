%an_swp2
%analyses sweeps, utilising modded version of Anders an_swp code, and other
%methods
function []= an_sweepmain(an_ind,tabindex,targetfullname)

global an_tabindex;
global target;
global diag_info
dynampath = strrep(mfilename('fullpath'),'/an_sweepmain','');
kernelFile = strcat(dynampath,'/metakernel_rosetta.txt');
paths();

cspice_furnsh(kernelFile);




try
    
    for i=1:length(an_ind)
        
        
        
        
        
        %fout=cell(1,7);
        split = 0;
        
        rfile =tabindex{an_ind(i),1};
        rfolder = strrep(tabindex{an_ind(i),1},tabindex{an_ind(i),2},'');
        mode=rfile(end-6:end-4);
        diagmacro=rfile(end-10:end-8);
        probe = rfile(end-5);
        diag_info{1} = strcat(diagmacro,'P',probe);

%        diag_info{1} = strcat('P',probe,'M',diagmacro);
        diag_info{2} = rfile; %let's also remember the full name
        arID = fopen(tabindex{an_ind(i),1},'r');
        
        if arID < 0
            fprintf(1,'Error, cannot open file %s', tabindex{an_ind(i),1});
            break
        end % if I/O error
        
        scantemp = textscan(arID,'%s','delimiter',',','CollectOutput', true);
        
        fclose(arID);
        
        rfile(end-6)='B';
        arID = fopen(rfile,'r');
        scantemp2=textscan(arID,'%*f%f','delimiter',',');
        
        
        % scantemp=textscan(arID,'%s%f%f%f%d','delimiter',',');
        fclose(arID);
        
        steps=    length(scantemp2{1,1})+5; %current + 4 timestamps + 1 QF
        
        size=    numel(scantemp{1,1});
        
        if mod(size,steps) ~=0
            fprintf(1,'error, bad sweepfile at \n %s \n, aborting %s mode analysis\n',rfile,mode);
            return
        end
        
        
        A= reshape(scantemp{1,1},steps,size/steps);
        Iarr= str2double(A(6:end,1:end));
        timing={A{1,1},A{2,end},A{3,1},A{4,end}};
        Qfarr =str2double(A(5,:));
        
        Vb=scantemp2{1,1};
        
        Tarr= A(1:4,1:end);
        % clear scantemp  A
        
        %    foutarr = cell(size/steps,2);
        %   Iuni = zeros(size/steps,1);
        
        %     [Vb, ~, ic] = unique(Vb); %%sort Vb, and remove duplicates (e.g. sweeps
        %     %from -30 to +30 to -30 creates duplicate potential values)
        %     %also remember the sorting indices, and use them to average multiple
        %     %current measurements on the same potential step (second time again)
        %
        %
        %     for k=1:size/steps
        %
        %         Iuni(k) = accumarray(ic,Iarr(:,k),[],@mean);
        %         foutarr(k,1:2)=Vplasma(Vb,Iarr(:,k));
        %
        %
        %
        %     end
        %
        
        %special case where V increases e.g. +15to -15 to +15, or -15 to +15 to -15V
        potdiff=diff(Vb);
        if potdiff(1) > 0 && Vb(end)~=max(Vb) % potbias looks like a V
            
            
            %split data
            mind=find(Vb==max(Vb));
            Vb2=Vb(mind:end);
            Iarr2=Iarr(mind:end,:);
            
            Vb=Vb(1:mind);
            Iarr= Iarr(1:mind,:);
            
            split = 1;
            
            
            
        elseif potdiff(1) <0 && Vb(end)~=min(Vb)
            %%potbias looks like upside-down V
            
            %split data
            mind=find(Vb==min(Vb));
            Vb2=Vb(mind:end);
            Iarr2=Iarr(mind:end,:);
            
            Vb=Vb(1:mind);
            Iarr= Iarr(1:mind,:);
            split = -1;
            
            
        end
        
        %'preloaded' is a dummy entry, just so orbit realises spice kernels
        %are already loaded
        [junk,junk,SAA]=orbit('Rosetta',Tarr(1:2,:),target,'ECLIPJ2000','preloaded');
        clear junk
        
        if strcmp(mode(2),'1');
            %current (Elias) SAA = z axis, Anders = x axis.
            % *Anders values* (converted to the present solar aspect angle definition
            % by ADDING 90 degrees) :
            Phi11 = 131;
            Phi12 = 181;
            
            illuminati = ((SAA < Phi11) | (SAA > Phi12));
            
            
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
        
        
        
        len = length(Iarr(1,:));
        %  cspice_str2et(
        
        
        %% initialise output struct
        AP(len).ts       = [];
        AP(len).vx       = [];
        AP(len).Tph      = [];
        AP(len).If0      = [];
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
        

        
        EP(len).tstamp   = [];
        EP(len).SAA      = [];
        EP(len).qf       = [];
        EP(len).Tarr     = {};
        EP(len).lum      = [];
        EP(len).split    = [];
        
        DP(len).If0      = [];
        DP(len).Tph      = [];
        DP(len).Vintersect = [];
        DP(len).Te       = [];
        DP(len).ne       = [];
        DP(len).Vsc      = [];
        DP(len).Vplasma  = [];
        DP(len).Vsigma   = [];
        DP(len).ia       = [];
        DP(len).ib       = [];
        DP(len).ea       = [];
        DP(len).eb       = [];
        
        DP(len).Ts       = [];
        DP(len).ns       = [];
        DP(len).sa       = [];
        DP(len).sb       = [];
       
        DP(len).Quality  = [];
        %%
        
        
        % analyse!
        for k=1:len
            

            
            %  a= cspice_str2et(timing{1,k});
            m = k;
            
            %% quality factor check
            qf= Qfarr(k);
            
            if (abs(SAA(1,2*k-1)-SAA(1,2*k)) >0.01) %rotation of more than 0.01 degrees  %arbitrary chosen value... seems decent
                qf = qf+20; %rotation
            end
            
            EP(k).SAA = mean(SAA(1,2*k-1:2*k));
            EP(k).lum = mean(illuminati(1,2*k-1:2*k));
            
            EP(k).split = 0;
            EP(k).Tarr = {Tarr{:,k}};
            
            %       fout{m,5}={Tarr{:,k}};
            EP(k).tstamp = Tarr{3,k};
            EP(k).qf = qf;
            
            
            %Anders LP sweep analysis
            AP(k)=  an_swp(Vb,Iarr(:,k),cspice_str2et(Tarr{1,k}),mode(2),EP(k).lum);
            %AP = [AP;temp];
            
  %          fout{m,1} = an_swp(Vb,Iarr(:,k),cspice_str2et(Tarr{1,k}),mode(2),illuminati(k));
 %           fout{m,2} = mean(SAA(1,2*k-1:2*k));


%            fout{m,3} = mean(illuminati(1,2*k-1:2*k));
            
%           %new LP sweep analysis

%            test= an_LP_Sweep(Vb, Iarr(:,k),AP(k).vs,EP(k).lum);
                        
            if k>1
                Vguess=DP(k-1).Vplasma;
            else
                Vguess=AP(k).vs;
            end


            DP(k)= an_LP_Sweep(Vb, Iarr(:,k),Vguess,EP(k).lum);
            
            
           % DP = [DP;temp];
%             
            
%             if AP(k).lum==1
%                 %estimates plasma potential from second derivative gaussian
%                 %fit, using qualified guesses of the plasma potential from
%                 %an_swp (,fout{l,1}(15)=vs = Vsc as intersection of ion and photoemission
%                 %current)
%                 [vP,vPStd] = Vplasma(Vb,Iarr(:,k),AP(k).vs,3);
%                 
%                 fout{m,4}(1) = vP; %skipping the intermediate step impossible on old matlab version on squid.
%                 fout{m,4}(2) = vPStd;
%                 
%                 
%                 if max(Vb)<(vP+vPStd) || min(Vb)>(vP-vPStd) %
%                     qf=qf+1; %poor fit for analysis method
%                 end
%                 
%                 
%             else
%                 fout{m,4}(1) = NaN;
%                 fout{m,4}(2) = NaN;
%                 
%             end%if

%            fout{m,7}=qf;
        end%for
        
        
        
        if (split~=0)
            
            
            for k=1:length(Iarr2(1,:))
                m=k+len;          %add to end of output array (fout{})
                %note Vb =! Vb2, Iarr =! Iarr2, etc.
                %% quality factor check
                qf= Qfarr(k);
                
                if (abs(SAA(1,2*k-1)-SAA(1,2*k)) >0.01) %rotation of more than 0.01 degrees
                    qf = qf+20; %rotation
                end
                
                %               fout{m,1} =an_swp(Vb2,Iarr2(:,k),cspice_str2et(Tarr{1,k}),mode(2),illuminati);
                %                fout{m,2} = mean(SAA(1,2*k-1:2*k)); %every pair...
                %                fout{m,3} = mean(illuminati(1,2*k-1:2*k));
                
                EP(m).SAA = mean(SAA(1,2*k-1:2*k));
                EP(m).lum = mean(illuminati(1,2*k-1:2*k));
                EP(m).Tarr = {Tarr{:,k}};
                EP(m).tstamp = Tarr{4,k};
                EP(m).qf = qf;
                EP(m).split= split; % 1 for V form, -1 for upsidedownV

                AP(m)     =  an_swp(Vb,Iarr(:,k),cspice_str2et(Tarr{1,k}),mode(2),EP(m).lum);
                %          fout{m,1} = an_swp(Vb,Iarr(:,k),cspice_str2et(Tarr{1,k}),mode(2),illuminati(k));
                %                fout{m,2} = mean(SAA(1,2*k-1:2*k));

                
                if k>1
                    Vguess=DP(m-1).Vplasma;
                else
                    Vguess=AP(m).vs; %use last calculation as a first guess
                end

                DP(m) = an_LP_Sweep(Vb2,Iarr2(:,k),Vguess,EP(m).lum);

                
                %
%                 if fout{m,3}==1
%                     %      [fout{l+len,4}{1},fout{l+len,4}{2}] = Vplasma(Vb2,Iarr2(:,k));
%                     
%                     %estimates plasma potential from second derivative gaussian
%                     %fit, using qualified guesses of the plasma potential from
%                     %an_swp (,fout{l,1}(15)=vs = Vsc as intersection of ion and photoemission
%                     %current)
%                     [vP,vPStd] = Vplasma(Vb2,Iarr2(:,k),fout{m,1}(15),4);
%                     %have to do this in three steps since old matlab version on server
%                     fout{m,4}(1) = vP;
%                     fout{m,4}(2) = vPStd;
%                     
%                     if max(Vb)<(vP+vPStd) || min(Vb)>(vP-vPStd) %
%                         qf=qf+1; %poor fit for analysis method
%                     end
%                     
%                     
%                 else
%                     fout{m,4}(1) = NaN;
%                     fout{m,4}(2) = NaN;
%                 end%if
%                 
% %                fout{m,5}={Tarr{:,k}};
%                 fout{m,6}= Tarr{4,k}; %%obs, not Tarr{3,k};
%                 
%                 
%                 
%                 fout{m,7}=qf;
                
                
            end%for
        end%if split
        
    %    fout = sortrows(fout,6);
        %  [foutarr,~] = sortrows{foutarr,6,'ascend'};

        
        [junk,ind] = sort({EP.tstamp});
        
  %      [junk,ind] = sort({EP.tstamp});
        klen=length(ind);

        AP=AP(ind);
        DP=DP(ind);
        EP=EP(ind);
        wfile= rfile;
        wfile(end-6)='A';
        awID= fopen(wfile,'w');
        r2 = 0;
        
%         fprintf(awID,strcat('EP(k).Tarr{1},EP(k).Tarr{2},EP(k).qf,EP(k).SAA,EP(k).lum',...
%             ',AP(k).vs,AP(k).vx,DP(k).Vsc,DP(k).Vsigma, AP(k).Tph,AP(k).If0,AP(k).lastneg,AP(k).firstpos',...
%             ',AP(k).poli1,AP(k).poli2,AP(k).pole1,AP(k).pole2',...
%             ',AP(k).vbinf,AP(k).diinf,AP(k).d2iinf',...
%             ',DP(k).Quality,DP(k).Tph,DP(k).Vintersect,DP(k).Vplasma,DP(k).Te',...
%             ',DP(k).ne,DP(k).ia,DP(k).ib,DP(k).ea,DP(k).eb',...
%             ',DP(k).Ts,DP(k).ns,DP(k).sa,DP(k).sb\n'));
        %        fprintf(awID,strcat('EP(k).Tarr{1},EP(k).Tarr{2},EP(k).qf,EP(k).SAA,EP(k).lum',...
%            ',AP(k).vs,AP(k).vx,DP(k).Vsc,DP(k).Vsigma, AP(k).Tph,AP(k).If0,AP(k).lastneg,AP(k).firstpos',...
%            ',AP(k).poli1,AP(k).poli2,AP(k).pole1,AP(k).pole2',...
%           ',AP(k).vbinf,AP(k).diinf,AP(k).d2iinf',...
%            ',DP(k).If0,DP(k).Tph,DP(k).Vintersect,DP(k).Vplasma,DP(k).Te',...
%           ',DP(k).ne,DP(k).ia,DP(k).ib,DP(k).ea,DP(k).eb',...
%            ',DP(k).Ts,DP(k).ns,DP(k).sa,DP(k).sb\n'));

% 
%         fprintf(awID,strcat('START_TIME(UTC),STOP_TIME(UTC),QualityFactor,SAA,illumination(1=sunlit)',...
%             ',old.V_intersect,old.vx,Vsc,Vsc_sigma,old.Tph,old.If0,lastneg,firstpos',...
%             ',old.ion_slope,old.ion_y_cross,old.plasma_e_slope,old.plasma_e_y_cross',...
%             ',old.vb_inflection,old.di_inflection,old.d2i_inflection',...
%             ',If0,Tph,V_intersect,V_plasma,Te',...
%             ',n_e,ioncurrent_slope,ioncurrent_y_intersect,plasmae_slope,plasmae_y_intersect',...
%             ',T_s(photoelectroncloud),n_s,photelectroncloud_slope,photelectroncloud_y_intersect.\n'));   




                %IF THIS HEADER IS REMOVED (WHICH IT SHOULD BE BEFORE ESA
                %DELIVERY) NOTIFY TONY ALLEN!
                fprintf(awID,strcat('START_TIME(UTC),STOP_TIME(UTC),Qualityfactor,SAA,Illumination(1=sunlit)',...
            ',old.Vintersect,old.vx,Vsc,Vsigma, old.Tph,old.If0,vb_lastnegcurrent,vb_firstposcurrent',...
            ',old.ion_slope,old.ion_yintersect,old.plasma_e_slope,old.plasmae_yintersect',...
            ',old.Vb_inflection,old.diinf,old.d2iinf',...
            ',If0,Tph,Vintersect,Vplasma,Te(plasma)',...
            ',ne(plasma),ion_slope,ion_y_intersect,plasma_e_slope,plasma_e_yintersect',...
            ',Ts(photoelectroncloud),ns(photoelectroncloud),s_slope,s_yintersect\n'));
        
        
        
        % fpformat = '%s, %s, %03i, %07.4f, %03.2f, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e  %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e\n';
        for k=1:klen
            %params = [ts vb(lastneg) vb(firstpos) vx poli(1) poli(2) pole(1) pole(2) p vbinf diinf d2iinf Tph If0 vs];
            %time0,time0,quality,mean(SAA),mean(Illuminati)
            
            
            
            %           '1,  2,   3  ,   4   ,   5   ;   6   ,   7   ,    8  ,   9  ;   10  ,   11  ,   12  ,   13  ;   14  ,   15  ,   16  ,   18  ;   19  ,   20  ,   21  \n
            
            %f_format = '%s, %s, %03i, %07.4f, %03.2f, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e\n';
            %1:5

            
                
            %time0,time0,qualityfactor,mean(SAA),mean(Illuminati)
            str1=sprintf('%s, %s, %03i, %07.3f, %03.2f,',EP(k).Tarr{1,1},EP(k).Tarr{1,2},EP(k).qf,EP(k).SAA,EP(k).lum);
            %time0,time0,qualityfactor,mean(SAA),mean(Illuminati)
 %           str1=sprintf('%s, %s, %03i, %07.3f, %03.2f,',fout{k,5}{1,1},fout{k,5}{1,2},fout{k,7},fout{k,2},fout{k,3});
            %6:9
            %,vs,vx,Vsc,VscSigma
            str2=sprintf(' %14.7e, %14.7e, %14.7e, %14.7e,',AP(k).vs,AP(k).vx,DP(k).Vsc,DP(k).Vsigma);
            %,vs,vx,Vsc,VscSigma
 %           str2=sprintf(' %14.7e, %14.7e, %14.7e, %14.7e,',fout{k,1}(15),fout{k,1}(4),fout{k,4}(1),fout{k,4}(2));
            %10:13
            %,Tph,If0,vb(lastneg) vb(firstpos),
            str3=sprintf(' %14.7e, %14.7e, %14.7e, %14.7e,', AP(k).Tph,AP(k).If0,AP(k).lastneg,AP(k).firstpos);
            %,Tph,If0,vb(lastneg) vb(firstpos),
%            str3=sprintf(' %14.7e, %14.7e, %14.7e, %14.7e,', fout{k,1}(13),fout{k,1}(14),fout{k,1}(2),fout{k,1}(3));
            %14:17
            %poli(1),poli(2),pole,pole,
            str4=sprintf(' %14.7e, %14.7e, %14.7e, %14.7e,',AP(k).poli1,AP(k).poli2,AP(k).pole1,AP(k).pole2);
            %poli(1),poli(2),pole,pole,
     %       str4=sprintf(' %14.7e, %14.7e, %14.7e, %14.7e,',fout{k,1}(5),fout{k,1}(6),fout{k,1}(7),fout{k,1}(8));
            %18:20
            %  vbinf,diinf,d2iinf
            str5=sprintf(' %14.7e, %14.7e, %14.7e,',AP(k).vbinf,AP(k).diinf,AP(k).d2iinf);
            %  vbinf,diinf,d2iinf
       %     str5=sprintf(' %14.7e, %14.7e, %14.7e',fout{k,1}(10),fout{k,1}(11),fout{k,1}(12));
       
       
            
            str6 = sprintf( '%03i, %14.7e, %14.7e, %14.7e, %14.7e,',DP(k).If0,DP(k).Tph,DP(k).Vintersect,DP(k).Vplasma,DP(k).Te);
            
            str7 = sprintf(' %14.7e, %14.7e, %14.7e, %14.7e, %14.7e,',DP(k).ne,DP(k).ia,DP(k).ib,DP(k).ea,DP(k).eb);
            
            str8 = sprintf( ' %14.7e, %14.7e, %14.7e, %14.7e',DP(k).Ts,DP(k).ns,DP(k).sa,DP(k).sb);

            
            strtot= strcat(str1,str2,str3,str4,str5,str6,str7,str8);
            strtot=strrep(strtot,'NaN','   ');
            
%                     DP(len).If0      = [];
%         DP(len).Tph      = [];
%         DP(len).Vintersect = [];
%         DP(len).Te       = [];
%         DP(len).ne       = [];
%         DP(len).Vsc      = [];
%         DP(len).Vsigma   = [];
%         DP(len).ia       = [];
%         DP(len).ib       = [];
%         DP(len).ea       = [];
%         DP(len).eb       = [];
%         DP(len).Quality  = [];
%             
%             
            
            %If you need to change NaN to something (e.g. N/A, as accepted by Rosetta Archiving Guidelines) change it here!
            
            
            row_bytes =fprintf(awID,'%s\n',strtot);
            %             if (row_bytes ~= r2 && r2~= 0)
            %                 s= strcat(str6,r3)
            %
            %                 'hello'
            %
            % %             end
            %             r2 = row_bytes;
            %             r3 =str6;
            %
            
            
            
        end
        fclose(awID);
        
        an_tabindex{end+1,1} = wfile;%start new line of an_tabindex, and record file name
        an_tabindex{end,2} = strrep(wfile,rfolder,''); %shortfilename
        an_tabindex{end,3} = tabindex{an_ind(i),3}; %first calib data file index
        %an_tabindex{end,3} = an_ind(1); %first calib data file index of first derived file in this set
        an_tabindex{end,4} = klen; %number of rows
        an_tabindex{end,5} = 19; %number of columns
        an_tabindex{end,6} = an_ind(i);
        an_tabindex{end,7} = 'sweep'; %type
        an_tabindex{end,8} = timing;
        an_tabindex{end,9} = row_bytes;
        
        %clear output structs before looping again
        clear AP DP EP
    end
    
    cspice_unload(kernelFile);  %unload kernels when exiting function
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
            fprintf(1,'%s, %i,',err.stack(i).name,err.stack(i).line);
        end
    end
    cspice_unload(kernelFile);
        
    
end


end
