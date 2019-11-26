%
% Utility for saving large arrays in multiple .mat files to circumvent MATLAB's 2 GiB (uncompressed) size limit.
% 
% Accepts any array, converts it to a 1D which is then split up in parts (different index ranges) which are stored in
% one file each.
%
%
% NOTE: Using MATLAB's "save" with the flag "-v7.3" should in theory solve the same problem but has been shown to be
% impractically slow (very) and generate far too large files.
% NOTE: Can not choose filenames entirely.
% NOTE: Will overwrite preexisting files.
%
%
% NOTE: Store_split_array2 is a backward-incompatible update (wrt. saved files) to store_split_array. Intented to
% eventually change names and the old one should be obsoleted.
%
%
% STATUS
% ======
% Seems to work. Survives automatic tests, but is untested in actual use.
%
%
% NAMING CONVENTIONS
% ==================
% array            : The variable that is seen by the interface, that is saved and loaded.
% SA, Stored Array : "array" reformatted into 1D array for internal storage.
% part             : One of the parts of the SA, either in memory, or the file that stores it.
%                    NOTE: Parts are numbered 0..(N-1), both in filenames and variables.
% FC               : File Content.
%
%
% Initially created 2018-12-03 by Erik P G Johansson.
%
classdef Store_split_array2
    % PROPOSAL: Separate functions for splitting and merging array.
    % PROPOSAL: Split default filenames from save/load.
    %   CON: load then requires all filenames to be known from beforehand and can not read number of files from first
    %        file.
    %
    % TODO-DECISION: How choose filenames?
    %   PROPOSAL: Separate function for splitting data (choosing indices and maybe selecting metadata) and choosing filenames.    
    % PROPOSAL: Add list of filenames to first file.
    %   PRO: Backward-compatible, if changes filenaming convention.
    %   CON: Can not change filenames of already created files!
    %   NOTE: Must assume something about directory locations, e.g. same parent directory.
    % PROPOSAL: Add list of file "suffixes" to first file.
    %
    % TODO-DECISION: Log messages enabled/disabled/optional?

    properties(Constant, Access=private)
        FC_VARIABLE_NAME_LIST = {'saveOperationId', 'saveTimestamp', 'arraySize', 'nParts', 'iStoredArrayPartBegin', 'iStoredArrayPartEnd', 'iPart', 'storedArrayPart', 'metadata'};
    end



    methods(Static, Access=public)

        function save(array, metadata, pathPrefix, nIndicesPerFile)

            % ASSERTION
            assert(nIndicesPerFile >= 1)

            % Determine how to split array.
            [iSaPartBeginArray, iSaPartEndArray] = EJ_library.utils.Store_split_array2.split_indices(numel(array), nIndicesPerFile);
            
            % Determine list of filenames.
            for iPart = 0 : (numel(iSaPartBeginArray)-1)
                fileList{iPart+1} = EJ_library.utils.Store_split_array2.get_file_path(pathPrefix, iPart);
            end

            % Split array and save to files as specified above.
            EJ_library.utils.Store_split_array2.save_universal(array, metadata, fileList, iSaPartBeginArray, iSaPartEndArray)
        end



        function [array, metadata] = load(pathPrefix)
            iPart = 0;
            
            while true
                filePath = EJ_library.utils.Store_split_array2.get_file_path(pathPrefix, iPart);
                
                %fprintf('Loading from "%s"\n', filePath);
                Fc = load(filePath);
                
               
                
                %==========================================               
                % Assertions, and help code for assertions
                %==========================================               
                if iPart == 0
                    % CASE: First file/part
                    
                    firstSaveOperationId = Fc.saveOperationId;
                    loadedParts          = zeros(Fc.nParts, 1);
                else
                    % CASE: NOT first file/part
                    
                    % ASSERTION: File belongs together with other files: saveOperationID is identical for all parts.
                    if firstSaveOperationId ~= Fc.saveOperationId
                        error('saveOperationId differs between array part files, indicating that files are not meant to be combined.');
                    end
                end                
                % ASSERTION: Have not loaded the same part before.
                if loadedParts(Fc.iPart+1)
                    error('Encountering the same file/part twice. This indicates that the set of files is bad.' )
                end
                loadedParts(Fc.iPart+1) = true;



                %=========================================
                % Restore loaded part of array into array
                %=========================================
                array(Fc.iStoredArrayPartBegin : Fc.iStoredArrayPartEnd) = Fc.storedArrayPart;    % NOTE: Works also if "array" is unitialized.



                iPart = iPart + 1;
                if iPart >= Fc.nParts
                    metadata = Fc.metadata;
                    break
                end
            end

            % ASSERTION: Has loaded all parts.
            if ~all(loadedParts)
                error('Algorithm failed to load all parts/files. Algorithm or files could be wrong.')
            end
            
            % Convert array: 1-D --> N-D
            array = reshape(array, Fc.arraySize);
        end

    end    % methods(Static, Access=public)
    
    
    
    methods(Static, Access=private)
        
        % Return the filename for a specified part. Effectively defines the filenaming convention used.
        %
        % NOTE: Does not add "." or any other "separator" between the path prefix and the number. The caller must include
        % that in the path prefix if they wish to have one.        
        function filePath = get_file_path(pathPrefix, iPart)
            assert(iPart >= 0)
            
            filePath = [pathPrefix, sprintf('%06i.mat', iPart)];
        end



        % Actual implementation of saving to files.
        % Takes arbitrary list of file paths, and arbitrary index ranges to use for splitting.
        %
        % RATIONALE
        % =========
        % Other methods can can wrap this method and split data and chose filenames in their own way.
        % NOTE: "load" method does not permit any analogue functionality though and "can" not obviously be made to do so
        % since it does not know how many files to load until it has already read the first file. Rewriting requires
        % wrapper function to first look for available files, and then submit the list. Doable but somewhat ~awkward.
        %
        function save_universal(array, metadata, fileList, iSaPartBeginArray, iSaPartEndArray)
            % IMPLEMENTATION NOTE: It is important that
            % (1) variable names actually stored in file are stable (unchanging), for backward compatibility (that
            % future versions of code can read files written by earlier versions of code, and
            % (2) the file format is self-explanatory.
            % Therefore using somewhat long struct fieldnames.
            
            Fc.saveOperationId = rand();    % Unique "operation ID" to store in files to make it possible for the reader to verify that the loaded files belong together.
            Fc.saveTimestamp   = [datestr(now, 'YYYY-mm-DD, HH:MM:SS'), ' (local time)'];
            Fc.arraySize       = size(array);    % NOTE: Defining variable just so that "save" can store/save it.
            Fc.metadata        = metadata;
            
            % Convert array: N-D --> 1-D
            storedArray = reshape(array, [numel(array), 1]);

            Fc.nParts = numel(iSaPartBeginArray);

            for iPart = 0 : (Fc.nParts-1)

                Fc.iStoredArrayPartBegin = iSaPartBeginArray(iPart+1);
                Fc.iStoredArrayPartEnd   = iSaPartEndArray  (iPart+1);
                Fc.iPart                 = iPart;

                Fc.storedArrayPart = storedArray(Fc.iStoredArrayPartBegin : Fc.iStoredArrayPartEnd);    % NOTE: Defining variable just so that "save" can store/save it.
                
                %===========
                % Save file
                %===========
                % ASSERTION: Check that variable names, and thus file format, have not changed by mistake.
                EJ_library.utils.assert.struct2(Fc, EJ_library.utils.Store_split_array2.FC_VARIABLE_NAME_LIST, {});
                % IMPLEMENTATION NOTE: "-struct" stores the struct fields as separate variables, but since "s = load(...)"
                % returns a struct with the variables as fields, this is "symmetric" with the load command despite that
                % the file contains separate variables (not a single struct).
                %   NOTE: This means the struct variable name "Fc" is not included in the file and that fieldnames
                %         should be chosen accordingly.
                %fprintf('Saving to "%s"\n', fileList{iPart});
                save(fileList{iPart+1}, '-struct', 'Fc');

            end
        end



        % Return list of index ranges in which a 1D array can be split.
        function [iSaPartBeginArray, iSaPartEndArray] = split_indices(lenSa, nPerPart)
            % ASSERTIONS
            assert(lenSa    >= 0)
            assert(nPerPart >= 1)
            
            iSaPartBeginArray = [];
            iSaPartEndArray   = [];
            iSaPartBegin = 1;

            while true
                iSaPartEnd = min(iSaPartBegin + nPerPart-1, lenSa);
                
                iSaPartBeginArray(end+1) = iSaPartBegin;
                iSaPartEndArray(end+1)   = iSaPartEnd;
                
                if (lenSa <= iSaPartEnd)
                    break
                end
                
                iSaPartBegin = iSaPartEnd + 1;
            end

        end    

    end   % methods(Static, Access=private)

end
