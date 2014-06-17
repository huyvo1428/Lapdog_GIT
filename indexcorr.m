% indexcorr.m Some corrections after index creation

count = 0;


lindex = length(index);


%mkdir(sprintf('%s/temp',archivepath))


dynampath= mfilename('fullpath'); %find path & remove/lapdog from string
dynampath = dynampath(1:end-10);

folder= sprintf('%s/temp',dynampath);
if exist(folder,'dir')~=7
    mkdir(folder);
end


for i=1:length(index)
    
    
    flag = 1;
    
    
    %if start and end time in file is on different days
    %Exception: if file is a sweep file, then don't separate files!
    
    if (strcmp(index(i).t0str(1:10),index(i).t1str(1:10))==0) && (index(i).sweep ==0)
        
        %datestr is a terrible way of comparing data date with very accurate
        %timing
        
        %  if (strcmp(datestr(index(i).t0,'yymmdd'),datestr(index(i).t1,'yymmdd'))==0 && index(i).sweep ==0)
        
        
        %read suspicious file
        
        trID = fopen(index(i).tabfile,'r');  %read file
        
        if index(i).probe == 3 %file for probe == 3 is different
            scantemp = textscan(trID,'%s%f%f%f%f','delimiter',',');
        else
            scantemp = textscan(trID,'%s%f%f%f','delimiter',',');
        end
        fclose(trID);
        
        primfname = sprintf('%s/primary_%s',folder,index(i).tabfile(end-28:end));
        primwID = fopen(primfname,'w'); %clear original file
        index(i).tabfile = primfname; %#ok<*SAGROW> %!!
        %now index stops pointing to original tabfile, and instead points to temporary file
        
        
        dday = index(i).t0str(1:10);
        
        for j=1:length(scantemp{1,3}) %loop all lines of file
            
            t1line = datenum(strrep(scantemp{1,1}{j,1},'T',' ')); %time of suspicious line
            
            
            if (strcmp(dday,scantemp{1,1}{j,1}(1:10)))  %if line is same day as t0str
                
                %    if (strcmp(datestr(index(i).t0,'yymmdd'),datestr(t1line,'yymmdd'))==1) %if line is same calendar day as t0
                
                %previous strcmp  was shit, datestr says
                %01T23:59:59.999865 = 02T00:00:00
                
                %so this line is okay, print it to same file unchanged.
                
                if index(i).probe == 3 %file for probe == 3 is different
                    fprintf(primwID,'%s,%16.6f,%14.7e,%14.7e,%14.7e\n',scantemp{1,1}{j,1},scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j),scantemp{1,5}(j));
                else
                    fprintf(primwID,'%s,%16.6f,%14.7e,%14.7e\n',scantemp{1,1}{j,1},scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j));
                end
                
            else %IF NOT THE SAME DATE
                               
                
                if (flag==1) %if first item
                    tempfilename = sprintf('%s/appendix_%i_%i_%s',folder,i,j,index(i).tabfile(end-28:end));   %let's preserve most of the file name
                    
                    % tempfilename = sprintf('%s/temp/appendix_%i_%i_%s',archivepath,i,j,index(i).tabfile(end-28:end));   %let's preserve most of the file name
                    twID = fopen(tempfilename,'w');
                    fclose(twID);
                    flag = 2; % remember to finilize index in later checks
                    
                    index(end+1) = index(i); %copy result to new index
                    
                    index(end).tabfile = tempfilename;
                    index(end).t0str = scantemp{1,1}{j,1}(1:23);
                    % index(end).sct0str = scantemp{1,2}(j);
                    index(end).sct0str = sprintf('"%s/%014.3f"',index(i).sct0str(2),scantemp{1,2}(j));
                    index(end).t0 = t1line;
                    
                    
                    % adding new end time information to OLD INDEX ENTRY i
                    
                    index(i).t1str = scantemp{1,1}{j-1,1}(1:23);
                    index(i).t1 = datenum(strrep(scantemp{1,1}{j-1,1},'T',' '));
                    index(i).sct1str = sprintf('"%s/%014.3f"',index(i).sct0str(2),scantemp{1,2}(j-1));
                    %keep some information the same as , (commented)
                    
                    
                end%if "flag check"
                twID=fopen(tempfilename,'a');
                
                
                if index(i).probe == 3 %file for probe == 3 is different
                    fprintf(twID,'%s,%16.6f,%14.7e,%14.7e,%14.7e\n',scantemp{1,1}{j,1},scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j),scantemp{1,5}(j));
                else
                    fprintf(twID,'%s,%16.6f,%14.7e,%14.7e\n',scantemp{1,1}{j,1},scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j));
                end
                
                
                fclose(twID); %close temp writefile
                
            end%if "calendar day check"
            
        end%for "read loop"
        
        
        if (flag ==2)
            flag =1;   %doesn't need this, flag is set to 1 a few steps later.
            
            count = count +1;
            fprintf(1,'%i split files\r ',count);
            %        i
            index(end).t1 = datenum(strrep(scantemp{1,1}{j,1},'T',' '));
            index(end).t1str= scantemp{1,1}{j,1}(1:23);
            index(end).sct1str =sprintf('"%s/%014.3f"',index(end).sct0str(2),scantemp{1,2}(j));
            
        end%if new file was created
        fclose(primwID);
        clear scantemp
    end%if "file start/end date check"
end%for "loop entire index"


%% Sort index by time
%[~,order] =sort([index(:).t0],'ascend');

[junk,order] =sort([index(:).t0],'ascend');

index =index(order);
clear order junk





%
%                     index(n).lblfile = [];
%                     index(n).tabfile = [];
%                     index(n).t0str = [];
%                     index(n).t1str = [];
%                     index(n).sct0str = [];
%                     index(n).sct1str = [];
%                     index(n).macrostr = [];
%                     index(n).t0 = -1;
%                     index(n).t1 = -1;
%                     index(n).macro = -1;
%                     index(n).lf = -1;
%                     index(n).hf = -1;
%                     index(n).sweep = -1;
%                     index(n).probe = -1;