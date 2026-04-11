# Valora 💎
### The Executive Portfolio for serious Game Collectors.

**Valora** is more than just a library tracker—it is a high-fidelity financial dashboard for your gaming assets. Built with **Flutter** and powered by **Supabase WASM**, Valora transforms your game shelves (physical or digital) into a managed investment portfolio with real-time market valuations.

---

## 🎯 The Vision: Why Valora?
For many collectors, a game collection is a significant financial asset. **Valora tries to bridge the gap** between a simple "checklist" and a professional portfolio manager. 
*   **What it trys to do**: Automate the tedious process of price-tracking while providing deep insights into asset growth, rarity, and platform diversification.
*   **Our Goal**: To be the fastest, most secure way to visualize the "net worth" of your gaming history.

## 🚀 Core Capabilities
*   **Real-Time Appraisals**: Connects to global market APIs via optimized Edge Functions to provide up-to-the-minute values for over 100k+ titles.
*   **Digital & Physical Sync**: Import thousands of games from **Steam** in one tap, or scan physical titles using the high-speed **UPC Barcode Scanner**.
*   **Financial Insights**: Visualize your collection's growth over time with interactive charts and "Crown Jewel" highlights.
*   **Social Snapshots**: Capture premium, shareable valuation summaries to showcase your collection milestones.

## 🛠️ How it Works (Under the Hood)
Valora is engineered for speed and stability:
1.  **WASM-GC Core**: On the web, Valora compiles to WebAssembly, delivering near-native performance that makes scrolling through thousands of games butter-smooth.
2.  **Edge Compute**: Valuation logic is offloaded to **Supabase Edge Functions** (TypeScript), ensuring that your local device doesn't waste battery processing price data.
3.  **Intelli-Cache**: Custom image caching layers ensure that high-quality game cover art is sub-sampled for your specific screen, keeping RAM usage low and UI responsiveness high.

## 🔒 Safety, Privacy & Security
We believe your collection data is private. **Valora is designed to be trustless and secure:**
*   **Row-Level Security (RLS)**: Every single row in the database is locked behind strict Supabase RLS policies. It is technically impossible for one user to see another's collection data.
*   **Secure Auth**: We use industry-standard **ID Token verification** for Google Sign-In, ensuring your password never touches our servers.
*   **No Data Resale**: Valora does not sell your collection data to third-party advertisers. Your library stays between you and your account.
*   **Production Hardening**: All API communication is encrypted via TLS, and production secrets are injected at build-time, never stored in the source code.

---

## 📦 Technical Installation

1. **Clone & Install**:
   ```bash
   git clone https://github.com/Hikki-dev/valora.git
   cd valora
   flutter pub get
   ```

2. **Configure Environment**:
   Ensure you have a `.env` file in the root with your Supabase credentials:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```

3. **Production Build (Web/WASM)**:
   ```bash
   ./scripts/build.sh --wasm
   ```

## 📜 License
Distributed under the MIT License. See `LICENSE` for more information.

---
*Created with ❤️ for collectors, by collectors.*
