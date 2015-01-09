function file_contents = createLBL_read_LBL_header(file_path)
    [fid, errmess] = fopen(file_path, 'r');        
    if fid < 0
        error(sprintf('Error, cannot open file %s', file_path))
    end

    fprintf(1, 'Read LBL header from file: %s\n', file_path);   % NOTE: Not ideal place to write log message but useful for debugging. Disable?
    fc = textscan(fid,'%s %s','Delimiter','=');
    fclose(fid);

    i_TABLE = find(strcmp(fc{1,2}(),'TABLE'), 1, 'first');
    file_contents.keys   = strtrim(fc{1}(1:i_TABLE-1, :));
    file_contents.values = strtrim(fc{2}(1:i_TABLE-1, :));
end
