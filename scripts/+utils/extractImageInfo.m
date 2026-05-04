function [age, kv, mas] = extractImageInfo(str)

    % Extract age (before YRS)
    age_token = regexp(str, '(\d+)\s*YRS', 'tokens');
    if ~isempty(age_token)
        age = str2double(age_token{1}{1});
    else
        age = NaN;
    end

    % Extract kV (before KV) - now supports decimals
    kv_token = regexp(str, '(\d+\.?\d*)\s*KV', 'tokens');
    if ~isempty(kv_token)
        kv = str2double(kv_token{1}{1});
    else
        kv = NaN;
    end

    % Extract mAs (before mAs)
    mas_token = regexp(str, '(\d+\.?\d*)\s*mAs', 'tokens');
    if ~isempty(mas_token)
        mas = str2double(mas_token{1}{1});
    else
        mas = NaN;
    end

end