%an_swp2
%analyses sweeps, utilising modded version of Anders an_swp code, and other
%methods
function []= an_swp2(an_ind,tabindex,targetfullname)

global an_tabindex;
global target;

dynampath = strrep(mfilename('fullpath'),'/an_swp2','');
kernelFile = strcat(dynampath,'/metakernel_rosetta.txt');
paths();

cspice_furnsh(kernelFile);

try
    
    for i=1:length(an_ind)
        
        fout=cell(1,7);
        split = 0;
        
        rfile =tabindex{an_ind(i),1};
        rfolder = strrep(tabindex{an_ind(i),1},tabindex{an_ind(i),2},'');
        mode=rfile(end-6:end-4);
        diagmacro=rfile(end-10:end-8);
        
        
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
            split = 1;
            
            
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
        
        
        %  phot ==
        
        vP = 0;
        vPStd = 0;
        
        for k=1:len
            %  a= cspice_str2et(timing{1,k});
            m = k;
            
            %% quality factor check
            qf= Qfarr(k);
            
            if (abs(SAA(1,2*k-1)-SAA(1,2*k)) >0.01) %rotation of more than 0.01 degrees
                qf = qf+20; %rotation
            end
            
            
            
            fout{m,1} = an_swp(Vb,Iarr(:,k),cspice_str2et(Tarr{1,k}),mode(2),illuminati(k));
            fout{m,2} = mean(SAA(1,2*k-1:2*k));
            fout{m,3} = mean(illuminati(1,2*k-1:2*k));
            if fout{m,3}==1
                %estimates plasma potential from second derivative gaussian
                %fit, using qualified guesses of the plasma potential from
                %an_swp (,fout{l,1}(15)=vs = Vsc as intersection of ion and photoemission
                %current)
                [vP,vPStd] = Vplasma(Vb,Iarr(:,k),fout{m,1}(15),3);
                
                fout{m,4}(1) = vP; %skipping intermediate step impossible on old matlab...
                fout{m,4}(2) = vPStd;
                
                
                if max(Vb)<(vP+vPStd) || min(Vb)>(vP-vPStd) %
                    qf=qf+1; %poor fit for analysis method
                end
                
                
            else
                fout{m,4}(1) = NaN;
                fout{m,4}(2) = NaN;
                
            end%if
          
            fout{m,5}={Tarr{:,k}};
            fout{m,6}= Tarr{3,k};
            fout{m,7}=qf;
        end%for
        
        
        
        if split
            
            
            for k=1:length(Iarr2(1,:))
                m=k+len;          %add to end of output array (fout{})
                %note Vb =! Vb2, Iarr =! Iarr2, etc.
                %% quality factor check
                qf= Qfarr(k);
                
                if (abs(SAA(1,2*k-1)-SAA(1,2*k)) >0.01) %rotation of more than 0.01 degrees
                    qf = qf+20; %rotation
                end
                
                fout{m,1} =an_swp(Vb2,Iarr2(:,k),cspice_str2et(Tarr{1,k}),mode(2),illuminati);
                
                fout{m,2} = mean(SAA(1,2*k-1:2*k)); %every pair...
                fout{m,3} = mean(illuminati(1,2*k-1:2*k));
                if fout{m,3}==1
                    %      [fout{l+len,4}{1},fout{l+len,4}{2}] = Vplasma(Vb2,Iarr2(:,k));
                    
                    %estimates plasma potential from second derivative gaussian
                    %fit, using qualified guesses of the plasma potential from
                    %an_swp (,fout{l,1}(15)=vs = Vsc as intersection of ion and photoemission
                    %current)
                    [vP,vPStd] = Vplasma(Vb2,Iarr2(:,k),fout{m,1}(15),4);
                    %have to do this in three steps since old matlab version on server
                    fout{m,4}(1) = vP;
                    fout{m,4}(2) = vPStd;
                    
                    if max(Vb)<(vP+vPStd) || min(Vb)>(vP-vPStd) %
                        qf=qf+1; %poor fit for analysis method
                    end
                    
                    
                else
                    fout{m,4}(1) = NaN;
                    fout{m,4}(2) = NaN;
                end%if
                
                fout{m,5}={Tarr{:,k}};
                fout{m,6}= Tarr{4,k}; %%obs, not Tarr{3,k};
                
                
                
                fout{m,7}=qf;
                
                
            end%for
        end%if split
        
        fout = sortrows(fout,6);
        %  [foutarr,~] = sortrows{foutarr,6,'ascend'};
        
        
        wfile= rfile;
        wfile(end-6)='A';
        awID= fopen(wfile,'w');
        r2 = 0;
        
        
        % fpformat = '%s, %s, %03i, %07.4f, %03.2f, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e  %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e\n';
        for k=1:length(fout(:,1))
            %params = [ts vb(lastneg) vb(firstpos) vx poli(1) poli(2) pole(1) pole(2) p vbinf diinf d2iinf Tph If0 vs];
            %time0,time0,quality,mean(SAA),mean(Illuminati)
            
            
            
            %           '1,  2,   3  ,   4   ,   5   ;   6   ,   7   ,    8  ,   9  ;   10  ,   11  ,   12  ,   13  ;   14  ,   15  ,   16  ,   18  ;   19  ,   20  ,   21  \n
            
            %f_format = '%s, %s, %03i, %07.4f, %03.2f, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e\n';
            %1:5
            %time0,time0,qualityfactor,mean(SAA),mean(Illuminati)
            str1=sprintf('%s, %s, %03i, %07.3f, %03.2f,',fout{k,5}{1,1},fout{k,5}{1,2},fout{k,7},fout{k,2},fout{k,3});
            %6:9
            %,vs,vx,Vsc,VscSigma
            str2=sprintf(' %14.7e, %14.7e, %14.7e, %14.7e,',fout{k,1}(15),fout{k,1}(4),fout{k,4}(1),fout{k,4}(2));
            %10:13
            %,Tph,If0,vb(lastneg) vb(firstpos),
            str3=sprintf(' %14.7e, %14.7e, %14.7e, %14.7e,', fout{k,1}(13),fout{k,1}(14),fout{k,1}(2),fout{k,1}(3));
            %14:17
            %poli(1),poli(2),pole,pole,
            str4=sprintf(' %14.7e, %14.7e, %14.7e, %14.7e,',fout{k,1}(5),fout{k,1}(6),fout{k,1}(7),fout{k,1}(8));
            %18:20
            %  vbinf,diinf,d2iinf
            str5=sprintf(' %14.7e, %14.7e, %14.7e',fout{k,1}(10),fout{k,1}(11),fout{k,1}(12));
            strtot= strcat(str1,str2,str3,str4,str5);
            str6=strrep(strtot,'NaN','   ');
            
            %If you need to change NaN to something (e.g. N/A, as accepted by Rosetta Archiving Guidelines) change it here!
            
            
            row_bytes =fprintf(awID,'%s\n',str6);
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
        an_tabindex{end,4} = length(fout(:,1)); %number of rows
        an_tabindex{end,5} = 19; %number of columns
        an_tabindex{end,6} = an_ind(i);
        an_tabindex{end,7} = 'sweep'; %type
        an_tabindex{end,8} = timing;
        an_tabindex{end,9} = row_bytes;
        
        
    end
    
    cspice_unload(kernelFile);  %unload kernels when exiting function
    
catch err
    
    fprintf(1,'Error at loop step %i, file %s',i,tabindex{an_ind(i),1});
    
    err
    err.stack.name
    err.stack.line
    cspice_unload(kernelFile);
    
    
    
end


end
