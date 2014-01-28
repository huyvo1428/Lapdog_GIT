function [] = createTABLBL(filename,tabind,index)
  
%filename = long file name path
%tabind = data block indices for each measurement type, array
%index = index array from earlier creation - Ugly way to remember index
%inside function.


%After Discussion 24/1 2014
    %%FILE CONVENTION: RPCLAP_YYMMDD_hhmmss_MMM_APC
    %%MMM = MacroID, A= Measured quantity (B/I/V)%% , P=Probe number
    %%(1/2/3), C = Mode ( H/L/S)
    % B = probe bias voltage file
    % I = Current file, static Vb
    % V = potential
    
    % File should containt Time, spacecraft time, current, bias potential, Qualityfactor 
    % 2011-09-05T13:45:20.026075 
    %YYYY-MM-DDThh:mm:ss.ffffff % double[s],double[A],double [V],int
    
    
    
    
    
        len = length(tabind);
        for(i=1:len);
            tabID = fopen(index(tabind(i)).tabfile);
            
            %{tstr sct ip vb} = textscan(tabID,'%s%f%f%f','delimiter',',');
            
            scantemp = textscan(tabID,'%s%f%f%f','delimiter',',');
            
            %hello = scantemp{1,:};
            if (i==2)
                %display(scantemp{1,1})
                %display(scantemp{1,2})
                %display(scantemp{1,3})
             %   display(scantemp{1})
            end
            
            %scantemp = [tstr;sct;ip;vb];
            %herrow = herrow + length(scantemp);
            %tabfile = fopen(filename,'a');
            %dlmcell(filename,scantemp)
            
            %dlmcell(filename,scantemp,'-a')
            dlmcell(filename,scantemp,'-a',',')
            %dlmwrite(filename,scantemp,'-append')
            %fprintf(tabfile,'%s%,%f,%f,%f\n',scantemp);
            %[tstr sct ip vb] = textread(index(ob(p1s(i))).tabfile,'%s%f%f%f','delimiter',',');
            % tstrarray(row,:) = [ts,sct,ip,vb];
            clear scantemp tstr sct ip vb
            fclose(tabID);
            %fclose(tabfile);
        end
       % fclose(tabfile);
%for i=1:len
%    fprintf(tabfile,'%s%,%f,%f\n',tblock(i:);
%end
%fclose(tabfile);

end

