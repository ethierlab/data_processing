function params = parse_input_params(params, input_params)

param_names = fieldnames(params); %make case insensitive, all lowercase

if isempty(input_params)
    % use all default parameters
    return;
end

if isstruct(input_params{1})
    % input is a param structure, not a series of {'param name', param value} pairs
    inpNames = fieldnames(input_params{1});
    for i=1:numel(inpNames)
        if any(strcmpi(inpNames(i),param_names))
            params.(inpNames{i}) = input_params{1}.(inpNames{i});
        else
            error('%s is not a valid parameter name',inpNames{i});
        end
    end
    
else
    if mod(length(input_params),2)
        error('parse_input_params: Params should be provided in (''param_name'',param_value) pairs, or as a params structure')
    end
    
    for pair = reshape(input_params,2,[])
        inpName = lower(pair{1}); % make case insensitive
        
        if any(strcmpi(inpName,param_names))
            % overwrite options. If you want you can test for the right class here
            % Also, if you find out that there is an option you keep getting wrong,
            % you can use "if strcmp(inpName,'problemOption'),testMore,end"-statements
            params.(param_names{strcmpi(inpName,param_names)}) = pair{2};
            
        else
            error('%s is not a valid parameter name',inpName);
        end
    end
end
