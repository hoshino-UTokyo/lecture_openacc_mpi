# lecture_openacc_mpi

東京大学情報基盤センター お試しアカウント付き講習会「OpenACCとMPIによるマルチGPUプログラミング入門」で使用しているサンプルコード(C, Fortran)です。
OpenACCとMPIを組み合わせて利用する方法が学べます。
Wisteria/BDEC-01 Aquariusノード向けのジョブスクリプトが含まれます。
講習会URL： https://www.cc.u-tokyo.ac.jp/events/lectures/


# Requirement

* NVIDA HPC SDK： https://developer.nvidia.com/nvidia-hpc-sdk-downloads

* OpenMPI 

  Wisteria/BDEC-01 には予めインストールされています。

# Usage

以下は全てWisteria/BDEC-01 Aquariusでの利用方法です。

```bash
module load nvidia ompi-cuda   # NVIDA HPC SDK, OpenMPIの環境構築。ログインの度必要です。
cd /work/グループ名/ユーザ名/  　#/home は計算ノードから参照できないので、/work以下で作業しましょう。
git clone https://github.com/hoshino-UTokyo/lecture_openacc_mpi.git
cd lecture_openacc_mpi/
cd C or F                      # C, Fortran好きな方を選んでください。
```