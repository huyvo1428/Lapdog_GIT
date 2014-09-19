% process -- grind all ops blocks through the mill
%
%
% Assumes:
% 1. index has been generated and exists in workspace (indexgen.m)
% 2. ops blocks are defined (opsblock.m)

global tabindex;
tabindex = {};

sctconv=@sct2obt;



for b = 1:nob   % Loop through all ops blocks
    

    
    
    
 %   day = datestr(index(obs(b)).t0,'yyyymmdd');  % convert block start time index to time string, convert to yyyymmdd format
    
    ob = obs(b):obe(b); %ob goes from start time index to end time index

    
    % Find sweeps:
    p1s = find([index(ob).sweep] & ([index(ob).probe] == 1)); %%returns indices of all sweeps for probe 1 for macro operation block
    p2s = find([index(ob).sweep] & ([index(ob).probe] == 2));
    
    
    
    % Find E data:
    
    
    p1el = find([index(ob).lf] & [index(ob).efield] & ([index(ob).probe] == 1));
    p2el = find([index(ob).lf] & [index(ob).efield] & ([index(ob).probe] == 2));
    p1eh = find([index(ob).hf] & [index(ob).efield] & ([index(ob).probe] == 1));
    p2eh = find([index(ob).hf] & [index(ob).efield] & ([index(ob).probe] == 2));
    
    % Find N data:
    p1nl = find([index(ob).lf] & ~[index(ob).efield] & ([index(ob).probe] == 1));
    p2nl = find([index(ob).lf] & ~[index(ob).efield] & ([index(ob).probe] == 2));
    p1nh = find([index(ob).hf] & ~[index(ob).efield] & ([index(ob).probe] == 1));
    p2nh = find([index(ob).hf] & ~[index(ob).efield] & ([index(ob).probe] == 2));
    
    
    %probe 3
    % Find E data:
    p3el = find([index(ob).lf] & [index(ob).efield] & ([index(ob).probe] == 3));
    p3eh = find([index(ob).hf] & [index(ob).efield] & ([index(ob).probe] == 3));
    % Find N data:
    p3nl = find([index(ob).lf] & ~[index(ob).efield] & ([index(ob).probe] == 3));
    p3nh = find([index(ob).hf] & ~[index(ob).efield] & ([index(ob).probe] == 3));
    
%     
    %     % This does not preserve label indices, but only the new indices. so
    %     % index(ob) where ob = 6:10, gives results in the range 1:5
    %
    %
    
    
    
%     %Get Sweep measurements times
%     obt0temp= cellfun(@(s) s(4:end-1), {index(ob(p1s)).sct0str}, 'uni',false);
%     obt1temp= cellfun(@(s) s(4:end-1), {index(ob(p1s)).sct1str}, 'uni',false);
    
    obt0temp= cell2mat(cellfun(@sct2obt, {index(ob(p1s)).sct0str}, 'uni',false));
    obt1temp= cell2mat(cellfun(@sct2obt, {index(ob(p1s)).sct1str}, 'uni',false)); 
    sweept1 = [obt0temp;obt1temp];
    
    
%     sweept1 = [str2double(obt0temp); str2double(obt1temp)];
%     clear sct0temp sct1temp

    clear obt0temp obt1temp
    obt0temp= cell2mat(cellfun(@sct2obt, {index(ob(p2s)).sct0str}, 'uni',false));
    obt1temp= cell2mat(cellfun(@sct2obt, {index(ob(p2s)).sct1str}, 'uni',false));

    
%     
%     obt0temp= cellfun(@(s) s(4:end-1), {index(ob(p2s)).sct0str}, 'uni',false);
%     obt1temp= cellfun(@(s) s(4:end-1), {index(ob(p2s)).sct1str}, 'uni',false);
    sweept2 = [obt0temp;obt1temp];
    clear obt0temp obt1temp
    
%     sweept1= arrayfun(@sct2obt,sweept1);
%     sweept2= arrayfun(@sct2obt,sweept2);
    
    
    sweept3 = [sweept1,sweept2];
    
    
    
    %     %%%% Start TAB genesis
    %
    %
    %
    
    %Generate sweep files
    %
    if(~isempty(p1s)) createTAB(derivedpath,ob(p1s),index,index(obs(b)).t0,'B1S',sweept1); end
    if(~isempty(p2s)) createTAB(derivedpath,ob(p2s),index,index(obs(b)).t0,'B2S',sweept1); end
    
%     %Generate E data files
%     if(~isempty(p1el)) createTAB(derivedpath,ob(p1el),index,index(obs(b)).t0,'V1L',sweept1); end
%     if(~isempty(p2el)) createTAB(derivedpath,ob(p2el),index,index(obs(b)).t0,'V2L',sweept2); end
%     if(~isempty(p1eh)) createTAB(derivedpath,ob(p1eh),index,index(obs(b)).t0,'V1H',sweept1); end
%     if(~isempty(p2eh)) createTAB(derivedpath,ob(p2eh),index,index(obs(b)).t0,'V2H',sweept2); end
%     
%     
%     if(~isempty(p3el)) createTAB(derivedpath,ob(p3el),index,index(obs(b)).t0,'V3L',sweept3); end 
%     if(~isempty(p3eh)) createTAB(derivedpath,ob(p3eh),index,index(obs(b)).t0,'V3H',sweept3); end 
%     %Generate N data files
%     if(~isempty(p1nl)) createTAB(derivedpath,ob(p1nl),index,index(obs(b)).t0,'I1L',sweept1); end
%     if(~isempty(p2nl)) createTAB(derivedpath,ob(p2nl),index,index(obs(b)).t0,'I2L',sweept2); end
%     if(~isempty(p1nh)) createTAB(derivedpath,ob(p1nh),index,index(obs(b)).t0,'I1H',sweept1); end
%     if(~isempty(p2nh)) createTAB(derivedpath,ob(p2nh),index,index(obs(b)).t0,'I2H',sweept2); end
%     
%     if(~isempty(p3nl)) createTAB(derivedpath,ob(p3nl),index,index(obs(b)).t0,'I3L',sweept3); end
%     if(~isempty(p3nh)) createTAB(derivedpath,ob(p3nh),index,index(obs(b)).t0,'I3H',sweept3); end


    
    
 fprintf(1,'Macroblock %i out of  %i.\n Latest file created from %s\n ',b,nob,index(obe(b)).t1str);
    
end %observation block for loop
