function file_list = list_all_flacs_recursive(root_dir)
% Recursively list all wav files under root_dir

    D = dir(fullfile(root_dir, '**', '*.flac'));
    file_list = cell(numel(D),1);

    for i = 1:numel(D)
        file_list{i} = fullfile(D(i).folder, D(i).name);
    end
end