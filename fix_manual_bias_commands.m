


rname = '/Users/frejon/Rosetta/Lapdog_GIT/time_periods_with_uncertain_bias_due_to_manual_commanding_v2018-11-29_14.29.txt';
trID=fopen(rname,'r');
%scantemp= textscan(trID,'%s %s %s','Delimiter','  ');
scantemp= textscan(trID,'%s %s %s');

fclose(trID);



for i=95:length(scantemp{1,1})
    
    
    if ~ismember(str2double(scantemp{1,3}{i}(3:end)),[304,305,306,307])
        %makro 305,305,306,307 are erroneously on this list, ignore
        
        str1='ls /mnt/squid/';
        str2=strcat('RO-C-RPCLAP-5-',scantemp{1,1}{i}(3:4),scantemp{1,1}{i}(6:7),'*V0.7/');
        str3= scantemp{1,1}{i}(1:4);
        str4='/*/D';
        str5= scantemp{1,1}{i}(9:10);
        str6='/*_';
        str7=scantemp{1,3}{i}(3:end);
        if ismember(str2double(scantemp{1,3}{i}(3:end)),[204,604]);
            str8='_I1H';
            %elseif   ismember(str2double(scantemp{1,3}{i}(3:end)),[304,305,306,307]);
            %     str2double(scantemp{1,3}{i}(3:end))
            %'help 304'
            %str8='_I1H'; %all other macros are Density  mode, both probes
            
        else
            str8='_I1L'; %all other macros are Density  mode, both probes
        end
        str9='.TAB';
        
        
        command = strcat(str1,str2,str3,str4,str5,str6,str7,str8,str9);
        [status,command_output] = system(command);
        cell_listoffiles=textscan(command_output,'%s');
        cell_listoffiles{1,1}% take the first file in the list?
        
        
        temp= lap_import(cell_listoffiles{1,1}{1});
        temp.t1 = irf_time(cell2mat(temp.textdata(:,1)),'utc>epoch');
        
        
        
        lapi1 = ge(temp.t1,irf_time(scantemp{1,1}{i},'utc>epoch')) & le(temp.t1,irf_time(scantemp{1,2}{i},'utc>epoch')) ;
        if sum(lapi1)== 0
            if  length(cell_listoffiles{1,1})>1
                fprintf(1,'try again');
                temp= lap_import(cell_listoffiles{1,1}{2});
                temp.t1 = irf_time(cell2mat(temp.textdata(:,1)),'utc>epoch');
                lapi1 = ge(temp.t1,irf_time(scantemp{1,1}{i},'utc>epoch')) & le(temp.t1,irf_time(scantemp{1,2}{i},'utc>epoch')) ;
            else
                lapi1(:)=1; %
            end
        end
        
        
        
        
        if ismember(str2double(scantemp{1,3}{i}(3:end)),[604])
            ind = find(lapi1,1,'first')
            if  ~isempty(ind)
                col1{i}= temp.textdata{ind,1};
                
            else
                'bug'
            end
            
        else
            i
            
            figure(61)
            subh(1)=subplot(2,1,1);
            plot(temp.t1(lapi1),temp.timeseries((lapi1),1)*1e9,'o')
            ax1=gca;ax1.YLabel.String= 'Current [nA]';
            irf_timeaxis(gca,'usefig');
            grid on;
            ax1.Title.String=sprintf('%d',i);
            subh(2)=subplot(2,1,2);
            plot(temp.t1(lapi1),temp.timeseries((lapi1),2),'o')
            irf_timeaxis(gca,'usefig');
            ax=gca;ax.YLabel.String= 'Voltage [V]';
            grid on;
            linkaxes(subh','x')
            vline(irf_time(scantemp{1,1}{i},'utc>epoch'),'g','start bias change')
            vline(irf_time(scantemp{1,2}{i},'utc>epoch'),'r','stop bias change')
            ax=gca;
            ax.Title.String=cell_listoffiles{1,1};
            lapi1(:)=1; %

        end
        
        str1= 'grep -rF "ROSETTA:LAP_VBIAS1"  /mnt/squid/';
        str9='.LBL';
        command1 = strcat(str1,str2,str3,str4,str5,str6,str7,str8,str9);
        [status,command_output_lap1] = system(command1);
        
        str1= 'grep -rF "ROSETTA:LAP_VBIAS2"  /mnt/squid/';
        command2 = strcat(str1,str2,str3,str4,str5,str6,str7,'_I2*',str9);
        [status,command_output_lap2] = system(command2);
        
        if ~isempty(command_output_lap2)
            col2{i}=strcat('0x',command_output_lap1(1,end-4:end-3),command_output_lap2(1,end-4:end-3));
        else
            'nope'
        end
        
        
        if str2double(scantemp{1,3}{i}(3:end))==506 %bug in macro 506
            col2{i}='0xa8a8';
            
        end
        str1= 'grep -rF "ROSETTA:LAP_P1P2_ADC20_MA_LENGTH"  /mnt/squid/';
        str9='.LBL';
        
       % if ~ismember(str2double(scantemp{1,3}{i}(3:end)),[604])
            if ~strcmp(str8,'_I1H');

            
            command1 = strcat(str1,str2,str3,str4,str5,str6,str7,str8,str9);
            [status,command_output_ma] = system(command1);
            %sprintf('hex: %s, dec; %d',command_output_ma(1,end-6:end-3),hex2dec(command_output_ma(1,end-6:end-3)));
            %fprintf(1,'dt = %f\n',hex2dec(command_output_ma(1,end-6:end-3))*0.5/57.8)
            error_dt = hex2dec(command_output_ma(1,end-6:end-3))*0.5/57.8;
            ax1.Title.String=sprintf('%d, errordt =%f',i,error_dt);
            breakpoint=1;
        end
    end
end

col3='0x0000';


% command = 'ls /mnt/squid/RO-C-RPCLAP-5-1*V0.8/*/*/*/*USC.TAB';
% [status,command_output] = system(command);
% cell_listoffiles=textscan(command_output,'%s');
% cell_listoffiles{1,1}

    col1{1}= '2014-07-05T13:04:46.000';%13:04:46.58'
    col1{6}= '2014-07-20T10:46:22.500';%10:46:23.03
    col1{7}= '2014-07-20T13:46:06.500';%13:46:07.030';
    col1{10}= '2014-07-26T11:51:26.500';%11:51:27.2149
    col1{14}= '2014-07-28T17:51:26.500';%17:51:27.2827
    col1{18}= '2014-07-30T23:51:27.000';%23:51:27.3500
    col1{21}= '2014-08-02T22:04:47.000';%22:04:47.4390
    col1{24}= '2014-08-03T22:04:47.000';%22:04:47.4690
    col1{25}= '2014-08-06T16:06:23.000';%16:06:23.5524
    col1{29}= '2014-08-08T23:04:31.000';%23:04:31.6216
    col1{32}= '2014-08-10T00:09:32.000';%.4420 <<-- Bug!
    col1{34}= '2014-08-13T02:05:19.000';%02:05:19.7462
    col1{36}= '2014-08-15T22:05:19.000';%22:05:19.8240
    col1{39}= '2014-08-17T22:44:47.000';%22:44:47.8838
    col1{41}= '2014-08-21T22:05:19.500';%22:05:20.0000
    col1{44}= '2014-08-23T22:14:55.500';%22:14:56.0593
    col1{46}= '2014-08-24T17:05:04.500';%17:05:05.0823
    col1{47}= '2014-08-25T22:05:19.500';%22:05:20.1178
    col1{50}= '2014-08-29T22:05:26.000';%22:05:26.8788' ?? Did this actually pass through?
    col1{54}= '2014-09-01T03:24:45.500';% ?? 
    %54 = bugged.     '/mnt/squid/RO-C-RPCLAP-5-1409-DERIV-V0.7/2014/SEP/D01/RPCLAP_20140901_032312_506_I1L.TAB'
    col1{57}= '2014-09-04T23:05:04.000';%23:05:04.4126
    col1{58}= '2014-09-06T22:25:36.000';%22:25:36.4705
    %61= bias command seemed to work
    col1{62}= '2014-09-10T08:30:56.000';%08:30:56.5660
    col1{63}= '2014-09-10T22:05:20.000';%22:05:20.5826
    col1{64}= '2014-09-12T22:25:36.000';%22:25:36.6417
    col1{65}= '2014-09-15T11:05:04.000';%.7160
    col1{67}= '2014-09-17T18:04:16.000';%.7832
    col1{68}= '2014-09-18T23:05:04.000';%.8178
    col1{69}= '2014-09-20T22:05:20.000';%.8705'
    col1{71}= '2014-09-22T22:05:20.000';%.9281'
    col1{72}= '2014-09-23T22:05:20.000';%.9566'
    col1{75}= '2014-09-25T22:15:28.500';%29.0140'
    col1{77}= '2014-09-27T22:05:20.500';%21.0711'
    col1{78}= '2014-09-29T22:05:20.500';%21.1282'
    col1{79}= '2014-10-01T22:09:36.500';%37.1855' %almost immediate
    col1{80}= '2014-10-03T22:06:57.000';%.2427'
    col1{81}= '2014-10-05T22:36:49.000';%.3004'
    col1{82}= '2014-10-07T22:17:05.000';%.3570
    col1{84}= '2014-10-08T22:06:57.000';%.3856
    col1{85}= '2014-10-09T22:06:57.000';%.4142
    col1{87}= '2014-10-11T22:06:57.000';%.4714
    col1{89}= '2014-10-13T22:35:35.000';%.6745 %bug? seem to affect LAP2, but not LAP1 !?
    col1{89}= '2014-10-13T22:36:49.000';%.5292';%<<<--- LAP2!?
    col1{90}= '2014-10-15T22:06:57.000';%.5858 ?? bug?
    col1{91}= '2014-10-16T14:08:33.000';%.6049 <- LAP2
    %92 Buggy I1H data Makro 807  <--- documented
    col1{92}= '2014-10-17T10:09:47.000';%.5941 
    %94 looks OK, m 204 
    col1{95}= '2014-11-14T10:04:50.000';%.4245
    col1{96}= '2014-11-21T00:09:38.000';%.6127
    %97 looks OK, m 204

    
   
    
    
    
    
    
% 
        twID=fopen('~/lapdog/fake_pds.bias','w');

    for i = 1:length(col1)
        
        if ~isempty(col1{i})
        %fprintf(twID,'%s\t%s\t%s\n',col1{i}(1:23),col2{i},col3);
        fprintf(twID,'%s\t%s\t%s\n',col1{i},col2{i},col3);

        end
        
            
        
    end
    fclose(twID);
        
     
    twID=fopen('~/lapdog/fake_pds.bias_debug','w');
diff=[];

    for i = 1:length(col1)
        
        i
        if ismember(str2double(scantemp{1,3}{i}(3:end)),[506,505,807])
            col2{i}='0xa8a8';            
        end
        
                
        if ismember(str2double(scantemp{1,3}{i}(3:end)),[604])
            col2{i}='0xd0d0';            
        end
        
                
                
        if ismember(str2double(scantemp{1,3}{i}(3:end)),[515])
            col2{i}='0xd0d0';            
        end
        
        
                
        if ~isempty(col1{i})
        diff(i) = irf_time(strrep((col1{i}),'T',' '),'utc>epoch') -irf_time(strrep((scantemp{1,1}{i}),'T',' '),'utc>epoch');

        else
            diff(i) =nan;
        end
        
       fprintf(twID,'%d\t%s\t%6.1f\t%s\t%s\t%s\t%s\t%s\n',i, scantemp{1,3}{i},diff(i),scantemp{1,1}{i},scantemp{1,2}{i},col1{i},col2{i},col3);

        
            
        
    end
    fclose(twID);
   
    
    
    
    
    debug= 0;
    if debug
        
        str8='_I1L'; %all other macros are Density  mode, both probes
        command = strcat(str1,str2,str3,str4,str5,str6,str7,str8,str9);
        [status,command_output] = system(command);
        cell_listoffiles=textscan(command_output,'%s');
        cell_listoffiles{1,1}% take the first file in the list?
        temp= lap_import(cell_listoffiles{1,1}{1});
        temp.t1 = irf_time(cell2mat(temp.textdata(:,1)),'utc>epoch');
        lapi1 = ge(temp.t1,irf_time(scantemp{1,1}{i},'utc>epoch')) & le(temp.t1,irf_time(scantemp{1,2}{i},'utc>epoch')) ;
      %  lapi1(:)=1; %

        figure(63)
        subh(1)=subplot(2,1,1);
        plot(temp.t1(lapi1),temp.timeseries((lapi1),1)*1e9,'o')
        ax=gca;ax.YLabel.String= 'Current [nA]';
        irf_timeaxis(gca,'usefig');
        grid on;
        ax.Title.String=sprintf('%d',i);

        subh(2)=subplot(2,1,2);
        plot(temp.t1(lapi1),temp.timeseries((lapi1),2),'o')
        irf_timeaxis(gca,'usefig');
        ax=gca;ax.YLabel.String= 'Voltage [V]';
        grid on;
        linkaxes(subh','x')
        vline(irf_time(scantemp{1,1}{i},'utc>epoch'),'g','start bias change')
        vline(irf_time(scantemp{1,2}{i},'utc>epoch'),'r','stop bias change')
        ax=gca;
        ax.Title.String=cell_listoffiles{1,1};
        lapi1(:)=1; %
        
    end
    
    
    
    
% 
% sampe of pds.bias file:
% 
% #                               
% # Generated from command logs   
% # with command: run_mpb filename 
% #                               
% # Note delimiter is a tab       
% #                               
% #                               
% # TIME|TAB|DENSITY P1P2|TAB|EFIELD P2P1|
% #
% 2004-03-21T20:24:39.000 *Mode*  0x0011
% 2004-05-08T11:42:50.000 0xd0d0  0x0000
% 2004-05-08T16:47:51.000 0xd0d0  0x0000
% 2004-05-08T21:30:40.387 *Mode*  0x000c
% 2004-05-08T21:46:37.408 *Mode*  0x000b
% 2004-05-08T22:01:37.427 *Mode*  0x000b
% 2004-05-08T22:16:36.446 *Mode*  0x000c
% 2004-05-08T22:31:37.466 *Mode*  0x000c
% 2004-05-08T22:48:57.488 *Mode*  0x0014



%ROSETTA:LAP_VBIAS1                = "0x007f"
%ROSETTA:LAP_VBIAS2                = "0x007f"

