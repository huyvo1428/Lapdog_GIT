function [] = createTABLBL(derivedpath,tabind,index,fileflag)
  
%dereivedpath =  filepath 
%tabind = data block indices for each measurement type, array
%index = index array from earlier creation - Ugly way to remember index
%inside function.
% fileflag = identifier for type of data


    
    %    FILE GENESIS
    %After Discussion 24/1 2014
    %%FILE CONVENTION: RPCLAP_YYMMDD_hhmmss_MMM_APC
    %%MMM = MacroID, A= Measured quantity (B/I/V)%% , P=Probe number
    %%(1/2/3), C = Mode (H/L/S)
    % B = probe bias voltage file
    % I = Current file, static Vb
    % V = potential
    %
    % H = High frequency data
    % L = Low frequency data
    % S = Voltage sweep data (bias voltage file or current file)
    % File should contain Time, spacecraft time, current, bias potential, Qualityfactor 
    % 2011-09-05T13:45:20.026075 
    %YYYY-MM-DDThh:mm:ss.ffffff % double[s],double[A],double [V],int
    
    filename = sprintf('%s/RPCLAP_%s_%s_%d_%s.TAB',derivedpath,datestr(index(tabind(1)).t0,'yyyymmdd'),datestr(index(tabind(1)).t0,'HHMMSS'),index(tabind(1)).macro,fileflag); %%
    
    len = length(tabind);
    for(i=1:len);
        tabID = fopen(index(tabind(i)).tabfile);
        %{tstr sct ip vb} = textscan(tabID,'%s%f%f%f','delimiter',',');
        scantemp = textscan(tabID,'%s%f%f%f','delimiter',',');
        
        if (datestr(scantemp[:,1]),'yyymmdd']
        end
        
        
        dlmcell(filename,scantemp,'-a',',')
        %dlmwrite(filename,scantemp,'-append')
        %fprintf(tabfile,'%s%,%f,%f,%f\n',scantemp);
        %[tstr sct ip vb] = textread(index(ob(p1s(i))).tabfile,'%s%f%f%f','delimiter',',');
        % tstrarray(row,:) = [ts,sct,ip,vb];
        clear scantemp tstr sct ip vb
        fclose(tabID);
    end

    
    
end

