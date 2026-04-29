function [metrics, C] = compute_binary_metrics(y_true, y_pred)
% Binary metrics for:
%   class 0 = original
%   class 1 = recording

    % Confusion matrix with fixed order
    C = confusionmat(y_true, y_pred, 'Order', [0 1]);

    % Rows = true, Cols = pred
    % C = [TN FP
    %      FN TP]
    TN = C(1,1);
    FP = C(1,2);
    FN = C(2,1);
    TP = C(2,2);

    metrics.accuracy = (TP + TN) / max(TP + TN + FP + FN, eps);
    metrics.precision = TP / max(TP + FP, eps);
    metrics.recall = TP / max(TP + FN, eps);
    metrics.f1 = 2 * metrics.precision * metrics.recall / max(metrics.precision + metrics.recall, eps);
    metrics.specificity = TN / max(TN + FP, eps);
    metrics.balanced_accuracy = (metrics.recall + metrics.specificity) / 2;

    metrics.TP = TP;
    metrics.TN = TN;
    metrics.FP = FP;
    metrics.FN = FN;
end