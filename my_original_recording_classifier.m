function [pred_label, score, ratio] = my_original_recording_classifier(wav_path,threshold)
% pred_label:
%   0 = original
%   1 = recording
%
% score:
%   higher => more likely recording

    % ===== 1) Read audio =====
    [x, fs] = audioread(wav_path);
    
    if size(x,2) > 1
        x = mean(x, 2);
    end
    
    x = double(x(:));
    
    % ===== Resample để giảm ảnh hưởng khác sampling rate =====
    target_fs = 22050;
    
    if fs ~= target_fs
        x = resample(x, target_fs, fs);
        fs = target_fs;
    end
    
    x = x - mean(x);
    
    mx = max(abs(x));
    if mx > 0
        x = x / mx;
    end

    % ===== 2) Spectrogram parameters =====
    win_len = round(0.032 * fs);   % 32 ms
    hop_len = round(0.010 * fs);   % 10 ms
    % nfft    = 1024;
    % win_len = max(win_len, 16);

    nfft = 2^nextpow2(win_len);
    win = hann(win_len, 'periodic');

    % if nfft < win_len
    %     nfft = 2^nextpow2(win_len);
    % end

    % win = hamming(win_len, 'periodic');
    % overlap = max(win_len - hop_len, 0);
    overlap = win_len-hop_len;

    % ===== 3) Compute spectrogram =====
    [S, Freq, ~] = spectrogram(x, win, overlap, nfft, fs);
    % [S,F,T] = melSpectrogram(x, fs, ...
    % 'WindowLength', 1024, ...
    % 'OverlapLength', 512, ...
    % 'FFTLength', 1024, ...
    % 'NumBands', 128);

    S_mag = abs(S);
    S_log = log(S_mag + 1e-10);

    % ===== 4) Define bands =====
    hf_band = (Freq >= 4000 & Freq <= min(8000, fs/2));
    lf_band = (Freq >= 0    & Freq < 2000);

    % fallback nếu fs thấp quá
    % if ~any(hf_band)
    %     hf_band = (Freq >= max(0, fs/4) & Freq <= fs/2);
    % end
    % if ~any(lf_band)
    %     lf_band = (Freq >= 0 & Freq <= min(2000, fs/4));
    % end

    % ===== 5) Vertical curvature in HF =====
    kv = [1; -2; 1];
    Sv = conv2(S_log, kv, 'same');
    % a = sqrt(mean(Sv(hf_band,:).^2, 'all'));
    a = mean(abs(Sv(:,:)), 'all');

    % ===== 6) Horizontal curvature in LF =====
    kh = [-1 0 1];
    Sh = conv2(S_log, kh, 'same');
    % b = sqrt(mean(Sh(lf_band,:).^2, 'all'));
    b = mean(abs(Sh(lf_band,:)), 'all');

    % ===== 7) Ratio =====
    % ratio = a * (b + eps);
    ratio = a;

    % ===== 8) Threshold =====

    if ratio < threshold
        pred_label = 1;   % recording
    else
        pred_label = 0;   % original
    end
    % pred_label = a;

    % Higher score => more likely recording
    score = threshold - ratio;
end