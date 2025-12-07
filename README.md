# 🎨 RGB to Grayscale Approximation (RGB2GRAY) with Sums of Powers of Two

This project implements an optimized **RGB color to Grayscale** image conversion suitable for **hardware** (FPGA or ASIC) using approximations based on **sums of powers of two** and a dedicated mechanism for **remainder handling**.

## 🌟 Project Goal

The primary goal was to develop an efficient RGB2GRAY conversion algorithm that could be implemented using only **right shift** and **addition** operations, thereby avoiding costly multiplications. This was achieved by approximating the standard luminance coefficients to the closest values expressible as sums of $1/2^n$ fractions.

---

## ⚙️ Formula and Approximation

The standard formula for grayscale conversion is:

$$
\text{Gray}_{\text{pixel}} = 0.299 \cdot \text{Pix}_R + 0.587 \cdot \text{Pix}_G + 0.114 \cdot \text{Pix}_B
$$

For hardware optimization, the coefficients were approximated as sums of powers of two:

| Channel | Real Coefficient | Approximation (Sum of Powers of Two) | Approximated Value | Estimation Error |
| :---: | :---: | :---: | :---: | :---: |
| **Red (R)** | 0.299 | $\frac{1}{4} + \frac{1}{32} + \frac{1}{64}$ | 0.296875 | 0.2125% (underestimation)|
| **Green (G)** | 0.587 | $\frac{1}{2} + \frac{1}{16} + \frac{1}{64} + \frac{1}{128}$ | 0.5859375 | 0.10625% (underestimation) |
| **Blue (B)** | 0.114 | $\frac{1}{16} + \frac{1}{32} + \frac{1}{64} + \frac{1}{128}$ | 0.1171875 | 0.31875% (overestimation) |

**Important Note:** The sum of the real coefficients ($0.299 + 0.587 + 0.114$) equals **1**, as does the sum of the power-of-two approximations.

---

## 🧮 Remainder Handling

The shift-only approach inherently introduces an error due to **truncation** (simply cutting the vector) of the results. The purpose of remainder handling is to correct the resulting approximation error through an analysis of the remainder bits.

**Core Concept:**
The method does not discard the remainder bits; instead, it saves them, shifts them into a dedicated vector, and sums them together. This summation of fractional remainders (e.g., $0.5 + 0.4 + 0.2 = 1.1$) determines whether an integer carry (`+1`) should be added to the final calculation.

This process is implemented using logic operations that extract the remainder (the least significant bits lost during the shift) and realign them for subsequent summation.

---

## ⚡ Results and Performance

The final implementation demonstrated high performance with optimized resource utilization:

* **Pipeline Stages:** 10 total pipeline stages.
* **Clock Period:** Operates at a **2.9 ns** clock period.
* **Hardware Used:** Only a few pipeline registers, **seven 8-bit Carry-save** (four-operand) and **two 8-bit Adders**.
* **Accuracy:** The error on any given pixel remains between **-1 and +1**.

---

## 👤 Author

**Raffaele Petrolo**
