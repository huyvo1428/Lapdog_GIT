%
% Class that models an ordered key-value pair list (KVPL).
% A KVPL is an ordered list of unique keys (strings). For every key there is a value (string). Is effectively a kind of
% associative array.
%
% The class is a MATLAB "value class" which implies that it is immutable and passed-by-value.
% Code replaces older standard struct KVPL that could be modified with functions EJ_library.utils.KVPL.* .
%
%
% IMPLEMENTATION NOTES
% ====================
% KVPLs have some characteristics of
%   (1) sets (of keys),
% but also the properties of
%   (2) ordered lists, and 
%   (3) "values" (same key can have different values).
% This makes the "fundamental operations" on KVPLs, and hence fundamental methods to implement less obvious. The methods
% have therefore been chosen and named depending on which properties they use. The method for joining/merging/combining
% KVPLs with non-overlapping keys is therefore called to refer to that it is a "list" operation that produces a
% predictable ordering, not a set operation (e.g. union).
% (1) Set-like operations have been chosen as unambiguous set-like operations which naturally and unambiguously preserve
% order:
%       diff, intersection, subset               : KVPL + key set --> KVPL
%       overwrite_intersection, overwrite_subset : KVPL + KVPL    --> KVPL
%       equals(... 'ignore key ordering')        : KVPL + KVPL --> boolean
% Other set-like operations can be conceived of but they do not seem to be as easily/naturally expressed as one might think, e.g.
% method for combining two KVPLs (KVPL + KVPL --> KVPL).
% (2) List-like operations:
%       append                              : KVPL + KVPL --> KVPL
%       equals(... 'consider key ordering') : KVPL + KVPL --> boolean
%
%
% Initially created 2018-11-06 by Erik P G Johansson.
% Based on earlier functions and a standardized and analogous struct.
%
classdef KVPL2
    % PROPOSAL: Change name.
    %   PRO: Should change name away from KVPL2 anyway.
    %   PRO: There are other "key-value pair lists" which are not KVPLs in the meaning of this class.
    %       Ex: *.utils.read_ODL_file uses "AsgList", a list of key = value assignments where the same key can
    %           occur twice.
    %   PROPOSAL: Indicate UNIQUE KEYS.
    %   PROPOSAL: Indicate that KEYS should be interpreted as a SET.
    %   PROPOSAL: Indicate that only works with (key) STRINGS.
    %       CON: Might change.
    %   PROPOSAL: Indicate likeness to standard data struct.
    %       PROPOSAL: associative arrays, map, dictionary.
    %           NOTE: Implies unique keys. Might NOT imply ordering.
    %       PROPOSAL: Association list, https://en.wikipedia.org/wiki/Association_list
    %       PROPOSAL: Associative list (invention)
    %       NOTE: "Order(ed)" seems to usually imply internal sorting, i.e. not an externally set order that is
    %             well-defined under operations.
    %   PROPOSAL: OSAA = Ordered String Associative Array
    %   PROPOSAL: OAAS = Ordered Associative Array of Strings
    %   PROPOSAL: UKAL = Unique Keys Associative List; AKUL = Associative List Unique Keys
    %   PROPOSAL: KSAL = Key Set Associative List
    %   PROPOSAL: ALKS = Associative List Key Set
    %   NOTE: May some day want an associative list-class that does not require unique keys.
    %
    % PROPOSAL: Permit non-string values.
    % TODO-DECISION: Forbid empty string keys?
    % 
    % PROPOSAL: Convert to handle object.
    %   
    % NOTE: Can obtain KVPL.keys as set (not list) to use as argument in methods.
    % NOTE: Can obtain KVPL.keys as list (not set) to use as argument in methods.
    %
    % PROPOSAL: 
    %   Have pure set operations methods. Return only keys.
    %       CON: Set operations methods not needed since too simple: union, intersection, diff, xor
    %       .subset/.keep(keySet)     % Remove unmentioned keys. Keep sorting.
    %       .subset/.keep(iList)      % Remove unmentioned keys. Keep/set sorting?
    %   Have pure assignment/read methods specifying only string keys.
    %       ? .assign(keySet, values)    % Assign subset of preexisting keys. Keep ordering
    %       ? .assign(iList,   values)   % Assign subset of preexisting keys. Keep/set sorting?
    %   Have pure ordering method(s), specifying only keys.
    %   CON: Inefficient implementing algorithms which could be done with indices.
    %       NOTE: Indices change when adding/removing keys and reordering.
    %       CON: Premature optimization
    %   PROPOSAL: Methods with index arguments.
    %
    % PROPOSAL: Assert that submitted KVPL arguments are of this same class.
    %   PRO: Can find old usages of obsoleted KVPL data struct.
    %   CON: Will generate error for mixed use of Lapdog & private KVPL2 class instances.
    %       Ex: create_E2C2D2 calls EJ_library.ro.create_OBJTABLE_LBL_file which calls
    %           LblData.HeaderKvpl = LblData.HeaderKvpl.overwrite_subset(T2pkKvpl);
    %           with mixed KVPL2 versions.
    %       PROPOSAL: Specify assertions which permit both *.util.KVPL2.
    %           Obfuscate package names (.e.g with strrep) to prevent string replacement when syncing files.
    %           CON: Overkill.
    %       CON-PROPOSAL: Separate Lapdog and private code so that this never happens.
    %   CON: Overkill.
    %       CON: Assertions are meant to find unexpected use. --> Find errors early in execution.
    %
    % PROPOSAL: Some kind of merge/combine/append_*/join/~union method that combines two KVPLs while asserting that
    %   intersection of keys have the same values.
    %   NOTE: There (probably) is no method that asserts that values are identical, except for "equals".
    %   NOTE: Combines set operation (assertion for state of non-zero intersection) and list operation (order matters).
    %   PROPOSAL: append_diff. Appends Kvpl1.append(Kvpl2.diff(Kvpl2.keys)) assuming that the intersection is identical in keys AND values (but not ordering).
    %       NOTE: Can not prepend.
    %       Ex: create_EST_prel_LBL_header.
    %           Int1Kvpl = Kvpl1.intersection(Kvpl2.keys);
    %           Int2Kvpl = Kvpl2.intersection(Kvpl1.keys);
    %           % ASSERTION: Intersection of keys also have the same values.
    %           if ~Int1Kvpl.equals(Int2Kvpl)
    %               error('ERROR: Does not know what to do with LBL/ODL key collision for "%s"\n', estTabPath)
    %           end
    %           EstHeaderKvpl = Kvpl1.append(Kvpl2.diff(Kvpl1.keys));    % NOTE: Removes intersection of keys, assuming that it is identical anyway.
    %       PROBLEM: Name "append_diff" still bad since it does not refer to intersection. Is not just a diff.
    %           PROPOSAL: overwrite_append (overwrite_prepend).
    %
    % PROPOSAL: diff-like method with assertion on keys being a subset.
    %   PROPOSAL: Name "diff_subset" analogous to "overwrite_subset" (vs "overwrite_intersection").
    %
    % PROPOSAL: Method for removing keys by regexp.
    %   PRO: Used thrice in createLBL.definitions.
    %
    % PROPOSAL: Method set_append_kvp which overwrites existing value if key exist, otherwise adds key+value.
    %   NOTE: Compare set_value, append_kvp.
    
    
    
    properties(SetAccess=private,GetAccess=public)
        keys      % Must be column vector.
        values    % Must be column vector.
    end
    
    
    
    methods(Access=public)
        
        % Constructor
        %
        % ARGUMENTS
        % =========
        % varargin :
        %   alt 1:      Initialize empty KVPL.
        %       (0 arguments)
        %   alt 2:
        %       kvplContentCellArray : Nx2 cell array of strings.
        %                        kvplContentCellArray{iRow,1} = key
        %                        kvplContentCellArray{iRow,2} = value
        %   alt 3:
        %       keys   : Nx1 cell array of strings.
        %       values : Nx1 cell array.
        %   
        function obj = KVPL2(varargin)
            import EJ_library.utils.*

            %===============
            % Assign fields
            %===============
            if nargin == 0
                obj.keys   = cell(0,1);
                obj.values = cell(0,1);
                
            elseif (nargin == 1) && iscell(varargin{1})                
                kvplContentCellArray = KVPL2.normalize_empty(varargin{1}, cell(0,2));
                
                % ASSERTION
                if size(kvplContentCellArray,2) ~= 2
                    error('Illegal size of cell array.')
                end
                
                obj.keys   = kvplContentCellArray(:,1);
                obj.values = kvplContentCellArray(:,2);
                
            elseif nargin == 2
                v1 = varargin{1};
                v2 = varargin{2};
                
                % ASSERTIONS
                EJ_library.utils.assert.vector(v1)
                EJ_library.utils.assert.vector(v2)
                
                % Normalize 0x0
                v1 = KVPL2.normalize_empty(v1, cell(0,1));
                v2 = KVPL2.normalize_empty(v2, cell(0,1));
                
                % Force column vectors.
                obj.keys   = v1(:);
                obj.values = v2(:);
            else
                error('Illegal argument(s).')
            end
            
            
            
            % ASSERTIONS: Check fields.
            assert.castring_set(obj.keys)
            if size(obj.keys, 2) ~= 1
                error('obj.keys is not a column vector.')
            end
            if size(obj.values, 2) ~= 1
                error('obj.values is not a column vector.')
            end
            if numel(obj.keys) ~= numel(obj.values)
                error('obj.keys and obj.values do not have identical size.')
            end
        end
        


        function isEmpty = isempty(obj)
            isEmpty = isempty(obj.keys);
        end



        % Check if object equals other KVPL.
        %
        % policy : String
        function eq = equals(obj, Kvpl2, policy)
            % PROPOSAL: Shorthand methods instead of policy. equals_cko, equals_iko            
            % PROPOSAL: Policy for just comparing keys, in and out of order.
            
            %EJ_library.utils.assert.isa(Kvpl2, 'EJ_library.utils.KVPL2')
            
            if numel(obj.keys) ~= numel(Kvpl2.keys)
                eq = false;
                return
            end
            
            switch(policy)
                case 'consider key order'
                    if any(~strcmp(obj.keys, Kvpl2.keys))
                        eq = false;
                        return
                    end
                case 'ignore key order'
                    ;
                otherwise
                    error('Illegal policy argument.')
            end

            [keysSorted1, iSort1] = sort(obj.keys);
            [keysSorted2, iSort2] = sort(Kvpl2.keys);

            if any(~strcmp(keysSorted1, keysSorted2))
                eq = false;
                return
            end

            eq = all(strcmp(obj.values(iSort1), Kvpl2.values(iSort2)));
        end
        
        
        
        % ASSERTION: key must pre-exist (otherwise method would be called append_*).
        % NOTE: Compare "append_kvp"
        function Kvpl = set_value(obj, key, value)
            i = find(strcmp(key, obj.keys));
    
            % ASSERTION
            if length(i) ~= 1
                error('obj does not contain the specified key="%s".', key)
            end
            
            obj.values{i} = value;
            Kvpl = EJ_library.utils.KVPL2(obj.keys, obj.values);
        end



        % ASSERTION: key must pre-exist.
        function value = get_value(obj, key)
            i = find(strcmp(key, obj.keys));
    
            % ASSERTION
            if length(i) ~= 1
                error('obj does not contain the specified key="%s".', key)
            end
            
            value = obj.values{i};
        end
        
        
        
        % Remove keys from KVPL. Does not require keySet to be a subset of keys.
        % Keeps ordering.
        %
        % NOTE: Complements obj.intersection.
        % NOTE: Named after the set operation "difference". Could also be thought of as "delete_keys".
        function Kvpl = diff(obj, keySet)
            % PROPOSAL: Rename "difference", remove_intersection
            import EJ_library.utils.*
            
            assert.castring_set(keySet)
            [diffKeyList, iDiff] = setdiff(obj.keys, keySet);
            
            Kvpl = KVPL2(...
                obj.keys(iDiff), ...
                obj.values(iDiff));
        end
        
        

        % Only keep specified keys in KVPL. Does not require keySet to be a subset of keys.
        % Keeps ordering.
        %
        % NOTE: Complements obj.diff.
        % NOTE: Named after the set operation. Could also be thought of as "keep_keys", "remove_all_keys_except".
        function Kvpl = intersection(obj, keySet)
            [intKeysList, iInt, junk] = intersect(obj.keys, keySet);
            
            Kvpl = EJ_library.utils.KVPL2(...
                obj.keys(iInt), ...
                obj.values(iInt));
        end
        
        
        
        function Kvpl = subset(obj, keySubset)
            % ASSERTION
            diffKeySet = setdiff(keySubset, obj.keys);
            if numel(diffKeySet) > 0
                error('keySubset does not represent a subset of obj.keys.')
            end

            Kvpl = obj.intersection(keySubset);
        end



        % NOTE: No "prepend" method/policy since that can be achieved by exchanging the object and argument.
        % ASSERTION: No intersection of key sets.
        function Kvpl = append(obj, Kvpl)
            import EJ_library.utils.*
            
            %assert.isa(Kvpl, 'EJ_library.utils.KVPL2')
            
            Kvpl = KVPL2(...
                [obj.keys; Kvpl.keys], ...
                [obj.values; Kvpl.values]);   % NOTE: Constructor asserts unique keys.
        end
        
        
        
        % NOTE: To copy a key-value from a KVPL, use Kvpl = Kvpl.append(Kvpl.subset({key}))
        % ASSERTION: No intersection of key sets.
        function Kvpl = append_kvp(obj, key, value)
            % IMPLEMENTATION NOTE: In order to value==string AND value==cell array (or at least when empty, or size 1x1), a
            % merger [obj.values(:); value] does not work as expected.
            % Ex: value == {} ==> Does not increase size of ".keys".
            % IMPLEMENTATION NOTE: {obj.values{:}; value} does not work. Must instead merge a row
            % vector (for some reason) and then transpose.
            Kvpl = EJ_library.utils.KVPL2(...
                [obj.keys;   key], ...
                [obj.values; {value}]);
        end
        
        
        
        % For the intersection of keys, assign obj values with values from KvplSrc.
        % obj and Kvpl will have the same set of keys, in the same order.
        function Kvpl = overwrite_intersection(obj, KvplSrc)
            % PROPOSAL: Better name to better reflect meaning.
            %   PROPOSAL: copy_from_intersection, replace/substitute_values_from, replace, replace_intersection,
            %             overwrite_intersection
            import EJ_library.utils.*
            %assert.isa(KvplSrc, 'EJ_library.utils.KVPL2')
            
            [intKeysList, iInt, jInt] = intersect(obj.keys, KvplSrc.keys);            
            obj.values(iInt) = KvplSrc.values(jInt);
            
            Kvpl = KVPL2(obj.keys, obj.values);
        end



        % For the subset of keys, assign obj values with values from KvplSubsetSrc.
        % Like overwrite_intersection, except that KvplSubsetSrc must have keys which are a subset of obj.keys.
        %
        % obj and Kvpl will have the same set of keys, in the same order.
        function Kvpl = overwrite_subset(obj, KvplSubsetSrc)
            % PROPOSAL: Better name to better reflect meaning.
            %   PROPOSAL: copy_from_subset, replace/substitute_values_from, replace, replace_subset,
            %             overwrite_subset

            % ASSERTION
            %EJ_library.utils.assert.isa(KvplSubsetSrc, 'EJ_library.utils.KVPL2')     % Also in overwrite_intersection.
            diffKeySet = setdiff(KvplSubsetSrc.keys, obj.keys);
            if numel(diffKeySet) > 0
                error('KvplSubsetSrc does not represent a subset of obj.keys.')
            end

            Kvpl = obj.overwrite_intersection(KvplSubsetSrc);
        end



        % Order key-value pairs according to a list of keys.
        % Remaining key-value pairs will be added at the end in their previous internal order.
        %
        %
        % ARGUMENTS
        % =========
        % keyOrderList   : Cell array of unique strings.
        %                  NOTE: Does not assume any relationship between obj.keys and keyOrderList
        %                  (either may contain elements not existing in the other).
        % unsortedPolicy : String.
        %   'sorted-unsorted'
        %   'unsorted-sorted'
        %
        function Kvpl = reorder(obj, keyOrderList, unsortedPolicy)
            % PROPOSAL: Policy for relationship between obj.keys and keyOrderList.
            %   Assert keyOrderList is subset of obj.keys.
            %   Assert obj.keys     is subset of keyOrderList.
            %   Assert obj.keys     and          yOrderList    are identical (except for order).
            
            import EJ_library.utils.*

            % ASSERTION
            assert.castring_set(keyOrderList)
            
            % NORMALIZATION
            keyOrderList = keyOrderList(:);   % Force column vector. Row/column otherwise influences iOrdered.

            % Derive iOrdered.
            [junk, iOrdered] = ismember(keyOrderList, obj.keys);
            iOrdered = iOrdered(find(iOrdered));   % Remove zeros. "find" can not be removed despite MATLAB's suggestion.
            
            % Derive iUnsorted = Indices into obj.keys that are not already in iOrdered.
            % NOTE: Want to keep the original order.
            hasNoNewLocation           = ones(size(obj.keys));
            hasNoNewLocation(iOrdered) = 0;
            iUnsorted = find(hasNoNewLocation);
            
            switch(unsortedPolicy)
                case 'sorted-unsorted'
                    iOrderTot = [iOrdered; iUnsorted];
                case 'unsorted-sorted'
                    iOrderTot = [iUnsorted; iOrdered];
                otherwise
                    error('Illegal argument unsortedPolicy="%s"', unsortedPolicy)
            end
            
            % ASSERTION: Internal consistency check.
            if (length(iOrderTot) ~= length(obj.keys)) || any(sort(iOrderTot) ~= (1:length(obj.keys))')
                error('ERROR: Likely bug in algorithm');
            end
            
            Kvpl = KVPL2(obj.keys(iOrderTot), obj.values(iOrderTot));
        end
        
    end    % methods(Access=public)
    
    
    
    methods(Static, Access=private)
        
        % Internal helper function
        % NOTE: Only replaces a 0x0x0x... array to be able to have assertions give error on e.g. 0x6 normalized format is Nx2.
        function v = normalize_empty(v, emptyReplacement)
            if isequal(size(v), [0,0])
            %if ~any(size(v))
                v = emptyReplacement;
            end
        end
        
    end    % methods(Access=private)
end    % classdef
