%% Setup
clear; clc; warning off;

new_folder = "ReplayDF_with_SW";   % changing name for other handling
output_root = "D:\dataset\Our_Handle_dataset\" + new_folder + "\";
source_root = "D:\dataset\ReplayDF\";   % recording

mkdir(output_root);
mkdir(output_root + "original_sw\");
mkdir(output_root + "recording_sw\");

Preprocess = @calculating_sw_score;
postfix = "";

all_source_files = dir(fullfile(source_root, '**', '*.wav'));
L = numel(all_source_files);

%% ================================================================
% Handle all recording dataset
%% ================================================================
textProgressBar(0, L, 'Processing:');

for ct = 1:L
    source_file = fullfile(all_source_files(ct).folder, all_source_files(ct).name);

    [~, name, ext] = fileparts(source_file);
    [y, Fs] = audioread(source_file);
    y = mean(y, 2);

    out = Preprocess(y, Fs);

    % Lấy đường dẫn tương đối so với source_root
    relative_folder = erase(string(all_source_files(ct).folder), string(source_root));

    % Bỏ dấu "\" đầu nếu có
    if strlength(relative_folder) > 0 && startsWith(relative_folder, "\")
        relative_folder = extractAfter(relative_folder, 1);
    end

    % Chọn root đích theo score
    if out >= 0.632
        dest_folder = output_root + "original_sw\" + relative_folder;
    else
        dest_folder = output_root + "recording_sw\" + relative_folder;
    end

    % Tạo lại subfolder nếu chưa có
    if ~exist(dest_folder, 'dir')
        mkdir(dest_folder);
    end

    % Đường dẫn file đích
    dest_file = fullfile(dest_folder, name + postfix + ext);

    % Copy file gốc sang thư mục mới
    copyfile(source_file, dest_file);

    textProgressBar(ct, L, 'Processing:');
end

function textProgressBar(current, total, message)
    persistent lastLength;

    if isempty(lastLength)
        lastLength = 0;
    end

    fprintf(repmat('\b', 1, lastLength));

    totalBarLength = 30;
    percentage = (current / total) * 100;
    barLength = floor(percentage * totalBarLength / 100);
    bar = ['[', repmat('=', 1, barLength), repmat(' ', 1, totalBarLength - barLength), ']'];

    outputString = sprintf('%s %s %d%%', message, bar, round(percentage));
    fprintf('%s', outputString);

    lastLength = length(outputString);

    if current >= total
        fprintf('\n');
        lastLength = 0;
    end
end