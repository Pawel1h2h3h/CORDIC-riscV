# SinCos RISC-V Visualization

Projekt umożliwia obliczanie wartości funkcji trygonometrycznych `sin(x)` i `cos(x)` w asemblerze RISC-V z wykorzystaniem emulatora **RARS**, a następnie generowanie wykresów w Pythonie.

## 📁 Zawartość

- `sincos.asm` – program w asemblerze RISC-V, obliczający i wypisujący wartości `sin(x)` i `cos(x)` na podstawie wejściowego kąta.
- `generate_data.py` – skrypt w Pythonie, który automatycznie uruchamia `sincos.asm` w pętli, podaje kąty od -360° do +360° i zapisuje wyniki do pliku CSV.
- `plots.py` – skrypt do wczytania danych z CSV i narysowania wykresów `sin(x)` i `cos(x)` w określonym zakresie kątów.

---

## ⚙️ Wymagania

- Python 3.x
- Java (zainstalowana i dostępna w terminalu)
- RARS (np. `rars1_6.jar` w katalogu projektu)
- Biblioteki Pythona:
  ```bash
  pip install matplotlib
