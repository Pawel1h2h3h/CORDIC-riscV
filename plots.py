import subprocess, re
import csv
import matplotlib.pyplot as plt


def run_rars(angle):
    # Uruchamiamy RARS i przekazujemy stdin + odczyt stdout
    proc = subprocess.Popen(
        ["java", "-jar", "rars1_6.jar", "sincos.asm"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True  # ważne, by obsługiwać dane jako tekst, a nie bajty
    )

    # Wpisujemy np. 30 jako kąt + enter
    stdout, stderr = proc.communicate(input=f"{angle}\n")
    return stdout


def write_to_file(filename, data):
    with open(filename, 'w') as file:
        file.write(data)



def main():
    """Odczytuje dane z RARS-a i zapisuje do pliku CSV."""
    value_list = []

    for i in range(-360,360):
        string_to_do = run_rars(i)  # zakładamy, że ta funkcja zwraca np. wynik z RARS-a
        match = re.search(r"cos\(x\) = (-?[\d.]+)\s*\|\s*sin\(x\) = (-?[\d.]+)", string_to_do)


        if match:
            cos_val = float(match.group(1))
            sin_val = float(match.group(2))
            print(cos_val, sin_val)
            value_list.append((cos_val, sin_val))
        else:
            print("Nie udało się znaleźć wartości.")

    # Zapisujemy do pliku CSV
    with open('wyniki.csv', 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(['cos', 'sin'])  # nagłówki
        writer.writerows(value_list)

    print("Zapisano do pliku wyniki.csv")
    return value_list


def rysuj_wykres_sin_cos(csv_path='wyniki.csv', start_angle=-360, end_angle=360):
    """Rysuje wykres funkcji sin i cos na podstawie danych z pliku CSV."""
    kąty = []
    sin_vals = []
    cos_vals = []

    with open(csv_path, 'r') as csvfile:
        reader = csv.DictReader(csvfile)
        for i, row in enumerate(reader):
            kąt = -360 + i  # Zakładamy, że dane zaczynają się od -360 stopni

            if start_angle <= kąt <= end_angle:
                try:
                    cos_val = float(row['cos'])
                    sin_val = float(row['sin'])
                    kąty.append(kąt)
                    cos_vals.append(cos_val)
                    sin_vals.append(sin_val)
                except (ValueError, KeyError):
                    print(f"Pominięto wiersz: {row}")

    # Rysowanie wykresu
    plt.figure(figsize=(10, 5))
    plt.plot(kąty, sin_vals, label='sin(x)')
    plt.plot(kąty, cos_vals, label='cos(x)')
    plt.xlabel('Kąt (°)')
    plt.ylabel('Wartość')
    plt.title(f'Wykres sin(x) i cos(x) dla kąta od {start_angle}° do {end_angle}°')
    plt.grid(True)
    plt.xticks(range(start_angle, end_angle + 1, 30))  # Podziałka co 90°
    plt.xlim(start_angle, end_angle)
    plt.legend()
    plt.tight_layout()
    plt.savefig('wykres_sin_cos.png')  # Zapisz wykres jako plik PNG
    plt.show()


# if __name__ == "__main__":
#     main()


rysuj_wykres_sin_cos(start_angle=-360, end_angle=360)