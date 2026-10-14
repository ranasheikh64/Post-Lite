# Jronix Post - Landing Page

A modern, responsive, high-converting landing page for **Jronix Post** (Lightning-Fast REST, Socket.IO & WebSocket Client).

---

## 🚀 How to Deploy to GitHub Pages

You can deploy this landing page to GitHub Pages in two simple ways:

### Option 1: Deploy from a `gh-pages` Branch (Recommended)
1. In your terminal, run:
   ```bash
   git subtree push --prefix landing-page origin gh-pages
   ```
2. Go to your GitHub repository:
   - **Settings** → **Pages**
   - Source: **Deploy from a branch**
   - Branch: `gh-pages` / `/ (root)`
   - Click **Save**.

---

### Option 2: Copy to `/docs` for GitHub Pages Root
GitHub Pages can automatically serve from a `/docs` folder on your `main` branch:
```bash
cp -r landing-page docs
git add docs
git commit -m "docs: add GitHub Pages site"
git push origin main
```
Then under **Settings → Pages**, select `main` branch and `/docs` folder.

---

## 🛠 Local Preview
To preview locally, open `index.html` in any browser or run:
```bash
npx serve landing-page
# or
python3 -m http.server 8000 --directory landing-page
```
Then open `http://localhost:8000`.
