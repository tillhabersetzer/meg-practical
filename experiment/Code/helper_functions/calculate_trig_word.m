function [decimal_trigger_word, bitmask] = calculate_trig_word(trigger_ids, bit_split, bit_ref)
%--------------------------------------------------------------------------
% Author: Till Habersetzer
%         Carl von Ossietzky University Oldenburg
%         till.habersetzer@uol.de
%
% CALCULATE_TRIG_WORD Calculates a decimal trigger word from binary trigger IDs.
%
% This function handles both single and multiple trigger IDs. It converts
% binary trigger IDs into a decimal representation while ensuring proper bit
% allocation and error checking.
%
% Args:
%     trigger_ids (numeric array): 
%         The integer trigger ID (for a single trigger) 
%         or an array of integer trigger IDs (for multiple triggers).
%     bit_split (numeric array, optional): 
%         If `trigger_ids` is an array, this array defines the number of bits 
%         allocated to each trigger ID. Defaults to [] (assumes all bits).
%     bit_ref (int, optional): 
%         Total number of reference bits (e.g., 16 for MEG). Defaults to 16.
%
% Returns:
%     decimal_trigger_word (double): The calculated decimal trigger word.
%     bitmask (char array): The binary representation of the trigger word.
%
% Examples:
%     1. Single trigger using defaults (bit_ref = 16)
%     [word, mask] = calculate_trig_word(1);
%     Returns: word = 0.5000, mask = '0000000000000001'
%
%     2. Multiple triggers with specific bit splits
%     trigger_ids = [3, 3, 3];
%     bit_split = [3, 3, 5];
%     [word, mask] = calculate_trig_word(trigger_ids, bit_split, 16);
%     Returns: word =  0.7764, mask = '0000001101100011'
%--------------------------------------------------------------------------

arguments
    trigger_ids (1,:) {mustBeInteger, mustBeNonnegative}
    bit_split (1,:) {mustBeInteger, mustBePositive} = []
    bit_ref (1,1) {mustBeInteger, mustBePositive} = 16
end

% Default bit_split to bit_ref if not provided
if isempty(bit_split)
    bit_split = bit_ref;
end

% Check if lengths match 
if length(trigger_ids) ~= length(bit_split) && length(bit_split) > 1
    error('calculate_trig_word:LengthMismatch', ...
          'Length of trigger_ids and bit_split must match.');
end

% Check if total requested bits exceed reference bits
if sum(bit_split) > bit_ref
    error('calculate_trig_word:InsufficientBits', ...
          'Insufficient reference bits (%d) for requested bit split.', bit_ref);
end

bitmask = ''; % Initialize binary bitmask

for trig_idx = 1:length(trigger_ids)
    trigger_id = trigger_ids(trig_idx);
    num_bits   = bit_split(trig_idx);
    
    % Check if bits are enough for this ID
    if trigger_id > (2^num_bits - 1)
        error('calculate_trig_word:ExceedsBits', ...
              'Trigger ID %d requires more than %d bits', trigger_id, num_bits);
    end
    
    % Convert to binary with padding and append
    bitmask = [bitmask, dec2bin(trigger_id, num_bits)];
end

% Pad with leading zeros if needed to reach bit_ref length
pad_length = bit_ref - length(bitmask);
if pad_length > 0
    bitmask = [repmat('0', 1, pad_length), bitmask];
end

% Convert binary bitmask to decimal trigger word
% flip string left / right - bit order is reversed
reversed_bitmask     = bitmask(end:-1:1);
decimal_trigger_word = bin2dec(reversed_bitmask) / (2^bit_ref);

end