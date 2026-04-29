# Switching Module for Replay Attack Detection

## 📌 Overview

This repository implements an artifact-guided switching module for replay attack detection.

The main idea is:
- Extract spectrogram-based artifacts using vertical filtering
- Compute an artifact score for each audio sample
- Use a threshold to classify samples as **original-like** or **recording-like**
- Split datasets accordingly to improve detection performance

The pipeline supports:
- ReplayDF dataset
- RIRplay dataset
- Mixed dataset for generalization

---

## 📂 File Description

### 🔹 Core Scripts

- `my_original_recording_classifier.m`  
  → Main function to compute artifact score and classify a single audio file

---

### 🔹 Benchmark & Threshold Estimation

- `benchmark_sw_for_ReplayDF.m`  
  → Run artifact extraction + histogram + threshold estimation for ReplayDF

- `benchmark_sw_for_RIRplay.m`  
  → Same as above but for RIRplay

---

### 🔹 Dataset Construction (Switching)

- `Creating_ReplayDF_with_SW.m`  
  → Create `ReplayDF_with_SW` dataset using the estimated threshold

- `Creating_RIRplay_with_SW.m`  
  → Create `RIRplay_with_SW` dataset

---

### 🔹 Utilities

- `compute_binary_metrics.m`  
  → Compute evaluation metrics (Accuracy, F1-score)

- `list_all_wavs_recursive.m`  
  → Recursively scan all `.wav` files in subfolders

- `list_all_flacs_recursive.m`  
  → Recursively scan all `.flac` files in subfolders

---

## ⚙️ What This Repo Does

1. Analyze spectrogram artifacts caused by replay
2. Separate audio into two groups:
   - original-like
   - recording-like
3. Build new datasets using switching strategy
4. Support evaluation with deepfake detection models

---

## 🎯 Purpose

- Improve replay attack detection
- Provide a simple but effective switching mechanism
- Enable cross-dataset generalization experiments
