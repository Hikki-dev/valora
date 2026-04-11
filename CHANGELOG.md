# Changelog

All notable changes to **Valora** will be documented in this file.

## [1.1.0+2] - 2026-04-11
### 💨 Performance & Web Optimization
- **WASM Acceleration**: Enabled and optimized the build pipeline for WebAssembly (WASM-GC), delivering superior web execution speed.
- **Intelligent Image Caching**: Added `memCacheWidth/Height` constraints to all core views (Library, Details, Insights, Wishlist) to prevent memory OOM crashes on high-DPI and web platforms.
- **Optimized Grid**: Refined the collection grid with RepaintBoundaries and smooth entry animations.

### 📐 Responsive Design Architecture
- **Three-Tier Navigation**: Implemented a fully adaptive structural engine:
  - **Mobile**: Ergonomic bottom navigation.
  - **Tablet**: Space-efficient Navigation Rail.
  - **Desktop**: High-fidelity full sidebar with branding.
- **Adaptive Layouts**: Viewports now dynamically scale grid columns and padding based on screen real estate (Mobile: 2, Tablet: 3, Desktop: 5 columns).

### 🔒 Security & Data Hardening
- **Supabase RLS**: Applied core Row Level Security (RLS) policies to isolate `games`, `profiles`, and `value_snapshots` by `auth.uid()`.
- **Secret Injection**: Hardened the production build process by moving all sensitive keys to `dart-define` injection.

### 📸 Core Feature Upgrades
- **Social Sharing**: New "Snapshot" system to capture and share a premium high-contrast summary of the top 10 most valuable collection assets.
- **Barcode & Sync**: Finalized the wiring for the UPC scanner and Steam Library Sync engine, including fallback platform detection logic.

### 🛠️ DX & CI/CD
- **Automated Pipeline**: Fixed formatting and linting workflows to ensure 100% analysis pass on every pull request.
- **Build Scripts**: Updated `scripts/build.sh` with WASM and environment-aware build flags.
