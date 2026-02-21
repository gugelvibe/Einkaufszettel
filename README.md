# Einkaufszettel

Eine einfache Einkaufslisten-App, entwickelt mit Flutter.

## Repository-Struktur

Dieses Repository ist auf die reine Programmlogik beschränkt. Plattformspezifische Ordner (`android`, `ios`, etc.) sind nicht versioniert.

## Installation & Ausführung

1.  **Repository klonen**
2.  **Abhängigkeiten laden**:
    ```bash
    flutter pub get
    ```
3.  **Plattform-spezifischen Code generieren**:
    Aufgrund der restriktiven Versionsverwaltung müssen die Plattform-Ordner lokal neu generiert werden:
    ```bash
    flutter create .
    ```
4.  **App starten**:
    ```bash
    flutter run
    ```

## Features
- Lokale Speicherung der Einkaufslisten
- Artikel-Vorschläge beim Tippen
- Drag & Drop Reordering
- iOS-inspiriertes Design
