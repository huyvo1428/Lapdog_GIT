%an_swp2


function []= an_swp2(an_ind,tabindex,targetfullname)

global an_tabindex;

%antemp ='';


%fprintf(awID,'%s,%16.6f,,,,\n',UTC_time,(0.5*intval+tday0+(j-1)*intval));
%outputarr =
%


for i=1:length(an_ind)
    
    foutarr=cell(1,5);
    split = 0;
    
    rfile =tabindex{an_ind(i),1};
    mode=rfile(end-6:end-4);
    arID = fopen(tabindex{an_ind(i),1},'r');

    scantemp = textscan(arID,'%s','delimiter',',','CollectOutput', true);
    
    % scantemp=textscan(arID,'%*s%*s%*f%*f%f','delimiter',',','CollectOutput', true);
    %   scantemp3=textscan(arID,'%f','delimiter','\n');
    
    % scantemp=textscan(arID,'%s%f%f%f%d','delimiter',',');
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
    Vb=scantemp2{1,1};
    
    timing= A(1:4,1:end);
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
    %    orbit('Rosetta',{'2007-09-07';'2007-09-08'},'EARTH','ECLIPJ2000')
    
    if strcmp(targetfullname,'SOLAR WIND')
           [~,~,SAA]=orbit('Rosetta',timing(1:2,:),'SUN','ECLIPJ2000');
    else
    
   
    [~,~,SAA]=orbit('Rosetta',timing(1:2,:),targetfullname,'ECLIPJ2000');
    end
    
    
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
    
    
    
    for k=1:len
        %  a= cspice_str2et(timing{1,k});
        
        
        foutarr{k,1} = an_swp(Vb,Iarr(:,k),cspice_str2et(timing{1,k}),mode(2),illuminati);
        foutarr{k,2} =mean(SAA(1,2*k-1:2*k));
        
        foutarr{k,3}=mean(illuminati(1,2*k-1:2*k));
        if foutarr{k,3}==1
            
            [foutarr{k,4}{1},foutarr{k,4}{2}] = Vplasma(Vb,Iarr(:,k));
        else
            foutarr{k,4}{1} = 'NaN';
            foutarr{k,4}{2} = 'NaN';
            
        end%if
        
        foutarr{k,5}={timing{:,k}};
        foutarr{k,6}= timing{3,k};
        
    end%for
    
    
    
    if split
        
        
        for k=1:length(Iarr2(1,:))
            
            foutarr{k+len,1} =an_swp(Vb2,Iarr2(:,k),cspice_str2et(timing{1,k}),mode(2),illuminati);
            foutarr{k+len,2} =mean(SAA(1,k:k+1));
            foutarr{k+len,3}=mean(illuminati(1,k:k+1));
            if foutarr{k+len,3}==1
                [foutarr{k+len,4}{1},foutarr{k+len,4}{2}] = Vplasma(Vb2,Iarr2(:,k));
            else
                foutarr{k+len,4}{1} = 'NaN';
                foutarr{k+len,4}{2} = 'NaN';
            end%if
            
            foutarr{k+len,5}={timing{:,k}};
            foutarr{k+len,6}= timing{4,k};
            
        end%for
    end%if split
    
    foutarr = sortrows(foutarr,6);
    %  [foutarr,~] = sortrows{foutarr,6,'ascend'};
    
    
    wfile= rfile;
    wfile(end-6)='A';
    awID= fopen(wfile,'w');
    
    
    for k=1:length(foutarr(:,1))
        %params = [ts vb(lastneg) vb(firstpos) vx poli(1) poli(2) pole(1) pole(2) p vbinf diinf d2iinf Tph If0 vs];
        %time0,time0,quality,mean(SAA),mean(Illuminati)
        
        
        
        %time0,time0,quality,mean(SAA),mean(Illuminati)
        fprintf(awID,'%s, %s,%03i,%07.4f, %03.2f,',foutarr{k,5}{1,1},foutarr{k,5}{1,2},0,foutarr{k,2},foutarr{k,3});
        %,vs,vx,Vsc,VscSigma
        fprintf(awID,'%14.7e, %14.7e, %14.7e, %14.7e,',foutarr{k,1}(15),foutarr{k,1}(4),foutarr{k,4}{1},foutarr{k,4}{2});
        %,Tph,If0,vb,vb,
        fprintf(awID,'%14.7e, %14.7e,%14.7e, %14.7e,', foutarr{k,1}(13),foutarr{k,1}(14),foutarr{k,1}(2),foutarr{k,1}(3));
        %poli,poli,pole,pole,
        fprintf(awID,'%14.7e, %14.7e,%14.7e, %14.7e,',foutarr{k,1}(5),foutarr{k,1}(6),foutarr{k,1}(7),foutarr{k,1}(8));
        %  vbinf,diinf,d2iinf
        fprintf(awID,'%14.7e, %14.7e,%14.7e,\n',foutarr{k,1}(10),foutarr{k,1}(11),foutarr{k,1}(12));
        %16.6f, %16.6f, %16.6f, %16.6f, %16.6f, %16.6f, %16.6f, %16.6f, %16.6f, %16.6f, %16.6f, %16.6f', ...
        
        %
        %         fprintf(awID,'%s, %s,%03i,%07.4f, %03.2f, %16.6f, %16.6f, %16.6f, %16.6f, %16.6f, %16.6f, %16.6f, %16.6f, %16.6f, %16.6f, %16.6f, %16.6f, %16.6f, %16.6f, %16.6f', ...
        %             foutarr{k,5}{1,1},foutarr{k,5}{2,1},0,foutarr{k,2},foutarr{k,3},foutarr{k,1}(15),foutarr{k,1}(4),foutarr{k,4}(1),foutarr{k,4}(2), ...
        %             foutarr{k,1}(13),foutarr{k,1}(14),foutarr{k,1}(2),foutarr{k,1}(3),foutarr{k,1}(5),foutarr{k,1}(6),foutarr{k,1}(7),foutarr{k,1}(8) ...
        %             ,foutarr{k,1}(10),foutarr{k,1}(11),foutarr{k,1}(12));
        
    end
    fclose(awID);
    
    
    
    
end
end
