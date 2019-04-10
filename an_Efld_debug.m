%function that takes reduced tabindices.

function []=an_Efld_debug(red_tabindex,red_index,kernelFile)

global efl_tabindex MISSING_CONSTANT target
  
debug=1;
if debug

    red_tabindex{1,1}=strrep(red_tabindex{1,1},'/homelocal/frejon/squidcopy/','/mnt/spis/');
    red_tabindex{2,1}=strrep(red_tabindex{2,1},'/homelocal/frejon/squidcopy/','/mnt/spis/');
    
    
end

probenr(1) = str2double(red_tabindex{1,1}(end-5));
probenr(2) = str2double(red_tabindex{2,1}(end-5));

macroNo(1) = red_index(1).macro;
macroNo(2) = red_index(2).macro;
fprintf(1,'macrono1=%s, 2=%s \n',dec2hex(macroNo(1)),dec2hex(macroNo(2)))

p_ind=false(1,2);
if probenr(1) == 1 && probenr(2) == 2
    p_ind(1)=true;    
elseif probenr(1) == 2 && probenr(2) == 1
    p_ind(2)=true;
else
    'error'

    
end


        ErID = fopen(red_tabindex{p_ind,1},'r'); %probe 1
        if ErID < 0
            fprintf(1,'Error, cannot open file1 %s\n',red_tabindex{p_ind,1});
            return;
        end % if I/O error
        %    scantemp=textscan(arID,'%s%f%f%f%i','delimiter',',');
        scantemp=textscan(ErID,'%s%f%f%f%d','delimiter',',');
        fclose(ErID);
        
%       %----------- SATURATION HANDLING FKJN 6/3 2018 ---------------%
        test_column = 4;
        scantemp{1,test_column}(scantemp{1,test_column}==MISSING_CONSTANT) = NaN;
%       %-------------------------------------------------------------%



        ErID = fopen(red_tabindex{~p_ind,1},'r');%probe 2
        if ErID < 0
            fprintf(1,'Error, cannot open file2 %s\n', red_tabindex{~p_ind,1});
            return;
        end % if I/O error
        %    scantemp=textscan(arID,'%s%f%f%f%i','delimiter',',');
        scantemp2=textscan(ErID,'%s%f%f%f%d','delimiter',',');
        fclose(ErID);
        
%       %----------- SATURATION HANDLING FKJN 6/3 2018 ---------------%
        scantemp2{1,test_column}(scantemp{1,test_column}==MISSING_CONSTANT) = NaN;
%       %-------------------------------------------------------------%
             

    %read files, handled NaNs. let's compute
    lent1=length(scantemp{1,5});
    if lent1~= length(scantemp2{1,5})
        
        fprintf(1,'Error, files not matching file1: %s, \n file2: %s \n', red_tabindex{1,1}, red_tabindex{2,1});

    end
    % prep output

    
        E_field2minus1 = scantemp2{1,4}-scantemp{1,4};
        %----------- SATURATION HANDLING FKJN 6/3 2018 ---------------%
        E_field2minus1(isnan(E_field2minus1))=MISSING_CONSTANT;
        %----------- SATURATION HANDLING FKJN 6/3 2018 ---------------%
 
        qf= bitor(scantemp{1,5},scantemp2{1,5}); %qualityflag!
        
        efname =red_tabindex{1,1};
        efname(end-6:end-4) = 'EFL';
        efolder = strrep(red_tabindex{1,1},red_tabindex{1,2},'');

        
        diffI =abs((scantemp2{1,3})-(scantemp{1,3}));
        printbooleanind=diffI<3e-11;  
        
        if any(~printbooleanind)    
            fprintf(1,'Error, Current bias values do not match')
        end
        
        
           %%%--------illumination check------------------------%%%

        if ~debug %I don't want to do this while debugging at the moment
            %dynampath = strrep(mfilename('fullpath'),'/an_Efld','');
            paths();
            
            cspice_furnsh(kernelFile);       
            [junk,SEA,SAA]=orbit('Rosetta',scantemp{1,1},target,'ECLIPJ2000','preloaded');
            cspice_kclear;
            
            SEA=SEA(1:lent1); %fix
            SAA=SAA(1:lent1);
            
         % *Elias values* (from photoemission study):
                Phi11 = 131.2;
                Phi12 = 179.2;
                illuminati1 = ((SAA < Phi11) | (SAA > Phi12)); 
                               
                Phi21 = 18;
                Phi22 = 82;
                Phi23 = 107;
                illuminati2 = ((SAA < Phi21) | (SAA > Phi22)) - 0.6*((SAA > Phi22) & (SAA < Phi23));
            SEA_OK = abs(SEA)<1; %  0 ?1 degree  = nominal pointing

            illuminati1(~SEA_OK)=0.3;

            dark_ind=illuminati1<0.9| illuminati2<0.9; %not sure about the illumination of these measurements
            printbooleanind(dark_ind)=0; %won't be printed.
            %%%----------------------------------------------%%%
        else
            %plot? % sprintf('%d','E') =69
            figure(69);plot(scantemp{1,2}-scantemp{1,2}(1),E_field2minus1)
            ax=gca;ax.XLabel.String='Seconds [s]';ax.YLabel.String='V2-V1 [V]';ax.Title.String=sprintf('%s',red_tabindex{1,1});
            grid on;
        
        end%~debug
        
        
        timing={scantemp{1,1}{1,1},scantemp{1,1}{end,1},scantemp{1,2}(1),scantemp{1,2}(end)};

        dummy=-1000;
        %dummyqf=1000;
        ewID= fopen(efname,'w');
        N_rows = 0;
        fprintf(1,'printing %s, macro: %s\n',efname, dec2hex(macroNo(1)));
        for j = 1:lent1
            
            if printbooleanind(j) %

                row_byte= fprintf(ewID,'%s, %16.6f, %16.6f, %16.6f, %03i\r\n',scantemp{1,1}{j,1},scantemp{1,2}(j),diffI(j),dummy,qf(j));
                N_rows = N_rows + 1;
            end

            
        end
        fclose(ewID);
        
        
        
%     
%         an_tabindex{end+1,1} = efname;                   % Start new line of an_tabindex, and record file name
%         an_tabindex{end,2} = strrep(efname,efolder,''); % shortfilename
%         an_tabindex{end,3} = red_tabindex{1,3}; % First calib data file index
%         an_tabindex{end,4} = N_rows;                % length(foutarr{1,3}); % Number of rows
%         an_tabindex{end,5} = 5;            % Number of columns
%         an_tabindex{end,6} = [];
%         an_tabindex{end,7} = 'Efield'; % Type
%         an_tabindex{end,8} = timing;
%         an_tabindex{end,9} = row_byte;     
        
        
        efl_tabindex(end+1).fname = efname;                   % Start new line of an_tabindex, and record file name
        efl_tabindex(end).fnameshort =  strrep(efname,efolder,''); % shortfilename
        efl_tabindex(end).first_index = red_tabindex{1,3}; % First calib data file index
        efl_tabindex(end).no_of_rows = N_rows;                % length(foutarr{1,3}); % Number of rows
        efl_tabindex(end).no_of_columns = 5;            % Number of columns
        % efl_tabindex{end,6] = an_ind(i);
        efl_tabindex(end).type = 'Efield'; % Type
        efl_tabindex(end).timing = timing;
        efl_tabindex(end).row_byte = row_byte;

end
