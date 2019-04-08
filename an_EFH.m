function []= an_EFH(an_ind,tabindex,index)
%function []= an_downsample(an_ind,tabindex,intval)


%fprintf(awID,'%s,%16.6f,,,,\n',UTC_time,(0.5*intval+tday0+(j-1)*intval));
%outputarr 

dynampath = strrep(mfilename('fullpath'),'/an_downsample','');

kernelFile = strcat(dynampath,'/metakernel_rosetta.txt');
hold_flag=0;
i=1; %
j=0;


%%%------ MAKE E-FIELD FILES FIRST -------------------------------- %%%%
global MISSING_CONSTANT VFLOATMACROS
k=0;
tabfilez=([tabindex{an_ind(:) ,3}]);
while k<length(an_ind) % alternatively length(tabfilez)
    k=k+1;

    %is this file from a macro where we float both probes?
    if    ismember(index(tabfilez(k)).macro,VFLOATMACROS{1}(ismember(VFLOATMACROS{1},VFLOATMACROS{2})))

        %pass only parts of the indices that I need:
        %an_Efld_debug(tabindex(an_ind(k:k+1),:), index(tabfilez(k:k+1)),kernelFile)
        an_Efld(tabindex(an_ind(k:k+1),:), index(tabfilez(k:k+1)),kernelFile)

        k=k+1;% k increased by two in this loop. The wanted files are subesequent
    end

end

end


function []=an_Efld(red_tabindex,red_index,kernelFile)

global efl_tabindex MISSING_CONSTANT target


%calling this inside the loop was madness
paths();
cspice_furnsh(kernelFile);


row_byte=0;
debug=0;
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


    fprintf(1,'error, check files 1=%s, 2=%s \n',red_tabindex{1,1},red_tabindex{2,1})

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
   %lent1=length(scantemp{1,5});

    % prep output


           %%%--------illumination check------------------------%%%

        if ~debug %I don't want to do this while debugging at the moment
            %dynampath = strrep(mfilename('fullpath'),'/an_Efld','');



            if ismemberf(macroNo(1),hex2dec({'710'}))
                [junk,SEA,SAA]=orbit('Rosetta',scantemp2{1,1},target,'ECLIPJ2000','preloaded');
                len=length(scantemp2{1,5});
                timing={scantemp2{1,1}{1,1},scantemp2{1,1}{end,1},scantemp2{1,2}(1),scantemp2{1,2}(end)};



            else
                [junk,SEA,SAA]=orbit('Rosetta',scantemp{1,1},target,'ECLIPJ2000','preloaded');
                len=length(scantemp{1,5});
                timing={scantemp{1,1}{1,1},scantemp{1,1}{end,1},scantemp{1,2}(1),scantemp{1,2}(end)};

            end

            SEA=SEA(1:len); %fix
            SAA=SAA(1:len);
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
            printbooleanind=~dark_ind; %print everything else

            %printbooleanind(dark_ind)=false; %won't be printed.
            %%%----------------------------------------------%%%
        else
            %plot? % sprintf('%d','E') =69
            figure(69);plot(scantemp{1,2}-scantemp{1,2}(1),scantemp2{1,4}-scantemp{1,4})
            ax=gca;ax.XLabel.String='Seconds [s]';ax.YLabel.String='V2-V1 [V]';ax.Title.String=sprintf('%s',red_tabindex{1,1});
            grid on;

        end%~debug



        efname =red_tabindex{1,1};
        efname(end-6:end-4) = 'EFH';
        efolder = strrep(red_tabindex{1,1},red_tabindex{1,2},'');

       % if  ismemberf(macroNo(1),hex2dec({'710','910'}))


            %v1l=
            %v1l(printbooleanind)=nan;
%             %v2l=scantemp2{1,4};
%             %v2l(printbooleanind)=nan;
%             x10_input=[];
%             x10_input.v1l=scantemp{1,4};
%             x10_input.v2l=scantemp2{1,4};
%             x10_input.t1l=scantemp{1,2};
%             x10_input.t2l=scantemp2{1,2};
%             x10_input.t1utc=scantemp{1,1};
%             x10_input.t2utc=scantemp2{1,1};
%             x10_input.qf1=uint64(scantemp{1,5});
%             x10_input.qf2=uint64(scantemp2{1,5});
%            % x10_input.SAA=SAA;
% 
% 
% 
%             efh = efl_x10(x10_input);
%             %fprintf(1,'macrono1=%s, 2=%s \n',dec2hex(macroNo(1)),dec2hex(macroNo(2)))
%             efh.qf=bitor(efh.qfraw(:,1),efh.qfraw(:,2));
      %  else




            if length(scantemp{1,5})~= length(scantemp2{1,5})
                fprintf(1,'Error, files not equally long. file1: %s, \n file2: %s \n', red_tabindex{1,1}, red_tabindex{2,1});

            end
            efh=[];


%
%             out.t_obt=[tl;tm];%vertcat should work
%             out.ef_out = [efl;efm];%vertcat should work
%             [junk,ascind]=sort(out.t_obt,'ascend');
%             out.ef_out=out.ef_out(ascind);
%             out.t_obt=out.t_obt(ascind);
%             out.t_utc=tb_utc(save_ind);
%             out.freq_flag=9*ones(1,length(out.t_obt);
%             out.freq_flag(out.t_obt==tm)=3; %see mail" kombinationer MA_LENGTH & DOWNSAMPLE 18/2 2019"
%             out.qfraw=qfraw(save_ind);
%
            efh.t_utc=scantemp{1,1};
            efh.t_obt=scantemp{1,2};
            %efl.qf= bitor(scantemp{1,5},scantemp2{1,5}); %qualityflag!    % Does not work on MATLAB R2009a since bitor then does not accept arguments of class/type int32 (but uint32, uint64 work).
            efh.qf= bitor(uint64(scantemp{1,5}),uint64(scantemp2{1,5})); %qualityflag!
            %efl.ef_out = 1000*(scantemp2{1,4}-scantemp{1,4})/5;
            efh.ef_out = efl_most(efh.t_obt,scantemp{1,4},scantemp2{1,4});


            %----------- SATURATION HANDLING FKJN 6/3 2018 ---------------%
            efh.ef_out(isnan(efh.ef_out))=MISSING_CONSTANT;
            %----------- SATURATION HANDLING FKJN 6/3 2018 ---------------%

            efh.freq_flag=0*ones(1,length(efh.t_obt)); %7 = 64 Dwnsmpl 64 Moving average

                 
                 if macroNo(1)==hex2dec('910') |  macroNo(1)==hex2dec('710')
                     
                    efh.freq_flag=nan(1,length(efh.t_obt)); %

                 else
                     efh.freq_flag=zeros(1,length(efh.t_obt)); %
                 end
             
                 
%                 efh.freq_flag=7*ones(1,length(efh.t_obt)); %7 = 64 Dwnsmpl 64 Moving average
%             elseif macroNo(1)==hex2dec('802')
%                 efh.freq_flag=0*ones(1,length(efh.t_obt)); %0 = full resolution
%             else
%                 efh.freq_flag=nan;
%                 'error. I didnt think we would get other this E-field macro'
%             end

       % end




%         diffI =abs((scantemp2{1,3})-(scantemp{1,3}));
%         printbooleanind(diffI>3e-11)=false;  % bias not consistent.
%
%         if any(~printbooleanind)
%             fprintf(1,' some shadowed values, or current bias values do not match')
%         end
%





        dummy=-1000;
        %dummyqf=1000;
        ewID= fopen(efname,'w');
        N_rows = 0;
        fprintf(1,'printing %s, macro: %s\n',efname, dec2hex(macroNo(1)));
        for j = 1:len

            if printbooleanind(j) %
                                  %UTC   %OBT      Efield, frequencyflag, qf
                row_byte= fprintf(ewID,'%s, %16.6f, %16.6f, %1i, %03i\r\n',efh.t_utc{j,1},efh.t_obt(j),efh.ef_out(j),efh.freq_flag(j),efh.qf(j));
                N_rows = N_rows + 1;
            end


        end
        fclose(ewID);
        cspice_kclear;

        fileinfo = dir(efname);

        if N_rows==0 || fileinfo.bytes==0
       % if fileinfo.bytes ==0 %happens if the entire collected file is empty (all invalid values)
            %  if N_rows > 0 %doublecheck!

            fprintf(1,'empty file?: %s \n bytes: %i, deleting...\n',efname,fileinfo.bytes);

            delete(efname); %will this work on any OS, any user?
            % end

        else % catalogue file


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




        