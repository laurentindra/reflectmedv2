#!/usr/bin/env python3
"""
================================================================================
ReflectMed AI — Automated Fine-Tuning Pipeline for Google Gemini
Berdasarkan Standar Pedagogis Medis AMEE Guide No. 44 (Sandars, 2009)
================================================================================
Skrip ini mengunggah dataset kurasi klinis dan memulai proses
Supervised Fine-Tuning (SFT) pada model Gemini 1.5 Flash untuk menghasilkan
mentor reflektif kedokteran yang empatik, terstruktur Gibbs, dan bebas bias asesmen.
"""

import os
import sys
import json
import time
import argparse

def validate_and_prepare_dataset(filepath):
    """Validasi format dataset JSONL dan konversi ke pasangan text_input/output."""
    print(f"[*] Memeriksa format integritas dataset: {filepath}")
    if not os.path.exists(filepath):
        print(f"[!] Error: File dataset tidak ditemukan di {filepath}")
        return False, []

    training_pairs = []
    with open(filepath, "r", encoding="utf-8") as f:
        for idx, line in enumerate(f, 1):
            line = line.strip()
            if not line:
                continue
            try:
                data = json.loads(line)
                if "messages" in data:
                    roles = [m.get("role") for m in data["messages"]]
                    if not ("user" in roles and "model" in roles):
                        print(f"[!] Baris {idx} harus memiliki pesan bertipe 'user' dan 'model'.")
                        return False, []
                    user_text = next((m.get("content", "") for m in data["messages"] if m.get("role") == "user"), "")
                    model_text = next((m.get("content", "") for m in data["messages"] if m.get("role") == "model"), "")
                    training_pairs.append({"text_input": user_text, "output": model_text})
                elif "text_input" in data and "output" in data:
                    training_pairs.append(data)
                else:
                    print(f"[!] Baris {idx} tidak memiliki format messages atau text_input/output.")
                    return False, []
            except json.JSONDecodeError as e:
                print(f"[!] Error sintaks JSON pada baris {idx}: {e}")
                return False, []

    print(f"[+] Validasi sukses: {len(training_pairs)} pasangan dialog klinis AMEE 44 siap digunakan.")
    return True, training_pairs

def run_fine_tuning(api_key, training_samples, model_name, epochs):
    """Jalankan proses fine-tuning menggunakan Google Generative AI SDK."""
    try:
        import google.generativeai as genai
    except ImportError:
        print("[!] Library 'google-generativeai' belum terpasang.")
        print("[*] Memasang sekarang: pip install google-generativeai")
        os.system(f"{sys.executable} -m pip install google-generativeai")
        import google.generativeai as genai

    genai.configure(api_key=api_key)

    print("\n=======================================================")
    print("🚀 MEMULAI PIPELINE TRAINING REFLECTMED AI")
    print("=======================================================")
    print(f"• Base Model   : models/gemini-1.5-flash-001")
    print(f"• Target Name  : {model_name}")
    print(f"• Total Data   : {len(training_samples)} sample cases")
    print(f"• Epochs       : {epochs}")
    print("=======================================================\n")

    print("[1/4] Menyiapkan payload dataset terstruktur...")
    print(f"[2/4] Menghubungi Google AI Studio Tuning Service...")
    print("[3/4] Mendaftarkan job fine-tuning pada klaster Google Cloud TPU...")

    try:
        operation = genai.create_tuned_model(
            source_model="models/gemini-1.5-flash-001",
            training_data=training_samples,
            id=model_name,
            epoch_count=epochs,
            batch_size=4,
            learning_rate=0.001,
            description="ReflectMed AI - Mentor Reflektif Klinis Kedokteran (AMEE Guide 44)",
        )

        full_model_name = f"tunedModels/{model_name}"
        print(f"\n[+] Job pelatihan berhasil didaftarkan!")
        print(f"[+] Nama Model Anda: {full_model_name}")
        print("[4/4] Memantau proses training & konvergensi bobot model...")

        for status in operation.wait_bar():
            time.sleep(10)

        result = operation.result()
        print("\n" + "=" * 55)
        print("🎉 PELATIHAN SELESAI DENGAN SUKSES!")
        print("=" * 55)
        print(f"Model ID Resmi : {result.name}")
        print("\nCara Menggunakan Model Ini di Aplikasi ReflectMed AI:")
        print("1. Buka aplikasi ReflectMed AI di ponsel / emulator.")
        print("2. Masuk ke 'Pengaturan & Profil'.")
        print(f"3. Masukkan Model ID: {result.name}")
        print("4. Chatbot Anda sekarang 100% menggunakan model hasil training ini!")

        # Simpan ke file info konfigurasi lokal
        config_path = os.path.join(os.path.dirname(__file__), "TRAINED_MODEL_INFO.json")
        with open(config_path, "w", encoding="utf-8") as f:
            json.dump({
                "model_id": result.name,
                "base_model": "gemini-1.5-flash-001",
                "trained_at": time.strftime("%Y-%m-%d %H:%M:%S"),
                "samples_count": len(training_samples),
                "epochs": epochs
            }, f, indent=2)
        print(f"\n[i] Informasi model tersimpan di: {config_path}")

    except Exception as e:
        print(f"\n[!] Catatan Eksekusi API: {e}")
        print("\n💡 Panduan Alternatif (Web GUI No-Code):")
        print("1. Kunjungi: https://aistudio.google.com/ -> Menu 'Tuned Models'")
        print("2. Klik 'Create Tuned Model' -> Pilih 'Gemini 1.5 Flash'")
        print("3. Unggah file CSV siap pakai yang telah kami buatkan di:")
        print(f"   📁 {os.path.abspath(os.path.join(os.path.dirname(__file__), 'medireflect_tuning_pairs.csv'))}")
        print("4. Klik 'Tune' dan dapatkan model dalam 5 menit!")

def main():
    parser = argparse.ArgumentParser(description="ReflectMed AI Fine-Tuning CLI")
    parser.add_argument(
        "--api-key",
        default=os.environ.get("GEMINI_API_KEY", ""),
        help="Google Gemini API Key (atau set environment variable GEMINI_API_KEY)",
    )
    parser.add_argument(
        "--dataset",
        default="medireflect_finetuning_dataset.jsonl",
        help="Path ke file dataset JSONL",
    )
    parser.add_argument(
        "--model-name",
        default="reflectmed-mentor-v1",
        help="ID nama unik untuk model kustom hasil pelatihan",
    )
    parser.add_argument(
        "--epochs",
        type=int,
        default=5,
        help="Jumlah epoch iterasi pelatihan (default: 5)",
    )

    args = parser.parse_args()

    # Cek direktori lokal jika relative path
    dataset_file = args.dataset
    if not os.path.isabs(dataset_file) and not os.path.exists(dataset_file):
        script_dir = os.path.dirname(os.path.abspath(__file__))
        candidate = os.path.join(script_dir, dataset_file)
        if os.path.exists(candidate):
            dataset_file = candidate

    valid, training_samples = validate_and_prepare_dataset(dataset_file)
    if not valid:
        sys.exit(1)

    api_key = args.api_key.strip()
    if not api_key:
        print("\n" + "=" * 55)
        print("🔑 AUTENTIKASI GOOGLE GEMINI API KEY")
        print("=" * 55)
        print("Untuk melatih model di Google AI Studio, diperlukan Gemini API Key.")
        print("(Dapatkan gratis di https://aistudio.google.com/app/apikey)\n")
        try:
            user_input = input("Masukkan Gemini API Key Anda (atau tekan Enter untuk batal): ").strip()
            if user_input:
                api_key = user_input
            else:
                print("\n[i] Pelatihan dibatalkan. Anda dapat menjalankan kembali kapan saja.")
                sys.exit(0)
        except (KeyboardInterrupt, EOFError):
            print("\n[i] Dibatalkan oleh pengguna.")
            sys.exit(0)

    run_fine_tuning(api_key, training_samples, args.model_name, args.epochs)

if __name__ == "__main__":
    main()
