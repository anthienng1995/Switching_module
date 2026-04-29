%function results = benchmark_original_recording_module()
% Benchmark original vs recording classification module
%
% Folder structure:
% D:\dataset\ReplayDF\
%   ├── original\   (many nested subfolders)
%   └── recording\  (many nested subfolders)
%
% Ground truth:
%   original  -> 0
%   recording -> 1
%
% You must implement:
%   [pred_label, score] = my_original_recording_classifier(wav_path)
%
% where:
%   pred_label = 0 for original, 1 for recording
%   score      = confidence for recording class (higher => more likely recording)
    clear all;
    clc;
    threshold = 0.63

    % ===== Dataset roots =====
    dataset_root   = 'D:\dataset\ReplayDF';
    original_root  = fullfile(dataset_root, 'original');
    recording_root = fullfile(dataset_root, 'recording');

    % ===== Output =====
    out_dir = fullfile(dataset_root, 'benchmark_results');
    if ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end

    % ===== Scan wav files recursively =====
    fprintf('Scanning original files...\n');
    orig_files = list_all_wavs_recursive(original_root);

    fprintf('Scanning recording files...\n');
    rec_files  = list_all_wavs_recursive(recording_root); 

    n_orig = numel(orig_files);
    n_rec  = numel(rec_files);
    n_total = n_orig + n_rec;

    fprintf('Found %d original files\n', n_orig);
    fprintf('Found %d recording files\n', n_rec);
    fprintf('Total %d files\n', n_total);

    % ===== Build file list and labels =====
    all_files = [orig_files; rec_files];
    y_true = [zeros(n_orig,1); ones(n_rec,1)];

    % ===== Preallocate =====
    y_pred = nan(n_total,1);
    y_score = nan(n_total,1);    % score for recording class
    y_ratio = nan(n_total,1);
    status = strings(n_total,1);

    % ===== Run classifier =====
    fprintf('\nRunning classifier...\n');

    for i = 1:n_total
        wav_path = all_files{i};

        try
            [pred_label, score, ratio] = my_original_recording_classifier(wav_path);

            % sanity
            if ~(isequal(pred_label,0) || isequal(pred_label,1))
                error('pred_label must be 0 or 1.');
            end

            y_pred(i) = pred_label;
            y_score(i) = score;
            y_ratio(i) = ratio;
            status(i) = "ok";

        catch ME
            warning('Error on file %d/%d: %s\n%s', i, n_total, wav_path, ME.message);
            status(i) = "error";
        end

        if mod(i,100)==0 || i==n_total
            fprintf('Processed %d / %d\n', i, n_total);
        end
    end

    % ===== Keep only successful files =====
    valid = strcmp(status, "ok") & ~isnan(y_pred);
    all_files_valid = all_files(valid);
    y_true_valid = y_true(valid);
    y_pred_valid = y_pred(valid);
    y_score_valid = y_score(valid);
    y_ratio_valid = y_ratio(valid);

    fprintf('\nValid files: %d / %d\n', numel(y_true_valid), n_total);

    % ===== Metrics =====
    [metrics, C] = compute_binary_metrics(y_true_valid, y_pred_valid);

    % ===== Save per-file results =====
    T = table(string(all_files_valid), y_true_valid, y_pred_valid, y_score_valid, ...
        'VariableNames', {'file_path', 'true_label', 'pred_label', 'score_recording'});
    writetable(T, fullfile(out_dir, 'per_file_predictions.csv'));

    % ===== Save summary =====
    summary_file = fullfile(out_dir, 'summary.txt');
    fid = fopen(summary_file, 'w');

    fprintf(fid, '===== ORIGINAL vs RECORDING BENCHMARK =====\n\n');
    fprintf(fid, 'Dataset root      : %s\n', dataset_root);
    fprintf(fid, 'Original root     : %s\n', original_root);
    fprintf(fid, 'Recording root    : %s\n\n', recording_root);

    fprintf(fid, 'Num original      : %d\n', n_orig);
    fprintf(fid, 'Num recording     : %d\n', n_rec);
    fprintf(fid, 'Num valid         : %d\n\n', numel(y_true_valid));

    fprintf(fid, 'Confusion Matrix (rows=true, cols=pred)\n');
    fprintf(fid, '            Pred Original   Pred Recording\n');
    fprintf(fid, 'True Original   %8d        %8d\n', C(1,1), C(1,2));
    fprintf(fid, 'True Recording  %8d        %8d\n\n', C(2,1), C(2,2));

    fprintf(fid, 'Accuracy         : %.6f\n', metrics.accuracy);
    fprintf(fid, 'Precision        : %.6f\n', metrics.precision);
    fprintf(fid, 'Recall           : %.6f\n', metrics.recall);
    fprintf(fid, 'F1-score         : %.6f\n', metrics.f1);
    fprintf(fid, 'Specificity      : %.6f\n', metrics.specificity);
    fprintf(fid, 'Balanced Accuracy: %.6f\n', metrics.balanced_accuracy);

    orig_ratio = y_ratio_valid(y_true_valid==0);
    rec_ratio  = y_ratio_valid(y_true_valid==1);
    
    fprintf('Original ratio:  mean=%.6f, std=%.6f, min=%.6f, max=%.6f\n', ...
        mean(orig_ratio), std(orig_ratio), min(orig_ratio), max(orig_ratio));
    
    fprintf('Recording ratio: mean=%.6f, std=%.6f, min=%.6f, max=%.6f\n', ...
        mean(rec_ratio), std(rec_ratio), min(rec_ratio), max(rec_ratio));

    if ~all(isnan(y_score_valid))
        try
            [Xroc, Yroc, ~, AUC] = perfcurve(y_true_valid, y_score_valid, 1);
            fprintf(fid, 'AUC              : %.6f\n', AUC);

            fig = figure('Color','w');
            plot(Xroc, Yroc, 'LineWidth', 2);
            xlabel('False Positive Rate');
            ylabel('True Positive Rate');
            title(sprintf('ROC Curve (AUC = %.4f)', AUC));
            grid on;
            saveas(fig, fullfile(out_dir, 'roc_curve.png'));
            close(fig);
        catch
            fprintf(fid, 'AUC              : failed to compute\n');
        end
    else
        fprintf(fid, 'AUC              : not available (score missing)\n');
    end

    % ===== Confusion matrix figure =====
    fig = figure('Color','w');
    cm = confusionchart(categorical(y_true_valid,[0 1],{'Original','Recording'}), ...
                        categorical(y_pred_valid,[0 1],{'Original','Recording'}), ...
        'RowSummary','row-normalized', ...
        'ColumnSummary','column-normalized');
    cm.Title = 'Original vs Recording Confusion Matrix';
    cm.XLabel = 'Predicted Class';
    cm.YLabel = 'True Class';
    saveas(fig, fullfile(out_dir, 'confusion_matrix.png'));

    % ===== Histogram =====
    fig = figure('Color','w');
    histogram(orig_ratio, 50, 'Normalization', 'probability');
    hold on;
    histogram(rec_ratio, 50, 'Normalization', 'probability');
    hold off;
    legend('original','recording','Location','best');
    xlabel('ratio');
    ylabel('Probability');
    title('Histogram of ratio feature');
    grid on;

    % ===== Console summary =====
    fprintf('\n===== RESULTS =====\n');
    fprintf('Accuracy          : %.4f\n', metrics.accuracy);
    fprintf('Precision         : %.4f\n', metrics.precision);
    fprintf('Recall            : %.4f\n', metrics.recall);
    fprintf('F1-score          : %.4f\n', metrics.f1);
    fprintf('Specificity       : %.4f\n', metrics.specificity);
    fprintf('Balanced Accuracy : %.4f\n', metrics.balanced_accuracy);
    fprintf('Saved results to: %s\n', out_dir);

    % return
    results.metrics = metrics;
    results.confusion_matrix = C;
    results.output_dir = out_dir;
%end